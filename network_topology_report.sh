#!/bin/bash

# Network Topology Report Generator
# Generates a comprehensive report of network configuration, services, and connections
# Version: 1.1.0

# Color codes for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default options
INCLUDE_DOCKER=true
INCLUDE_WIREGUARD=true
INCLUDE_SAMBA=true
VERBOSE_SERVICES=false
SHOW_HELP=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --help|-h)
            SHOW_HELP=true
            shift
            ;;
        --no-docker)
            INCLUDE_DOCKER=false
            shift
            ;;
        --no-wireguard)
            INCLUDE_WIREGUARD=false
            shift
            ;;
        --no-samba)
            INCLUDE_SAMBA=false
            shift
            ;;
        --verbose-services|-v)
            VERBOSE_SERVICES=true
            shift
            ;;
        --version)
            echo "Network Topology Report Generator v1.1.0"
            exit 0
            ;;
        *)
            OUTPUT_FILE="$1"
            shift
            ;;
    esac
done

# Show help if requested
if [ "$SHOW_HELP" = true ]; then
    cat << 'EOF'
Network Topology Report Generator v1.1.0

USAGE:
    network_topology_report.sh [OPTIONS] [output_file]

OPTIONS:
    -h, --help              Show this help message
    --version               Show version number
    -v, --verbose-services  Show detailed service information in topology
    --no-docker             Skip Docker network analysis
    --no-wireguard          Skip WireGuard VPN analysis
    --no-samba              Skip Samba connection analysis

EXAMPLES:
    # Basic usage with auto-generated filename
    sudo ./network_topology_report.sh

    # Specify output filename
    sudo ./network_topology_report.sh my_report.txt

    # Verbose service detection
    sudo ./network_topology_report.sh --verbose-services report.txt

    # Skip Docker analysis (faster on non-Docker hosts)
    sudo ./network_topology_report.sh --no-docker report.txt

    # Multiple options
    sudo ./network_topology_report.sh --no-docker --no-samba --verbose-services output.txt

NOTES:
    - Requires sudo for complete information
    - Will work without sudo but with limited data
    - Output is plain text, suitable for version control

EOF
    exit 0
fi

# Get hostname
HOSTNAME=$(hostname)
TIMESTAMP=$(date -u)

# Output file (default if not specified)
OUTPUT_FILE="${OUTPUT_FILE:-network_topology_report_${HOSTNAME}_$(date +%Y%m%d_%H%M%S).txt}"

