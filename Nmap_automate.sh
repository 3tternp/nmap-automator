#!/bin/sh

# Nmap Automator - Advanced Nmap Scanning Script
# POSIX compliant & optimized for performance

# Default output directory
OUTPUT_DIR="./nmap_results"

# Ensure output directory exists
mkdir -p "$OUTPUT_DIR"

# Function to display usage
show_help() {
    echo "Usage: $0 -t <targets> -s <scan_types> [-o <output_dir>] [-r] [-h]"
    echo "  -t <targets>      : Target IP(s) or domain(s) (comma-separated)"
    echo "  -s <scan_types>   : Scan types (comma-separated: full, port, udp, recon, fuzz, network)"
    echo "  -o <output_dir>   : Output directory (default: ./nmap_results)"
    echo "  -r                : Enable Remote Mode"
    echo "  -h                : Show this help message"
    exit 1
}

# Function to check missing tools
check_tools() {
    missing_tools=""
    for tool in nmap ffuf; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            missing_tools="$missing_tools $tool"
        fi
    done

    if [ -n "$missing_tools" ]; then
        echo "[-] Missing required tools:$missing_tools"
        echo "[-] Please install the missing tools and rerun the script."
        exit 1
    fi
}

# Function to show progress bar
progress_bar() {
    total=$1
    count=0
    while [ "$count" -lt "$total" ]; do
        printf "#"
        count=$((count + 1))
        sleep 0.5
    done
    printf "\n"
}

# Function to perform network discovery scan
network_scan() {
    echo "[+] Running network scan to discover live hosts..."
    nmap -sn "$TARGETS" -oN "$OUTPUT_DIR/live_hosts.txt"
    echo "[+] Live hosts saved to $OUTPUT_DIR/live_hosts.txt"
}

# Function to perform full scan
full_scan() {
    echo "[+] Running full scan on $TARGETS..."
    progress_bar 10
    nmap -p- -A "$TARGETS" -oN "$OUTPUT_DIR/full_scan.txt"
    echo "[+] Full scan saved to $OUTPUT_DIR/full_scan.txt"
}

# Function to perform port scan
port_scan() {
    echo "[+] Running port scan on $TARGETS..."
    progress_bar 5
    nmap -p- "$TARGETS" -oN "$OUTPUT_DIR/port_scan.txt"
    echo "[+] Port scan saved to $OUTPUT_DIR/port_scan.txt"
}

# Function to perform UDP scan
udp_scan() {
    echo "[+] Running UDP scan on $TARGETS..."
    progress_bar 8
    nmap -sU "$TARGETS" -oN "$OUTPUT_DIR/udp_scan.txt"
    echo "[+] UDP scan saved to $OUTPUT_DIR/udp_scan.txt"
}

# Function to perform recon scan
recon_scan() {
    echo "[+] Running reconnaissance scan on $TARGETS..."
    progress_bar 7
    nmap -A "$TARGETS" -oN "$OUTPUT_DIR/recon_scan.txt"
    echo "[+] Recon scan saved to $OUTPUT_DIR/recon_scan.txt"
}

# Function to perform HTTP fuzzing
http_fuzzing() {
    echo "[+] Running HTTP fuzzing on $TARGETS..."
    progress_bar 6
    ffuf -w /usr/share/wordlists/dirb/common.txt -u "http://$TARGETS/FUZZ" -o "$OUTPUT_DIR/http_fuzz.txt"
    echo "[+] HTTP fuzzing results saved to $OUTPUT_DIR/http_fuzz.txt"
}

# Function to run remote mode
remote_mode() {
    echo "[+] Running scans in remote mode..."
    ssh user@remote_host "bash -s" < "$0" -t "$TARGETS" -s "$SCAN_TYPES" -o "$OUTPUT_DIR"
}

# Parse user inputs
while getopts "t:s:o:rh" opt; do
    case $opt in
        t) TARGETS="$OPTARG" ;;
        s) SCAN_TYPES="$OPTARG" ;;
        o) OUTPUT_DIR="$OPTARG" ;;
        r) REMOTE_MODE=true ;;
        h) show_help ;;
        *) show_help ;;
    esac
done

# Validate input
if [ -z "$TARGETS" ] || [ -z "$SCAN_TYPES" ]; then
    show_help
fi

# Check required tools
check_tools

# Run scans
for scan in $(echo "$SCAN_TYPES" | tr ',' ' '); do
    case $scan in
        full) full_scan ;;
        port) port_scan ;;
        udp) udp_scan ;;
        recon) recon_scan ;;
        fuzz) http_fuzzing ;;
        network) network_scan ;;
        *) echo "[-] Unknown scan type: $scan" ;;
    esac
done

# Run remote mode if enabled
if [ "$REMOTE_MODE" = true ]; then
    remote_mode
fi

echo "[+] Scans completed. Results saved in $OUTPUT_DIR."
