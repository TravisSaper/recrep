#!/usr/bin/env bash

set -uo pipefail

usage() {
    echo "Recrep is a tool to assist in the reporting of the first 3 phases of the recon pipeline."
    echo ""
    echo "Usage:"
    echo "   recrep.sh [flags]"
    echo ""
    echo "Flags:"
    echo "INPUT:"
    echo "   -d string       one domain in scope to use in the report"
    echo "   -l string       file containing domains in scope to use in the report"
    echo "   -t string       target name to use in the report (default: TARGET)"
    echo "RATE-LIMIT:"
    echo "   -r int       rate limit for the report (default: 10)"
    echo "OUTPUT:"
    echo "   -o string       directory to write output to"
}

OUTDIR=""
DOMAIN=""
DOMAIN_LIST=""
RATE_LIMIT=10
TARGET_NAME="TARGET"
DATE=$(date +%Y-%m-%d)

while getopts ":d:l:o:r:t:h" opt; do
    case "$opt" in
        d) DOMAIN="$OPTARG" ;;
        l) DOMAIN_LIST="$OPTARG" ;;
        o) OUTDIR="$OPTARG" ;;
        r) RATE_LIMIT="$OPTARG" ;;
        t) TARGET_NAME="$OPTARG" ;;
        h)
            usage
            exit 0
            ;;
        :)
            echo "[!] Option -$OPTARG requires an argument"
            usage
            exit 1
            ;;
        \?)
            echo "[!] Invalid option: -$OPTARG"
            usage
            exit 1
            ;;
    esac
done

if [[ -n "$DOMAIN" && -n "$DOMAIN_LIST" ]]; then
    echo "[!] Use either -d or -l, not both"
    echo "Do recrep -h for usage"
    exit 1
fi

if [[ -z "$DOMAIN" && -z "$DOMAIN_LIST" ]]; then
    echo "[!] You must provide either -d or -l"
    echo "Do recrep -h for usage"
    exit 1
fi

if ! [[ "$RATE_LIMIT" =~ ^[1-9][0-9]*$ ]]; then
    echo "[!] Rate limit must be a positive integer"
    exit 1
fi

if [[ -n "$DOMAIN" ]]; then
    OUTDIR="${OUTDIR:-recon_${DOMAIN}}"
else
    if [[ ! -f "$DOMAIN_LIST" ]]; then
        echo "[!] Domain list file not found: $DOMAIN_LIST"
        exit 1
    fi

    FIRST_DOMAIN=$(grep -m 1 -v '^[[:space:]]*$' "$DOMAIN_LIST" || true)

    if [[ -z "$FIRST_DOMAIN" ]]; then
        echo "[!] Domain list file is empty"
        exit 1
    fi

    OUTDIR="${OUTDIR:-recon_${FIRST_DOMAIN}}"
fi

mkdir -p "$OUTDIR/report" || {
    echo "[!] Failed to create output directory: $OUTDIR"
    exit 1
}

cd "$OUTDIR" || {
    echo "[!] Failed to enter output directory: $OUTDIR"
    exit 1
}

PHASE=0

banner() {
    printf '%s\n' '
========================
██████╗ ███████╗ ██████╗██████╗ ███████╗██████╗
██╔══██╗██╔════╝██╔════╝██╔══██╗██╔════╝██╔══██╗
██████╔╝█████╗  ██║     ██████╔╝█████╗  ██████╔╝
██╔══██╗██╔══╝  ██║     ██╔══██╗██╔══╝  ██╔═══╝
██║  ██║███████╗╚██████╗██║  ██║███████╗██║
╚═╝  ╚══════╝╚═════╝╚═╝  ╚═╝╚══════╝╚═╝
========================
'
}

phase() {
    PHASE=$((PHASE + 1))
    printf '\n==================================================\n'
    printf '  PHASE %s: %s\n' "$PHASE" "$1"
    printf '==================================================\n'
}

log() {
    printf '\n[*] %s\n' "$1"
}

