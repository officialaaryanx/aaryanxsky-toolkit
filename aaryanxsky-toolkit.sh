#!/bin/bash
# ============================================================
#  AaryanXSky OSINT & Recon Toolkit
#  A menu-driven wrapper around native Kali Linux tools.
#  Educational / authorized security research use only.
# ============================================================

TOOL_NAME="AaryanXSky Toolkit"
BASE_DIR="$HOME/.aaryanxsky-toolkit"
LOG_FILE="$BASE_DIR/audit.log"
LOOT_DIR="$BASE_DIR/loot"
CANARY_DIR="$BASE_DIR/canary"
CANARY_LOG="$CANARY_DIR/hits.log"
CANARY_PORT=8901

mkdir -p "$LOOT_DIR" "$CANARY_DIR"
touch "$LOG_FILE" "$CANARY_LOG"

# ---------- Colors ----------
GREEN='\033[0;32m'
CYAN='\033[0;36m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

# ---------- Helpers ----------
log_action() {
    echo "$(date -u +'%Y-%m-%dT%H:%M:%SZ') | $1" >> "$LOG_FILE"
}

pause() {
    echo
    read -rp "Press Enter to return to menu..." _
}

banner() {
    clear
    echo -e "${GREEN}${BOLD}"
    cat << "EOF"
   _                          __  _____ _
  /_\  __ _ _ _ _  _ __ _ _ _ \ \/ / __| |___  _
 / _ \/ _` | '_| || / _` | ' \ >  <\__ \ / / || |
/_/ \_\__,_|_|  \_, \__,_|_||_/_/\_\___/_\_\\_, |
                |__/                        |__/
EOF
    echo -e "${NC}${CYAN}          ${TOOL_NAME}${NC}"
    echo -e "${YELLOW}   OSINT / Recon / Forensics — Kali-native edition${NC}"
    echo -e "   Log: $LOG_FILE"
    echo "-------------------------------------------------------------"
}

need() {
    # need <binary> <apt-package-name>
    if ! command -v "$1" >/dev/null 2>&1; then
        echo -e "${RED}[!] '$1' not found.${NC}"
        read -rp "Install now with apt (needs sudo)? [y/N] " ans
        if [[ "$ans" =~ ^[Yy]$ ]]; then
            sudo apt update && sudo apt install -y "$2"
        else
            echo -e "${RED}Skipping — this feature needs '$1'.${NC}"
            return 1
        fi
    fi
    return 0
}

# ---------- Dependency check ----------
check_all_deps() {
    banner
    echo "Checking dependencies..."
    echo
    declare -A tools=(
        [whois]=whois
        [geoiplookup]=geoip-bin
        [theHarvester]=theharvester
        [dnsenum]=dnsenum
        [exiftool]=libimage-exiftool-perl
        [nmap]=nmap
        [airodump-ng]=aircrack-ng
        [python3]=python3
        [curl]=curl
    )
    for bin in "${!tools[@]}"; do
        if command -v "$bin" >/dev/null 2>&1; then
            echo -e "  [${GREEN}OK${NC}] $bin"
        else
            echo -e "  [${RED}MISSING${NC}] $bin  (apt package: ${tools[$bin]})"
        fi
    done
    echo
    read -rp "Install all missing packages now? [y/N] " ans
    if [[ "$ans" =~ ^[Yy]$ ]]; then
        sudo apt update
        sudo apt install -y whois geoip-bin theharvester dnsenum \
            libimage-exiftool-perl nmap aircrack-ng python3 curl
    fi
    pause
}

# ---------- 1. IP Intelligence ----------
ip_intel() {
    banner
    echo -e "${CYAN}== IP Intelligence ==${NC}"
    read -rp "Enter IPv4/IPv6 address: " ip
    [[ -z "$ip" ]] && { echo "No IP given."; pause; return; }

    need whois whois || { pause; return; }
    outfile="$LOOT_DIR/ip_${ip//[:.]/_}_$(date +%s).txt"

    {
        echo "=== WHOIS for $ip ==="
        whois "$ip" 2>/dev/null
        echo
        if command -v geoiplookup >/dev/null 2>&1; then
            echo "=== GeoIP ==="
            geoiplookup "$ip"
        fi
    } | tee "$outfile"

    log_action "ip_intel target=$ip saved=$outfile"
    echo -e "\n${GREEN}Saved to $outfile${NC}"
    pause
}

