# routechecker

This Bash script collects IPv4 route objects from Internet Routing Registry (IRR) databases for a list of Autonomous System Numbers (ASNs). It filters out private, loopback, default, and NAT ranges, stores the results with version control, and logs changes. Only the latest two versions of each output file are retained.

🔧 Usage

1. Create a file named AS.txt with the ASNs you want to query (comma-separated):

AS14593, AS36492

2. Run the script:

chmod +x routequery.sh
./routequery.sh

📦 Outputs

For each ASN:

- **ipv4_routes_<ASN>_<timestamp>.txt**: Current prefix list
- **<ASN>_latest.txt**: Copy of the current list
- **diff_<ASN>_<timestamp>.txt**: Differences against previous version (if available)
- **log_<ASN>.txt**: Changelog with prefix count on first run

🧹 Retention Policy

Only the two most recent result files are kept (current and previous)

The following IP ranges are automatically excluded:

0.0.0.0/0 (default route)

10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16 (RFC1918 private IPs)

127.0.0.0/8 (loopback)

169.254.0.0/16 (link-local)

100.64.0.0/10 (CGNAT)

📘 Change Log

Each log_<ASN>.txt file contains entries for every run:

- **First run**: Logs total prefix count
- **Subsequent runs**: Logs number of changes (warns if more than 5)

📡 IRR Sources Queried

The script queries the following IRR databases:

- whois.radb.net
- whois.ripe.net
- whois.jp.apnic.net

🧪 Testing

To test the script:

1. Create an AS.txt file with real ASNs (e.g., Starlink: AS14593)
2. Run the script multiple times
3. Review the diff and log files to verify change tracking

Designed for advanced IRR monitoring, automation via cron, audit pipelines, and change tracking workflows.