need() {
    command -v "$1" >/dev/null 2>&1 || {
        printf "[!] '%s' not found on PATH, skipping that step\n" "$1"
        return 1
    }
}

banner

phase "Information Gathering — subfinder, assetfinder, httpx"

if [[ -n "$DOMAIN" ]]; then
    echo "Subfinder on $DOMAIN"
else
    echo "Subfinder on domains from $DOMAIN_LIST"
fi

if [[ -n "$DOMAIN" ]]; then
    if need subfinder; then
        subfinder -d "$DOMAIN" -rl "$RATE_LIMIT" -o subfinder.txt
    else
        touch subfinder.txt
    fi

elif [[ -n "$DOMAIN_LIST" ]]; then
    if need subfinder; then
        subfinder -dL "$DOMAIN_LIST" -rl "$RATE_LIMIT" -o subfinder.txt
    else
        touch subfinder.txt
    fi
fi

if [[ -n "$DOMAIN" ]]; then
    echo "Assetfinder on $DOMAIN"
else
    echo "Assetfinder on domains from $DOMAIN_LIST"
fi

if [[ -n "$DOMAIN" ]]; then
    if need assetfinder; then
        assetfinder --subs-only "$DOMAIN" > assetfinder.txt
    else
        touch assetfinder.txt
    fi
elif [[ -n "$DOMAIN_LIST" ]]; then
    if need assetfinder; then
        while IFS= read -r domain; do
        [[ -n "$domain" ]] || continue
        assetfinder --subs-only "$domain"
        done < "$DOMAIN_LIST" > assetfinder.txt
    else
        touch assetfinder.txt
    fi
fi

cat subfinder.txt assetfinder.txt | sort -u > subs.txt

echo "Httpx on subs.txt"
if need httpx; then
    httpx -l subs.txt -silent -status-code -title -tech-detect -rl "$RATE_LIMIT" \
        -o recon_results_code.txt
else
    touch recon_results_code.txt
fi

: > interesting_findings.txt

echo "Identifying interesting findings..."

echo "Interesting subdomains:" >> interesting_findings.txt
grep -Ei 'admin|api|dev|stage|staging|test|internal|dashboard|portal|vpn|auth|beta' subs.txt \
    >> interesting_findings.txt || true

echo "" >> interesting_findings.txt
echo "Interesting HTTP responses:" >> interesting_findings.txt
grep -E '\[(200|301|302|401|403|404|500)\]' recon_results_code.txt \
    >> interesting_findings.txt || true


echo "Writing report to report/report.md"

REPORT_FILE="report/report.md"

{
    printf '# %s\n\n' "$TARGET_NAME"

    echo "# Use custom header"
    echo ""

    echo "# In Scope"
    if [[ -n "$DOMAIN" ]]; then
        echo "$DOMAIN"
    else
        cat "$DOMAIN_LIST"
    fi
    echo ""

    echo "# Out of Scope"
    echo ""

    echo "# Reporting"
    echo ""

    echo "# Forbidden"
    echo ""

    echo "# Acceptable"
    echo ""
    echo "Automated scanning: $RATE_LIMIT Requests per second"
    echo "Target: ${DOMAIN:-$DOMAIN_LIST}"
    echo "Date: $DATE"
    echo ""

    echo "Subdomains Found:"
    echo ""

    while IFS= read -r line; do
        [[ -n "$line" ]] || continue
        url="${line%% *}"
        rest="${line#"$url"}"
        printf '[%s](%s)%s\n\n' "$url" "$url" "$rest"
    done < recon_results_code.txt

    echo "# Interesting Findings:"
    echo ""

    while IFS= read -r line; do
        if [[ "$line" == "[+]"* || -z "$line" ]]; then
            echo "$line"
            continue
        fi

        if [[ "$line" == http://* || "$line" == https://* ]]; then
            url="${line%% *}"
            rest="${line#"$url"}"
            printf '[%s](%s)%s\n\n' "$url" "$url" "$rest"
        else
            echo "$line"
        fi
    done < interesting_findings.txt

} > "$REPORT_FILE"

log "Report written to $OUTDIR/$REPORT_FILE"