# ---------- 2. Domain Recon ----------
domain_recon() {
    banner
    echo -e "${CYAN}== Domain Recon (theHarvester + whois + dnsenum) ==${NC}"
    read -rp "Enter domain (e.g. example.com): " domain
    [[ -z "$domain" ]] && { echo "No domain given."; pause; return; }

    outfile="$LOOT_DIR/domain_${domain}_$(date +%s).txt"

    {
        echo "=== WHOIS for $domain ==="
        need whois whois && whois "$domain" 2>/dev/null
        echo
        echo "=== DNS resolution ==="
        getent hosts "$domain"
        echo
        if need theHarvester theharvester; then
            echo "=== theHarvester (passive, source=all) ==="
            theHarvester -d "$domain" -b all 2>/dev/null
        fi
    } | tee "$outfile"

    echo
    read -rp "Run dnsenum too? (can be noisy/active) [y/N] " ans
    if [[ "$ans" =~ ^[Yy]$ ]] && need dnsenum dnsenum; then
        dnsenum "$domain" | tee -a "$outfile"
    fi

    log_action "domain_recon target=$domain saved=$outfile"
    echo -e "\n${GREEN}Saved to $outfile${NC}"
    pause
}

# ---------- 3. EXIF Forensics ----------
exif_forensics() {
    banner
    echo -e "${CYAN}== EXIF Forensics ==${NC}"
    read -rp "Path to image file (jpg/png): " img
    if [[ ! -f "$img" ]]; then
        echo -e "${RED}File not found.${NC}"
        pause; return
    fi
    need exiftool libimage-exiftool-perl || { pause; return; }

    outfile="$LOOT_DIR/exif_$(basename "$img")_$(date +%s).txt"
    exiftool "$img" | tee "$outfile"

    echo
    echo -e "${YELLOW}-- GPS fields only --${NC}"
    exiftool -gpslatitude -gpslongitude -gpsposition "$img"

    log_action "exif_forensics file=$img saved=$outfile"
    echo -e "\n${GREEN}Saved to $outfile${NC}"
    pause
}

# ---------- 4. Port / Service Scan ----------
port_scan() {
    banner
    echo -e "${CYAN}== Port / Service Scan (nmap) ==${NC}"
    read -rp "Enter target IP or host: " target
    [[ -z "$target" ]] && { echo "No target given."; pause; return; }
    need nmap nmap || { pause; return; }

    echo "1) Quick scan (top 100 ports)"
    echo "2) Full scan with service/version detection"
    read -rp "Choose [1/2]: " mode
    outfile="$LOOT_DIR/portscan_${target//[:.]/_}_$(date +%s).txt"

    if [[ "$mode" == "2" ]]; then
        nmap -sV -T4 "$target" | tee "$outfile"
    else
        nmap --top-ports 100 "$target" | tee "$outfile"
    fi

    log_action "port_scan target=$target mode=$mode saved=$outfile"
    echo -e "\n${GREEN}Saved to $outfile${NC}"
    pause
}

# ---------- 5. Wi-Fi / BSSID Recon ----------
wifi_recon() {
    banner
    echo -e "${CYAN}== Wi-Fi / BSSID Recon (aircrack-ng suite) ==${NC}"
    echo -e "${YELLOW}Requires a monitor-mode-capable wireless adapter.${NC}"
    echo "This only launches the tools — you drive them interactively,"
    echo "since scanning needs a live interface and root."
    echo
    need airodump-ng aircrack-ng || { pause; return; }

    read -rp "Wireless interface (e.g. wlan0): " iface
    [[ -z "$iface" ]] && { echo "No interface given."; pause; return; }

    echo -e "${YELLOW}About to run:${NC} sudo airmon-ng start $iface"
    read -rp "Proceed? [y/N] " ans
    if [[ "$ans" =~ ^[Yy]$ ]]; then
        sudo airmon-ng start "$iface"
        echo "Now launching airodump-ng — press Ctrl+C to stop."
        sleep 2
        sudo airodump-ng "${iface}mon" 2>/dev/null || sudo airodump-ng "$iface"
        log_action "wifi_recon iface=$iface"
    fi
    pause
}

# ---------- 6. Canary Token (self-hosted, lightweight) ----------
ensure_canary_server() {
    SERVER_PY="$CANARY_DIR/canary_server.py"
    if [[ -f "$SERVER_PY" ]]; then return; fi
    cat > "$SERVER_PY" << 'PYEOF'
import sys, http.server, socketserver, datetime, os

PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 8901
LOG_PATH = sys.argv[2] if len(sys.argv) > 2 else "hits.log"

class Handler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        canary_id = self.path.strip("/").split("/")[-1] or "unknown"
        ip = self.headers.get("X-Forwarded-For", self.client_address[0])
        ua = self.headers.get("User-Agent", "unknown")
        ts = datetime.datetime.utcnow().isoformat() + "Z"
        line = f"{ts} | canary_id={canary_id} | ip={ip} | ua={ua}\n"
        with open(LOG_PATH, "a") as f:
            f.write(line)
        print("[HIT]", line.strip())
        self.send_response(200)
        self.send_header("Content-Type", "text/html")
        self.end_headers()
        self.wfile.write(b"<h1>ok</h1>")
    def log_message(self, *args):
        pass  # keep console clean; hits.log has everything

with socketserver.TCPServer(("0.0.0.0", PORT), Handler) as httpd:
    print(f"Canary listener running on port {PORT}. Logging to {LOG_PATH}")
    httpd.serve_forever()
PYEOF
}

