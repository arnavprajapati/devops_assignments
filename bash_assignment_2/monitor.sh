#!/bin/bash

LOG_FILE="/var/log/health_monitor.log"
SERVICES_FILE="services.txt"
DRY_RUN=false

# Check for --dry-run flag
if [[ "$1" == "--dry-run" ]]; then
    DRY_RUN=true
    echo "[INFO] Running in DRY-RUN mode (no actual restarts)"
fi

# Counters
total=0
healthy=0
recovered=0
failed=0

# Check if services.txt exists
if [[ ! -f "$SERVICES_FILE" ]]; then
    echo "[ERROR] services.txt file not found!"
    exit 1
fi

# Check if file is empty
if [[ ! -s "$SERVICES_FILE" ]]; then
    echo "[ERROR] services.txt is empty!"
    exit 1
fi

# Function to log events
log_event() {
    local severity=$1
    local message=$2
    echo "$(date '+%Y-%m-%d %H:%M:%S') [$severity] $message" >> "$LOG_FILE"
}

echo "===== Service Health Monitor ====="
echo "User: $(whoami)"
echo "Host: $(hostname)"
echo "----------------------------------"

# Loop through services
while IFS= read -r service; do
    ((total++))

    status=$(systemctl is-active "$service" 2>/dev/null)

    if [[ "$status" == "active" ]]; then
        echo "✔ $service is running"
        ((healthy++))
    else
        echo "✖ $service is NOT running"

        if [[ "$DRY_RUN" == true ]]; then
            echo "[DRY-RUN] Would restart $service"
            log_event "INFO" "$service would be restarted (dry-run)"
            continue
        fi

        echo "→ Restarting $service..."
        systemctl restart "$service"

        sleep 5

        new_status=$(systemctl is-active "$service" 2>/dev/null)

        if [[ "$new_status" == "active" ]]; then
            echo "✔ $service recovered"
            log_event "RECOVERED" "$service restarted successfully"
            ((recovered++))
        else
            echo "✖ $service failed to recover"
            log_event "FAILED" "$service failed to restart"
            ((failed++))
        fi
    fi

done < "$SERVICES_FILE"

# Summary
echo ""
echo "========= SUMMARY ========="
echo "Total Checked : $total"
echo "Healthy       : $healthy"
echo "Recovered     : $recovered"
echo "Failed        : $failed"
echo "==========================="