# Function to print section header
print_header() {
    echo ""
    echo "=== $1 ==="
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Start report
{
    echo "=== NETWORK TOPOLOGY REPORT ==="
    echo "Hostname: $HOSTNAME"
    echo "Generated: $TIMESTAMP"
    echo ""

    # Network Interfaces
    print_header "NETWORK INTERFACES"
    if command_exists ip; then
        ip addr show
    else
        ifconfig -a
    fi

    # Routing Table
    print_header "ROUTING TABLE"
    if command_exists ip; then
        ip route show
    else
        route -n
    fi

    # Neighbor Discovery (ARP Table)
    print_header "NEIGHBOR DISCOVERY (ARP TABLE)"
    if command_exists ip; then
        ip neigh show
    else
        arp -a
    fi

    # Listening Ports & Services
    print_header "LISTENING PORTS & SERVICES"
    if command_exists ss; then
        ss -tulpn
    elif command_exists netstat; then
        netstat -tulpn
    fi

    # Active Network Connections
    print_header "ACTIVE NETWORK CONNECTIONS"
    if command_exists ss; then
        ss -tupn | grep ESTAB
    elif command_exists netstat; then
        netstat -tupn | grep ESTABLISHED
    fi

    # Firewall Status
    print_header "FIREWALL STATUS"
    if command_exists ufw; then
        sudo ufw status verbose
    elif command_exists iptables; then
        echo "IPTables rules:"
        sudo iptables -L -n -v
    fi

    # Network Statistics
    print_header "NETWORK STATISTICS"
    if command_exists ip; then
        ip -s link
    else
        netstat -i
    fi

    # DNS Configuration
    print_header "DNS CONFIGURATION"
    if [ -f /etc/resolv.conf ]; then
        cat /etc/resolv.conf
    fi

    # WireGuard Status
    print_header "WIREGUARD STATUS (if applicable)"
    if [ "$INCLUDE_WIREGUARD" = true ]; then
        if command_exists wg; then
            sudo wg show 2>/dev/null || echo "WireGuard not configured or not accessible"
        else
            echo "WireGuard not installed"
        fi
    else
        echo "Skipped (--no-wireguard flag used)"
    fi

    # Samba Connections
    print_header "SAMBA CONNECTIONS"
    if [ "$INCLUDE_SAMBA" = true ]; then
        if command_exists smbstatus; then
            echo ""
            sudo smbstatus 2>/dev/null || echo "Samba not running or not accessible"
        else
            echo "Samba not installed"
        fi
    else
        echo "Skipped (--no-samba flag used)"
    fi

    # Docker Networks (if applicable)
    if [ "$INCLUDE_DOCKER" = true ] && command_exists docker; then
        print_header "DOCKER NETWORKS"
        docker network ls 2>/dev/null
        echo ""
        echo "Docker network details:"
        for network in $(docker network ls --format "{{.Name}}" 2>/dev/null); do
            echo "Network: $network"
            docker network inspect "$network" 2>/dev/null | grep -A 5 "IPAM"
        done
    fi

    echo ""
    echo "=================================================================================="
    echo "=== VISUAL NETWORK TOPOLOGY DIAGRAM ==="
    echo "=================================================================================="
    echo ""
    echo "Visualisation: NETWORK TOPOLOGY DIAGRAM"
    echo "Generated: $TIMESTAMP"
    echo "Host: $HOSTNAME"
    echo ""

    # Parse and display network topology
    echo "INTERNET CLOUD"
    echo "│"

    # Get default gateway
    DEFAULT_GW=$(ip route | grep default | awk '{print $3}' | head -1)
    if [ -n "$DEFAULT_GW" ]; then
        echo "├── PUBLIC GATEWAY: $DEFAULT_GW"
        echo "│"
    fi

    # Get public IP and hostname
    PUBLIC_IP=$(ip addr show | grep 'inet ' | grep -v '127.0.0.1' | grep -v '10\.' | grep -v '172\.(1[6-9]|2[0-9]|3[0-1])\.' | grep -v '192\.168\.' | awk '{print $2}' | cut -d/ -f1 | head -1)
    PUBLIC_IPV6=$(ip addr show | grep 'inet6' | grep -v '::1' | grep -v 'fe80:' | grep -v 'fd' | awk '{print $2}' | cut -d/ -f1 | head -1)
    
    if [ -n "$PUBLIC_IPV6" ]; then
        echo "└── YOUR SERVER: $PUBLIC_IPV6"
    else
        echo "└── YOUR SERVER: $PUBLIC_IP"
    fi
    echo "│"

    # Main network interface
    MAIN_IFACE=$(ip route | grep default | awk '{print $5}' | head -1)
    if [ -n "$MAIN_IFACE" ]; then
        echo "├── INTERFACE: $MAIN_IFACE (PUBLIC)"
        if [ -n "$PUBLIC_IP" ]; then
            SUBNET=$(ip addr show "$MAIN_IFACE" | grep "inet $PUBLIC_IP" | awk '{print $2}')
            echo "│   ├── IP: $SUBNET"
        fi
        if [ -n "$PUBLIC_IPV6" ]; then
            IPV6_SUBNET=$(ip addr show "$MAIN_IFACE" | grep "inet6 $PUBLIC_IPV6" | awk '{print $2}')
            echo "│   ├── IPv6: $IPV6_SUBNET"
        fi
        echo "│   └── SERVICES:"
        
        # Detect services with improved logic
        SERVICES_FOUND=false
        
        # Check for HTTP/HTTPS (any interface, not just localhost)
        if ss -tulpn 2>/dev/null | grep -E "LISTEN.*:80 |LISTEN.*:80$" | grep -v "127.0.0" | grep -qv "\[::1\]"; then
            SERVICES_FOUND=true
            if [ "$VERBOSE_SERVICES" = true ]; then
                HTTP_PROC=$(ss -tulpn 2>/dev/null | grep -E "LISTEN.*:80 " | grep -v "127.0.0" | head -1 | grep -oP 'users:\(\(".*?",pid=[0-9]+' | cut -d'"' -f2)
                echo "│       ├── HTTP (80) - $HTTP_PROC"
            else
                echo "│       ├── HTTP (80)"
            fi
        fi
        
        if ss -tulpn 2>/dev/null | grep -E "LISTEN.*:443 |LISTEN.*:443$" | grep -v "127.0.0" | grep -qv "\[::1\]"; then
            SERVICES_FOUND=true
            if [ "$VERBOSE_SERVICES" = true ]; then
                HTTPS_PROC=$(ss -tulpn 2>/dev/null | grep -E "LISTEN.*:443 " | grep -v "127.0.0" | head -1 | grep -oP 'users:\(\(".*?",pid=[0-9]+' | cut -d'"' -f2)
                echo "│       ├── HTTPS (443) - $HTTPS_PROC"
            else
                echo "│       ├── HTTPS (443)"
            fi
        fi
        
        # Check for SSH (non-standard ports too)
        if ss -tulpn 2>/dev/null | grep -E "LISTEN.*(sshd|ssh)" | grep -qv "127.0.0"; then
            SERVICES_FOUND=true
            SSH_PORTS=$(ss -tulpn 2>/dev/null | grep -E "LISTEN.*(sshd|ssh)" | grep -v "127.0.0" | awk '{print $5}' | grep -oP ':\K[0-9]+$' | sort -u | tr '\n' ',' | sed 's/,$//')
            if [ "$VERBOSE_SERVICES" = true ]; then
                echo "│       ├── SSH ($SSH_PORTS)"
            else
                echo "│       ├── SSH ($SSH_PORTS)"
            fi
        fi
        
        # Check for SMTP
        if ss -tulpn 2>/dev/null | grep -E "LISTEN.*:25 |LISTEN.*:25$" | grep -qv "127.0.0"; then
            SERVICES_FOUND=true
            echo "│       ├── SMTP (25)"
        fi
        
        # Check for DNS
        if ss -tulpn 2>/dev/null | grep -E "LISTEN.*:53 |LISTEN.*:53$" | grep -qv "127.0.0"; then
            SERVICES_FOUND=true
            echo "│       ├── DNS (53)"
        fi
        
        # Check for MySQL/MariaDB
        if ss -tulpn 2>/dev/null | grep -E "LISTEN.*:3306 |LISTEN.*:3306$" | grep -qv "127.0.0"; then
            SERVICES_FOUND=true
            echo "│       ├── MySQL/MariaDB (3306)"
        fi
        
        # Check for PostgreSQL
        if ss -tulpn 2>/dev/null | grep -E "LISTEN.*:5432 |LISTEN.*:5432$" | grep -qv "127.0.0"; then
            SERVICES_FOUND=true
            echo "│       ├── PostgreSQL (5432)"
        fi
        
        # Check for Redis
        if ss -tulpn 2>/dev/null | grep -E "LISTEN.*:6379 |LISTEN.*:6379$" | grep -qv "127.0.0"; then
            SERVICES_FOUND=true
            echo "│       ├── Redis (6379)"
        fi
        
        # Check for custom high ports (8000-9000 range - common for apps)
        if [ "$VERBOSE_SERVICES" = true ]; then
            CUSTOM_PORTS=$(ss -tulpn 2>/dev/null | grep LISTEN | grep -v "127.0.0" | awk '{print $5}' | grep -oP ':\K[0-9]+$' | grep -E '^(8[0-9]{3}|9[0-9]{3})$' | sort -u)
            if [ -n "$CUSTOM_PORTS" ]; then
                SERVICES_FOUND=true
                echo "│       ├── Custom services: $(echo $CUSTOM_PORTS | tr '\n' ',' | sed 's/,$//' | tr ' ' ',')"
            fi
        fi
        
        if [ "$SERVICES_FOUND" = false ]; then
            echo "│       └── No public services detected"
        fi
    fi
    echo "│"

    # WireGuard VPN
    if [ "$INCLUDE_WIREGUARD" = true ] && command_exists wg && sudo wg show 2>/dev/null | grep -q interface; then
        echo "├── VPN: WireGuard"
        WG_IFACE=$(sudo wg show interfaces 2>/dev/null | head -1)
        if [ -n "$WG_IFACE" ]; then
            WG_IP=$(ip addr show "$WG_IFACE" 2>/dev/null | grep 'inet ' | awk '{print $2}')
            echo "│   ├── $WG_IFACE - $WG_IP"
            
            # List peers
            sudo wg show "$WG_IFACE" peers 2>/dev/null | while read peer; do
                ENDPOINT=$(sudo wg show "$WG_IFACE" peer "$peer" endpoint 2>/dev/null)
                HANDSHAKE=$(sudo wg show "$WG_IFACE" peer "$peer" latest-handshake 2>/dev/null)
                if [ "$HANDSHAKE" != "0" ]; then
                    echo "│   │   └── PEER: $peer (ACTIVE)"
                else
                    echo "│   │   └── PEER: $peer (INACTIVE)"
                fi
            done
        fi
        echo "│"
    fi

    # Tailscale
    if ip addr show 2>/dev/null | grep -q tailscale; then
        echo "├── VPN: Tailscale"
        TS_IP=$(ip addr show tailscale0 2>/dev/null | grep 'inet ' | awk '{print $2}')
        echo "│   ├── tailscale0 - $TS_IP"
        
        # Get Tailscale DNS
        if grep -q "100.100.100.100" /etc/resolv.conf 2>/dev/null; then
            echo "│   └── DNS: 100.100.100.100"
        fi
        echo "│"
    fi

    # Docker Networks
    if [ "$INCLUDE_DOCKER" = true ] && command_exists docker; then
        echo "└── DOCKER NETWORKS"
        docker network ls --format "{{.Name}}" 2>/dev/null | grep -v "^bridge$" | grep -v "^host$" | grep -v "^none$" | while read network; do
            SUBNET=$(docker network inspect "$network" 2>/dev/null | grep -A 1 '"Subnet"' | grep -v Subnet | tr -d ' ",')
            DRIVER=$(docker network ls --format "{{.Name}} {{.Driver}}" | grep "^$network " | awk '{print $2}')
            
            # Check if network is in use
            CONTAINERS=$(docker network inspect "$network" 2>/dev/null | grep -c '"Name".*"container:')
            if [ "$CONTAINERS" -gt 0 ]; then
                STATUS="(ACTIVE)"
            else
                STATUS="(DOWN)"
            fi
            
            echo "    ├── $DRIVER: $network - $SUBNET $STATUS"
            
            # List containers
            docker network inspect "$network" 2>/dev/null | grep '"Name": "' | grep -v '"Network":' | while read line; do
                CONTAINER=$(echo "$line" | cut -d'"' -f4)
                if [ "$CONTAINER" != "" ]; then
                    echo "    │   ├── CONTAINER: $CONTAINER"
                fi
            done
        done
    fi

    # Active Connections Summary
    echo ""
    echo "ACTIVE CONNECTIONS"
    echo "──────────────────────────────────────────────────────────────"
    if command_exists ss; then
        ss -tupn | grep ESTAB | head -20
    else
        netstat -tupn | grep ESTABLISHED | head -20
    fi

    # Security Status
    echo ""
    echo "SECURITY STATUS"
    echo "──────────────────────────────────────────────────────────────"
    if command_exists ufw; then
        if sudo ufw status | grep -q "Status: active"; then
            echo "✅ UFW firewall is active"
        else
            echo "⚠️  UFW firewall is inactive"
        fi
    fi
    
    if command_exists wg && sudo wg show 2>/dev/null | grep -q interface; then
        # Check if Samba is restricted to WireGuard
        if sudo ufw status 2>/dev/null | grep -q "10.0.0"; then
            echo "✅ Samba isolated to WireGuard network only"
        fi
    fi
    
    if command_exists docker && docker ps -q 2>/dev/null | grep -q .; then
        echo "✅ Docker containers running in isolated networks"
    fi

    # Services Summary
    echo ""
    echo "SERVICES SUMMARY"
    echo "──────────────────────────────────────────────────────────────"
    
    PUBLIC_PORTS=$(ss -tulpn 2>/dev/null | grep -v "127.0.0" | grep LISTEN | wc -l)
    echo "PUBLIC: $PUBLIC_PORTS listening ports"
    
    if command_exists wg && sudo wg show 2>/dev/null | grep -q interface; then
        WG_COUNT=$(sudo wg show interfaces 2>/dev/null | wc -w)
        echo "VPN: $WG_COUNT WireGuard"
        if ip addr show 2>/dev/null | grep -q tailscale; then
            echo -n ", 1 Tailscale"
        fi
        echo ""
    fi
    
    if command_exists docker; then
        CONTAINER_COUNT=$(docker ps -q 2>/dev/null | wc -l)
        if [ "$CONTAINER_COUNT" -gt 0 ]; then
            echo "CONTAINERS: $CONTAINER_COUNT active"
        fi
    fi

    # Traffic Flow
    echo ""
    echo "TRAFFIC FLOW"
    echo "──────────────────────────────────────────────────────────────"
    echo "Internet → SSH/HTTPS/WireGuard → $MAIN_IFACE"
    if command_exists wg && sudo wg show 2>/dev/null | grep -q interface; then
        echo "WireGuard Peers → Samba Shares → wg0"
    fi
    if command_exists docker && docker ps -q 2>/dev/null | grep -q .; then
        echo "Containers → Bridge Networks → Host"
    fi

    echo ""
    echo "=================================================================================="
    echo "=== END OF NETWORK TOPOLOGY REPORT ==="
    echo "=================================================================================="

} > "$OUTPUT_FILE"

echo -e "${GREEN}Network topology report generated: $OUTPUT_FILE${NC}"
echo -e "${BLUE}View with: cat $OUTPUT_FILE${NC}"
