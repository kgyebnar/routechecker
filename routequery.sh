#!/bin/bash

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
WHOIS_SERVERS=(
    "whois.radb.net"
    "whois.ripe.net"
    "whois.jp.apnic.net"
)

# Read ASNs from AS.txt (comma-separated)
IFS=',' read -r -a ASN_LIST < AS.txt

for ASN in "${ASN_LIST[@]}"; do
    ASN_TRIMMED=$(echo "$ASN" | xargs)
    TEMP_FILE="routes_temp_${ASN_TRIMMED}.txt"
    OUTPUT_FILE="ipv4_routes_${ASN_TRIMMED}_${TIMESTAMP}.txt"
    DIFF_FILE="diff_${ASN_TRIMMED}_${TIMESTAMP}.txt"
    LATEST_FILE="${ASN_TRIMMED}_latest.txt"
    LOG_FILE="log_${ASN_TRIMMED}.txt"

    echo "Fetching IPv4 route objects for $ASN_TRIMMED from multiple IRRs..."
    > "$TEMP_FILE"

    for SERVER in "${WHOIS_SERVERS[@]}"; do
        echo "Querying $SERVER for $ASN_TRIMMED..."
        whois -h "$SERVER" " -i origin $ASN_TRIMMED" 2>/dev/null \
            | grep -E "^route:" \
            | awk '{print $2}' >> "$TEMP_FILE"
    done

    # Deduplicate and remove default + RFC1918 + loopback + NAT + link-local routes
    grep -Ev '^(0\.0\.0\.0/0|10\.|172\.(1[6-9]|2[0-9]|3[0-1])\.|192\.168\.|127\.|100\.64\.|169\.254\.)' "$TEMP_FILE" \
        | sort -u > "$OUTPUT_FILE"

    # Count final prefix lines
    PREFIX_COUNT=$(wc -l < "$OUTPUT_FILE")

    # Keep only latest and previous version, delete older
    cp "$OUTPUT_FILE" "$LATEST_FILE"
    FILES=($(ls -t ipv4_routes_${ASN_TRIMMED}_*.txt | grep -v "$LATEST_FILE"))
    if (( ${#FILES[@]} > 2 )); then
        for ((i=2; i<${#FILES[@]}; i++)); do
            rm -f "${FILES[$i]}"
        done
    fi

    # Generate DIFF against previous version
    PREVIOUS_FILE=$(ls -t ipv4_routes_${ASN_TRIMMED}_*.txt | grep -v -e "$OUTPUT_FILE" -e "$LATEST_FILE" | head -n 1)
    if [[ -f "$PREVIOUS_FILE" ]]; then
        echo "Generating diff with previous version: $PREVIOUS_FILE"
        diff -u "$PREVIOUS_FILE" "$OUTPUT_FILE" > "$DIFF_FILE"
        echo "DIFF saved to $DIFF_FILE"

        # Check if more than 5 lines differ (not counting headers)
        DIFF_CHANGES=$(grep -E '^[-+]' "$DIFF_FILE" | grep -v '^[-+]{3}' | wc -l)
        if (( DIFF_CHANGES > 5 )); then
            echo "⚠️  More than 5 changes detected in ASN $ASN_TRIMMED! ($DIFF_CHANGES changes)"
            echo "$TIMESTAMP: $DIFF_CHANGES changes in $ASN_TRIMMED" >> "$LOG_FILE"
        else
            echo "$TIMESTAMP: $DIFF_CHANGES changes in $ASN_TRIMMED" >> "$LOG_FILE"
        fi
    else
        echo "No previous file found. Skipping diff for $ASN_TRIMMED."
        echo "$TIMESTAMP: initial version created for $ASN_TRIMMED with $PREFIX_COUNT prefixes" >> "$LOG_FILE"
    fi

    rm -f "$TEMP_FILE"
    echo "Finished processing $ASN_TRIMMED. Output: $OUTPUT_FILE"
done