canary_generate() {
    banner
    echo -e "${CYAN}== Canary Token Generator ==${NC}"
    read -rp "Label for this token (optional): " label
    label="${label:-anon}"
    canary_id=$(cat /proc/sys/kernel/random/uuid | cut -c1-8)

    echo "$canary_id|$label|$(date -u +'%Y-%m-%dT%H:%M:%SZ')" >> "$CANARY_DIR/tokens.txt"

    ip=$(hostname -I 2>/dev/null | awk '{print $1}')
    echo
    echo -e "${GREEN}Token created:${NC} $canary_id (label: $label)"
    echo -e "${GREEN}Tracking URL (once listener is running):${NC} http://${ip:-<your-ip>}:${CANARY_PORT}/canary/$canary_id"
    echo
    echo "Start the listener from the Canary submenu to begin logging hits."
    log_action "canary_generate id=$canary_id label=$label"
    pause
}

canary_start_listener() {
    ensure_canary_server
    banner
    echo -e "${CYAN}== Starting Canary Listener on port $CANARY_PORT ==${NC}"
    echo "Press Ctrl+C to stop."
    log_action "canary_listener_start port=$CANARY_PORT"
    python3 "$CANARY_DIR/canary_server.py" "$CANARY_PORT" "$CANARY_LOG"
    pause
}

canary_view_logs() {
    banner
    echo -e "${CYAN}== Canary Hit Logs ==${NC}"
    if [[ -s "$CANARY_LOG" ]]; then
        cat "$CANARY_LOG"
    else
        echo "No beacon hits recorded yet."
    fi
    pause
}

canary_menu() {
    while true; do
        banner
        echo -e "${CYAN}== Canary Token Menu ==${NC}"
        echo "1) Generate new token"
        echo "2) Start listener (logs incoming hits)"
        echo "3) View hit logs"
        echo "4) List generated tokens"
        echo "0) Back to main menu"
        read -rp "Select: " c
        case "$c" in
            1) canary_generate ;;
            2) canary_start_listener ;;
            3) canary_view_logs ;;
            4) banner; echo "Generated tokens:"; cat "$CANARY_DIR/tokens.txt" 2>/dev/null || echo "None yet."; pause ;;
            0) break ;;
            *) ;;
        esac
    done
}

# ---------- 7. Audit / Loot log ----------
view_audit_log() {
    banner
    echo -e "${CYAN}== Audit Log ==${NC}"
    cat "$LOG_FILE"
    pause
}

view_loot() {
    banner
    echo -e "${CYAN}== Loot Directory ($LOOT_DIR) ==${NC}"
    ls -lh "$LOOT_DIR" 2>/dev/null || echo "Empty."
    pause
}

export_all() {
    banner
    ts=$(date +%s)
    zipfile="$HOME/aaryanxsky-export-$ts.zip"
    if command -v zip >/dev/null 2>&1; then
        zip -r "$zipfile" "$LOOT_DIR" "$CANARY_DIR" "$LOG_FILE" >/dev/null
        echo -e "${GREEN}Exported everything to $zipfile${NC}"
    else
        echo -e "${RED}'zip' not installed. Install with: sudo apt install zip${NC}"
    fi
    log_action "export_all file=$zipfile"
    pause
}

# ---------- Main Menu ----------
main_menu() {
    while true; do
        banner
        echo "1) IP Intelligence          (whois + geoip)"
        echo "2) Domain Recon              (theHarvester + whois + dnsenum)"
        echo "3) EXIF Forensics            (exiftool)"
        echo "4) Port / Service Scan       (nmap)"
        echo "5) Wi-Fi / BSSID Recon       (aircrack-ng)"
        echo "6) Canary Token              (generate / listen / logs)"
        echo "7) View Audit Log"
        echo "8) View Loot Directory"
        echo "9) Export Everything (.zip)"
        echo "d) Check / Install Dependencies"
        echo "0) Exit"
        echo "-------------------------------------------------------------"
        read -rp "Select an option: " choice
        case "$choice" in
            1) ip_intel ;;
            2) domain_recon ;;
            3) exif_forensics ;;
            4) port_scan ;;
            5) wifi_recon ;;
            6) canary_menu ;;
            7) view_audit_log ;;
            8) view_loot ;;
            9) export_all ;;
            d|D) check_all_deps ;;
            0) echo "Bye."; exit 0 ;;
            *) ;;
        esac
    done
}

main_menu
