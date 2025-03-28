#!/bin/sh
# =======================================
#  🚀 ASTRA Nmap Automator 🚀
# =======================================
# Features: Auto-installs missing tools, animated progress bar, and improved UI

# Default output directory
OUTPUT_DIR="./nmap_results"
mkdir -p "$OUTPUT_DIR"

# Colors for better visibility
RED='\033[1;31m'

# Function: Display ASCII Banner
show_banner() {
    clear
    echo "========================================"
    echo "       ✨ ASTRA Nmap Automator ✨       "
    echo "========================================"
    echo "        .        .        .            "
    echo "     .      *         *      .         "
    echo "  *      *     🌟     *      *        "
    echo "     *       *       *     *           "
    echo "  ------------------------------------  "
    echo "     Secure the Stars with Nmap        "
    echo "========================================"
}

# Function: Check and Install Required Tools
check_tools() {
    for tool in nmap ffuf dirb; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            echo "${YELLOW}[*] Installing missing tool: $tool..."
            if command -v apt >/dev/null 2>&1; then
                sudo apt update && sudo apt install -y "$tool"
            elif command -v yum >/dev/null 2>&1; then
                sudo yum install -y "$tool"
            elif command -v brew >/dev/null 2>&1; then
                brew install "$tool"
            else
                echo "${RED}[-] Package manager not detected. Please install $tool manually."
                exit 1
            fi
        fi
    done

    # Ensure wordlist for ffuf exists
    if [ ! -f /usr/share/wordlists/dirb/common.txt ]; then
        echo "${YELLOW}[*] Downloading common.txt wordlist..."
        sudo mkdir -p /usr/share/wordlists/dirb/
        sudo wget -O /usr/share/wordlists/dirb/common.txt https://raw.githubusercontent.com/v0re/dirb/master/wordlists/common.txt
    fi
}

# Function: Animated Progress Bar
progress_bar() {
    local duration=$1
    local bar_length=30
    local completed=0

    echo -ne "${YELLOW}["
    while [ "$completed" -lt "$bar_length" ]; do
        printf "#"
        sleep 0.1  
        completed=$((completed + 1))
    done
    echo -e "] 100%\n"
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
    
    echo "[+] Running $scan_name Scan..."
    progress_bar 5
    
    results=$(eval "$scan_command")
    save_output "$scan_name" "$results"
}

# Function: User selects target
get_target() {
    echo "Enter target IP or domain:"
    read -r TARGET
    [ -z "$TARGET" ] && { echo "${RED}No target provided. Exiting."; exit 1; }
}

# Function: User selects scans
choose_scans() {
   echo "Choose scan types (separate multiple choices with spaces):"
    echo "1) Full Scan"
    echo "2) Full Scan from Input list"
    echo "3) Port Scan"
    echo "4) UDP Scan"
    echo "5) Recon Scan"
    echo "6) HTTP Fuzzing"
    echo "7) Network Discovery"
    echo "8) Exit"

    read -r SCAN_SELECTION
}

# Function: Execute selected scans
execute_scans() {
    for scan in $SCAN_SELECTION; do
        case $scan in
             1) run_scan "Full" "nmap -p- -A $TARGET" ;;
            2) run_scan "List_Input" "nmap -p- -iL input_list.txt" ;;
            3) run_scan "Port" "nmap -p- $TARGET" ;;
            4) run_scan "UDP" "nmap -sU $TARGET" ;;
            5) run_scan "Recon" "nmap -A $TARGET" ;;
            6) run_scan "HTTP Fuzzing" "ffuf -w /usr/share/wordlists/dirb/common.txt -u \"http://$TARGET/FUZZ\"" ;;
            7) run_scan "Network Discovery" "nmap -sn $TARGET" ;;
            8) echo "${YELLOW}Exiting."; exit 0 ;;
            *) echo "${RED}Invalid selection: $scan" ;;
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
    echo "[+] Scans Completed! Results saved in $OUTPUT_DIR."
}

main

