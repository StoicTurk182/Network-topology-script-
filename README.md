# Network Topology Report Generator

A comprehensive bash script that generates detailed network topology reports including interfaces, routing, services, VPN connections, Docker networks, and visual network diagrams.

## Features

- **Network Configuration**: Interfaces, routing tables, ARP cache, DNS settings
- **Service Detection**: Listening ports, active connections, public services
- **Security Status**: Firewall rules (UFW/iptables), network isolation checks
- **VPN Support**: WireGuard and Tailscale detection and peer information
- **Container Networks**: Docker network topology and container mappings
- **Visual Diagram**: ASCII art network topology visualization
- **Flexible Output**: Configurable options to skip specific components
- **Version Control Friendly**: Plain text output format

## Requirements

- Linux system (Ubuntu/Debian recommended)
- `sudo` access for complete information
- Optional: `docker`, `wg` (WireGuard), `samba` for full reporting

## Usage

### Basic Usage

```bash
# Generate report with auto-generated filename
sudo ./network_topology_report.sh

# Specify output filename
sudo ./network_topology_report.sh my_network_report.txt
```

### Options

```bash
-h, --help              Show help message
--version               Show version number
-v, --verbose-services  Show detailed service information
--no-docker             Skip Docker network analysis
--no-wireguard          Skip WireGuard VPN analysis
--no-samba              Skip Samba connection analysis
```

### Examples

```bash
# Verbose output with service details
sudo ./network_topology_report.sh --verbose-services report.txt

# Skip Docker (faster on non-Docker hosts)
sudo ./network_topology_report.sh --no-docker

# Multiple options
sudo ./network_topology_report.sh --no-docker --no-samba -v output.txt
```

## Output Includes

1. **System Information**: Hostname, timestamp
2. **Network Interfaces**: All network adapters and their configurations
3. **Routing Table**: Current routing rules
4. **ARP Table**: Known network neighbors
5. **Listening Services**: Ports and associated processes
6. **Active Connections**: Established network connections
7. **Firewall Status**: UFW or iptables rules
8. **Network Statistics**: Interface statistics
9. **DNS Configuration**: Resolver settings
10. **WireGuard Status**: VPN interfaces and peer connections
11. **Samba Connections**: Active file sharing sessions
12. **Docker Networks**: Container networking topology
13. **Visual Diagram**: ASCII network topology map
14. **Security Summary**: Firewall and isolation status
15. **Services Summary**: Count of public/VPN services

## Permissions

The script will work without sudo but with limited information. For complete data collection, run with sudo:

```bash
sudo ./network_topology_report.sh
```

## Output Format

Reports are saved as plain text files with timestamp, suitable for:
- Documentation
- Version control
- Diff comparisons
- Troubleshooting
- Security audits

Default filename format: `network_topology_report_<hostname>_<timestamp>.txt`

## Version

Current version: 1.1.0

## Notes

- Script is non-destructive and read-only
- Uses standard Linux networking tools (`ip`, `ss`, `netstat`)
- Gracefully handles missing tools or services
- Color-coded terminal output for readability
