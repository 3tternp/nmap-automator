#!/bin/sh

# =======================================
#  Interactive Nmap Automator 🚀
# =======================================
# Features: Auto-installs missing tools, dynamic menu, and beautiful UI

# Default output directory
OUTPUT_DIR="./nmap_results"
mkdir -p "$OUTPUT_DIR"

# Colors for better visibility
RED='\033[1;31m'
YELLOW='\033[1;33m'

# Function: Display ASCII Banner
show_banner() {
    clear
    echo "${CYAN}"
    echo "========================================"
    echo "  🚀 Interactive Nmap Automator 🚀"
    echo "  Author:3tternp"
    echo "========================================"
    echo "${RESET}"
}

# Function: Check and Install Required Tools
check_tools() {
    for tool in nmap ffuf; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            echo "${YELLOW}[*] Installing missing tool: $tool...${RESET}"
            if command -v apt >/dev/null 2>&1; then
                sudo apt update && sudo apt install -y "$tool"
            elif command -v yum >/dev/null 2>&1; then
                sudo yum install -y "$tool"
            elif command -v brew >/dev/null 2>&1; then
                brew install "$tool"
            else
                echo "${RED}[-] Package manager not detected. Please install $tool manually.${RESET}"
                exit 1
            fi
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

# Function: User selects target
get_target() {
    echo "${CYAN}Enter target IP or domain:${RESET}"
    read -r TARGET
    [ -z "$TARGET" ] && { echo "${RED}No target provided. Exiting.${RESET}"; exit 1; }
}

# Function: User selects scans
choose_scans() {
    echo "${CYAN}Choose scan types (separate multiple choices with spaces):${RESET}"
    echo "1) Full Scan"
    echo "2) Port Scan"
    echo "3) UDP Scan"
    echo "4) Recon Scan"
    echo "5) HTTP Fuzzing"
    echo "6) Network Discovery"
    echo "7) Exit"

    read -r SCAN_SELECTION
}

# Function: Execute selected scans
execute_scans() {
    for scan in $SCAN_SELECTION; do
        case $scan in
            1) run_scan "Full" "nmap -p- -A $TARGET" ;;
            2) run_scan "Port" "nmap -p- $TARGET" ;;
            3) run_scan "UDP" "nmap -sU $TARGET" ;;
            4) run_scan "Recon" "nmap -A $TARGET" ;;
            5) run_scan "HTTP Fuzzing" "ffuf -w /usr/share/wordlists/dirb/common.txt -u \"http://$TARGET/FUZZ\"" ;;
            6) run_scan "Network Discovery" "nmap -sn $TARGET" ;;
            7) echo "${YELLOW}Exiting.${RESET}"; exit 0 ;;
            *) echo "${RED}Invalid selection: $scan${RESET}" ;;
        esac
    done
}

# Main function
main() {
    show_banner
    check_tools
    get_target
    choose_scans
    execute_scans
    echo "${CYAN}[+] Scans Completed! Results saved in $OUTPUT_DIR.${RESET}"
}

main

