#!/bin/bash

SITES_FILE="/usr/local/etc/traffic_sites.txt"

# Make sure the file exists
if [[ ! -f "$SITES_FILE" ]]; then
    echo "Error: $SITES_FILE not found!"
    exit 1
fi

# Load websites into array
mapfile -t SITES < "$SITES_FILE"

# Randomize how many bursts we’ll do today (60–120)
BURSTS=$(( 60 + RANDOM % 61 ))

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting new day with $BURSTS bursts planned."

for ((b=1; b<=BURSTS; b++)); do
    # Random number of requests per burst (5–25)
    REQS=$(( 5 + RANDOM % 21 ))
    echo "[$(date '+%H:%M:%S')] Burst $b → $REQS requests"

    for ((i=1; i<=REQS; i++)); do
        SITE=${SITES[$RANDOM % ${#SITES[@]}]}

        AGENT=$(shuf -n1 <<EOF
Mozilla/5.0 (Windows NT 10.0; Win64; x64)
Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)
Mozilla/5.0 (X11; Linux x86_64)
curl/7.81.0
EOF
)
        echo "   → Request $i to $SITE"
        curl -A "$AGENT" -s -o /dev/null -w "Status: %{http_code}\n" "$SITE"

        # Small pause inside burst
        sleep $((1 + RANDOM % 5))
    done

    # Average spacing between bursts = 24h / BURSTS
    # Add randomness: 50%–150% of average
    AVG_INTERVAL=$(( 86400 / BURSTS ))
    SLEEP_TIME=$(( (AVG_INTERVAL / 2) + RANDOM % AVG_INTERVAL ))
    echo "   Sleeping $SLEEP_TIME seconds until next burst."
    sleep $SLEEP_TIME
done

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Daily quota finished, sleeping until tomorrow."

# Sleep until midnight, then restart
NOW=$(date +%s)
MIDNIGHT=$(date -d "tomorrow 00:00" +%s)
sleep $(( MIDNIGHT - NOW ))

exec "$0"
