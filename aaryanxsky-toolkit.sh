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

# type_effect <text> [delay] — typewriter-style print for hacker feel
type_effect() {
    local text="$1"
    local delay="${2:-0.012}"
    for ((i=0; i<${#text}; i++)); do
        printf "%s" "${text:$i:1}"
        sleep "$delay"
    done
    echo
}

# loading_bar <label> [seconds]
loading_bar() {
    local label="$1"
    local secs="${2:-2}"
    local width=30
    printf "${CYAN}%s${NC} [" "$label"
    for ((i=0; i<width; i++)); do
        printf "${GREEN}#${NC}"
        sleep "$(echo "$secs / $width" | bc -l 2>/dev/null || echo 0.05)"
    done
    printf "] 100%%\n"
}

# print_box <title> <content...> — bordered highlight box for key results
print_box() {
    local title="$1"; shift
    local width=63
    echo -e "${GREEN}╔$(printf '═%.0s' $(seq 1 $width))╗${NC}"
    printf "${GREEN}║${NC} ${BOLD}${CYAN}%-*s${NC}${GREEN}║${NC}\n" $((width-1)) "$title"
    echo -e "${GREEN}╠$(printf '═%.0s' $(seq 1 $width))╣${NC}"
    for line in "$@"; do
        printf "${GREEN}║${NC} %-*s${GREEN}║${NC}\n" $((width-1)) "$line"
    done
    echo -e "${GREEN}╚$(printf '═%.0s' $(seq 1 $width))╝${NC}"
}

boot_sequence() {
    clear
    echo -e "${GREEN}"
    if command -v cmatrix >/dev/null 2>&1; then
        timeout 2 cmatrix -s 2>/dev/null
    fi
    clear
    echo -e "${GREEN}${BOLD}"
    type_effect ">> initializing aaryanxsky-core..." 0.015
    type_effect ">> loading recon modules [whois|theHarvester|exiftool|nmap|aircrack-ng]..." 0.008
    type_effect ">> mounting loot directory: $LOOT_DIR" 0.008
    type_effect ">> access granted." 0.02
    sleep 0.3
    echo -e "${NC}"
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
    echo -e "${YELLOW}   [ROOT@GEOINT] OSINT / Recon / Forensics — Kali-native edition${NC}"
    echo -e "${GREEN}   Log:${NC} $LOG_FILE"
    echo -e "${GREEN}-------------------------------------------------------------${NC}"
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

# ---------- Map helper ----------
# show_on_map <lat> <lon> <label>
# Generates a small Leaflet HTML map pinned at the given coordinates
# and opens it in the default browser.
show_on_map() {
    local lat="$1" lon="$2" label="$3"
    [[ -z "$lat" || -z "$lon" ]] && return 1

    print_box "COORDINATES LOCKED" "TARGET : ${label}" "LAT    : ${lat}" "LON    : ${lon}"

    # Google Earth web view — zoomed street-level, top-down tilt
    local earth_url="https://earth.google.com/web/search/${lat},${lon}/@${lat},${lon},0a,1000d,35y,0h,0t,0r"

    echo -e "${GREEN}[+] Google Earth link:${NC} $earth_url"
    log_action "map_view label=${label} lat=${lat} lon=${lon} url=${earth_url}"

    if command -v xdg-open >/dev/null 2>&1; then
        xdg-open "$earth_url" >/dev/null 2>&1 &
        disown 2>/dev/null
        echo -e "${YELLOW}Opening in default browser...${NC}"
    else
        echo -e "${YELLOW}xdg-open not found. Open the link above manually.${NC}"
    fi
    if command -v xdg-open >/dev/null 2>&1; then
        xdg-open "$mapfile" >/dev/null 2>&1 &
    elif command -v sensible-browser >/dev/null 2>&1; then
        sensible-browser "$mapfile" >/dev/null 2>&1 &
    else
        echo "Open it manually in a browser: $mapfile"
    fi
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
        [traceroute]=traceroute
        [hashid]=hashid
        [sublist3r]=sublist3r
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
            libimage-exiftool-perl nmap aircrack-ng python3 curl \
            traceroute hashid sublist3r
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
    loading_bar "Tracing $ip" 1.5

    {
        echo "=== WHOIS for $ip ==="
        whois "$ip" 2>/dev/null
        echo
        if command -v geoiplookup >/dev/null 2>&1; then
            echo "=== GeoIP ==="
            geoiplookup "$ip"
        fi
    } | tee "$outfile"

    # Fetch precise lat/lon for map pin (free, no API key)
    if command -v curl >/dev/null 2>&1; then
        geo=$(curl -s "http://ip-api.com/json/${ip}?fields=status,lat,lon,city,country")
        lat=$(echo "$geo" | grep -oP '"lat":\s*\K[-0-9.]+')
        lon=$(echo "$geo" | grep -oP '"lon":\s*\K[-0-9.]+')
        city=$(echo "$geo" | grep -oP '"city":\s*"\K[^"]+')
        country=$(echo "$geo" | grep -oP '"country":\s*"\K[^"]+')
        if [[ -n "$lat" && -n "$lon" ]]; then
            echo -e "\n${YELLOW}Location:${NC} $city, $country ($lat, $lon)"
            show_on_map "$lat" "$lon" "IP: $ip ($city, $country)"
        fi
    fi

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
    loading_bar "Scanning $domain" 1.5

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

    # Resolve to an IP and show it on the map
    resolved_ip=$(getent hosts "$domain" | awk '{print $1}' | head -n1)
    if [[ -n "$resolved_ip" ]] && command -v curl >/dev/null 2>&1; then
        geo=$(curl -s "http://ip-api.com/json/${resolved_ip}?fields=status,lat,lon,city,country")
        lat=$(echo "$geo" | grep -oP '"lat":\s*\K[-0-9.]+')
        lon=$(echo "$geo" | grep -oP '"lon":\s*\K[-0-9.]+')
        city=$(echo "$geo" | grep -oP '"city":\s*"\K[^"]+')
        country=$(echo "$geo" | grep -oP '"country":\s*"\K[^"]+')
        if [[ -n "$lat" && -n "$lon" ]]; then
            echo -e "\n${YELLOW}Location:${NC} $city, $country ($lat, $lon)"
            show_on_map "$lat" "$lon" "$domain ($resolved_ip) — $city, $country"
        fi
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

    # Extract decimal lat/lon and show on map if present
    lat=$(exiftool -c "%+.6f" -GPSLatitude -n -s3 "$img" 2>/dev/null)
    lon=$(exiftool -c "%+.6f" -GPSLongitude -n -s3 "$img" 2>/dev/null)
    if [[ -n "$lat" && -n "$lon" ]]; then
        show_on_map "$lat" "$lon" "EXIF GPS — $(basename "$img")"
    else
        echo -e "${YELLOW}No GPS data found in this image.${NC}"
    fi

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

# ---------- 7. Subdomain Enumeration ----------
subdomain_enum() {
    banner
    echo -e "${CYAN}== Subdomain Enumeration ==${NC}"
    read -rp "Enter root domain (e.g. example.com): " domain
    [[ -z "$domain" ]] && { echo "No domain given."; pause; return; }

    outfile="$LOOT_DIR/subdomains_${domain}_$(date +%s).txt"
    loading_bar "Enumerating subdomains" 2

    if command -v sublist3r >/dev/null 2>&1; then
        sublist3r -d "$domain" -o "$outfile"
        cat "$outfile"
    elif command -v assetfinder >/dev/null 2>&1; then
        assetfinder --subs-only "$domain" | tee "$outfile"
    else
        echo -e "${YELLOW}Neither sublist3r nor assetfinder found.${NC}"
        echo "Falling back to certificate-transparency lookup (crt.sh)..."
        curl -s "https://crt.sh/?q=%25.${domain}&output=json" \
            | grep -oP '"name_value":"\K[^"]+' | sort -u | tee "$outfile"
    fi

    log_action "subdomain_enum target=$domain saved=$outfile"
    echo -e "\n${GREEN}Saved to $outfile${NC}"
    pause
}

# ---------- 8. MAC Address Vendor Lookup ----------
mac_lookup() {
    banner
    echo -e "${CYAN}== MAC Address Vendor Lookup ==${NC}"
    read -rp "Enter MAC address (e.g. AA:BB:CC:00:11:22): " mac
    [[ -z "$mac" ]] && { echo "No MAC given."; pause; return; }
    loading_bar "Resolving vendor" 1

    result=$(curl -s "https://api.macvendors.com/${mac}")
    if [[ "$result" == *"errors"* || -z "$result" ]]; then
        echo -e "${RED}Vendor not found or API unreachable.${NC}"
    else
        print_box "VENDOR MATCH" "MAC    : ${mac}" "VENDOR : ${result}"
    fi

    log_action "mac_lookup target=$mac result=$result"
    pause
}

# ---------- 9. Traceroute / Network Path ----------
trace_path() {
    banner
    echo -e "${CYAN}== Network Path Trace ==${NC}"
    read -rp "Enter target IP or host: " target
    [[ -z "$target" ]] && { echo "No target given."; pause; return; }
    need traceroute traceroute || { pause; return; }

    outfile="$LOOT_DIR/traceroute_${target//[:.]/_}_$(date +%s).txt"
    loading_bar "Tracing route" 2
    traceroute "$target" | tee "$outfile"

    log_action "trace_path target=$target saved=$outfile"
    echo -e "\n${GREEN}Saved to $outfile${NC}"
    pause
}

# ---------- 10. Hash Identifier ----------
hash_identify() {
    banner
    echo -e "${CYAN}== Hash Identifier ==${NC}"
    read -rp "Enter hash string: " hash
    [[ -z "$hash" ]] && { echo "No hash given."; pause; return; }

    if need hashid hashid; then
        hashid "$hash"
    else
        len=${#hash}
        echo "Hash length: $len characters"
        case $len in
            32) echo "Likely: MD5 / NTLM" ;;
            40) echo "Likely: SHA1" ;;
            64) echo "Likely: SHA256" ;;
            128) echo "Likely: SHA512" ;;
            *) echo "Unrecognized length — install hashid for full detection." ;;
        esac
    fi

    log_action "hash_identify hash_len=${#hash}"
    pause
}

# ---------- 11. HTML Report Generator ----------
generate_report() {
    banner
    echo -e "${CYAN}== Generating Full Report ==${NC}"
    loading_bar "Compiling loot" 2
    report="$LOOT_DIR/report_$(date +%s).html"

    {
        echo "<!DOCTYPE html><html><head><meta charset='UTF-8'>"
        echo "<title>AaryanXSky — Recon Report</title>"
        echo "<style>body{background:#0d0d0d;color:#00ff66;font-family:monospace;padding:24px;}"
        echo "h1{border-bottom:1px solid #00ff66;padding-bottom:8px;}"
        echo "pre{background:#111;padding:12px;border:1px solid #033;overflow-x:auto;}"
        echo "h2{color:#00e5ff;margin-top:32px;}</style></head><body>"
        echo "<h1>AaryanXSky Recon Report — $(date -u +'%Y-%m-%d %H:%M UTC')</h1>"
        for f in "$LOOT_DIR"/*.txt; do
            [[ -e "$f" ]] || continue
            echo "<h2>$(basename "$f")</h2><pre>$(sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g' "$f")</pre>"
        done
        echo "</body></html>"
    } > "$report"

    log_action "generate_report saved=$report"
    echo -e "${GREEN}Report saved:${NC} $report"
    command -v xdg-open >/dev/null 2>&1 && xdg-open "$report" >/dev/null 2>&1 &
    pause
}

# ---------- Audit / Loot log ----------
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
        echo "1)  IP Intelligence          (whois + geoip + map)"
        echo "2)  Domain Recon              (theHarvester + whois + dnsenum + map)"
        echo "3)  EXIF Forensics            (exiftool + GPS map)"
        echo "4)  Port / Service Scan       (nmap)"
        echo "5)  Wi-Fi / BSSID Recon       (aircrack-ng)"
        echo "6)  Canary Token              (generate / listen / logs)"
        echo "7)  Subdomain Enumeration     (sublist3r / crt.sh)"
        echo "8)  MAC Vendor Lookup"
        echo "9)  Network Path Trace        (traceroute)"
        echo "10) Hash Identifier"
        echo "11) Generate Full HTML Report"
        echo "12) View Audit Log"
        echo "13) View Loot Directory"
        echo "14) Export Everything (.zip)"
        echo "d)  Check / Install Dependencies"
        echo "0)  Exit"
        echo -e "${GREEN}-------------------------------------------------------------${NC}"
        read -rp "Select an option: " choice
        case "$choice" in
            1) ip_intel ;;
            2) domain_recon ;;
            3) exif_forensics ;;
            4) port_scan ;;
            5) wifi_recon ;;
            6) canary_menu ;;
            7) subdomain_enum ;;
            8) mac_lookup ;;
            9) trace_path ;;
            10) hash_identify ;;
            11) generate_report ;;
            12) view_audit_log ;;
            13) view_loot ;;
            14) export_all ;;
            d|D) check_all_deps ;;
            0) type_effect ">> session terminated." 0.02; exit 0 ;;
            *) ;;
        esac
    done
}

boot_sequence
main_menu
