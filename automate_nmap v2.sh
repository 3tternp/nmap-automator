#!/bin/sh

# =======================================
#  Nmap Automator - Ultimate Version 🚀
# =======================================
# Author: 3tternp
# Features: Multiple scan types, beautiful UI, logging, remote execution, and POSIX compliance

# Default output directory
OUTPUT_DIR="./nmap_results"
mkdir -p "$OUTPUT_DIR"

# Colors for better visibility
GREEN='\033[1;32m'
RED='\033[1;31m'
YELLOW='\033[1;33m'

# Function: Display usage
show_help() {
    echo "${CYAN}Usage: $0 -t <targets> -s <scan_types> [-o <output_dir>] [-r] [-h]${RESET}"
    echo "  -t <targets>    : Target IP(s) or domain(s) (comma-separated)"
    echo "  -s <scan_types> : Scan types (comma-separated: full, port, udp, recon, fuzz, network)"
    echo "  -o <output_dir> : Output directory (default: ./nmap_results)"
    echo "  -r              : Enable Remote Mode"
    echo "  -h              : Show this help message"
    exit 1
}

# Function: Check if required tools are installed
check_tools() {
    for tool in nmap ffuf; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            echo "${RED}[-] Missing tool: $tool${RESET}"
            echo "[-] Install missing tools before running the script."
            exit 1
        fi
    done
}

# Function: Display a progress bar
progress_bar() {
    local duration=$1
    local bar_length=30
    local increment=$((duration / bar_length))

    printf "${YELLOW}["
    for _ in $(seq 1 "$bar_length"); do
        printf "#"
        sleep "$increment"
    done
    printf "] Done!${RESET}\n"
}

# Function: Save scan output with timestamps
save_output() {
    local filename="$OUTPUT_DIR/$1-$(date +"%Y%m%d_%H%M%S").txt"
    echo "[+] Saving output to $filename"
    echo "$2" > "$filename"
}

# Function: Run a scan and log output
run_scan() {
    local scan_name="$1"
    local scan_command="$2"
    
    echo "${GREEN}[+] Running $scan_name Scan...${RESET}"
    progress_bar 5
    
    results=$(eval "$scan_command")
    save_output "$scan_name" "$results"
}

# Function: Network Discovery Scan
network_scan() {
    run_scan "Network Discovery" "nmap -sn $TARGETS"
}

# Function: Full Scan
full_scan() {
    run_scan "Full" "nmap -p- -A $TARGETS"
}

# Function: Port Scan
port_scan() {
    run_scan "Port" "nmap -p- $TARGETS"
}

# Function: UDP Scan
udp_scan() {
    run_scan "UDP" "nmap -sU $TARGETS"
}

# Function: Recon Scan
recon_scan() {
    run_scan "Recon" "nmap -A $TARGETS"
}

# Function: HTTP Fuzzing
http_fuzzing() {
    run_scan "HTTP Fuzzing" "ffuf -w /usr/share/wordlists/dirb/common.txt -u \"http://$TARGETS/FUZZ\""
}

# Function: Run Remote Mode
remote_mode() {
    echo "${GREEN}[+] Running in Remote Mode...${RESET}"
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
[ -z "$TARGETS" ] || [ -z "$SCAN_TYPES" ] && show_help

# Check for required tools
check_tools

# Run scans based on user selection
for scan in $(echo "$SCAN_TYPES" | tr ',' ' '); do
    case $scan in
        full) full_scan ;;
        port) port_scan ;;
        udp) udp_scan ;;
        recon) recon_scan ;;
        fuzz) http_fuzzing ;;
        network) network_scan ;;
        *) echo "${RED}[-] Unknown scan type: $scan${RESET}" ;;
    esac
done

# Run remote mode if enabled
[ "$REMOTE_MODE" = true ] && remote_mode

echo "${CYAN}[+] Scans Completed! Results saved in $OUTPUT_DIR.${RESET}"
