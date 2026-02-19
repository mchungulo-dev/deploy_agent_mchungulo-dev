#!/bin/bash 

# Get & validate directory name
while true; do
    read -p "Enter the directory name: attendance_tracker_" input

    if [ -z "$input" ]; then
        echo "Error: Directory name cannot be empty. Please try again."
    else
        break
    fi
done


# Trap for Ctrl+C cleanup
handle_termination() {
    echo -e "\n\nInterrupted! Cleaning up..."
    target="attendance_tracker_${input}"

    if [ -d "$target" ]; then
        archive_name="${target}_archive"
        echo "Archiving current project: $target -> $archive_name"
        cp -r "$target" "$archive_name"
        rm -rf "$target"
        echo "Archive directory created: $archive_name"
        echo "Incomplete directory removed. Workspace clean."
    else
        echo "No project folder found to archive -- nothing to clean up."
    fi

    exit 1
}

trap handle_termination SIGINT

# Create folder structure early so trap can archive it on interrupt
mkdir -p "attendance_tracker_${input}/Helpers"
mkdir -p "attendance_tracker_${input}/reports"
echo "attendance_tracker_${input} folder structure created."

# Python health check
if python3 --version &> /dev/null; then
    echo "Health Check: Python 3 is installed and ready to use."
else
    echo "Warning: Python 3 is NOT found. The application may not run correctly."
fi

# Threshold validation helper
validate_threshold() {
    local prompt="$1"
    local result=""

    while true; do
        read -p "$prompt" result >&2

        if ! [[ "$result" =~ ^[0-9]+$ ]]; then
            echo "Error: Please enter a whole number (no decimals or letters)." >&2
            continue
        fi

        if [ "$result" -lt 0 ] || [ "$result" -gt 100 ]; then
            echo "Error: Value must be between 0 and 100." >&2
            continue
        fi

        break
    done

    echo "$result"
}

# Ask about threshold updates
while true; do
    read -p "Would you like to update the attendance thresholds? (y/n): " update_answer

    if [ "$update_answer" == "y" ] || [ "$update_answer" == "Y" ] || [ "$update_answer" == "n" ] || [ "$update_answer" == "N" ]; then
        break
    else
        echo "Error: Please enter 'y' or 'n' only."
    fi
done

if [ "$update_answer" == "y" ] || [ "$update_answer" == "Y" ]; then
    warning_percentage=$(validate_threshold "Enter new Warning threshold (0-100, e.g., 80): ")
    failure_percentage=$(validate_threshold "Enter new Failure threshold (0-100, e.g., 40): ")

    if [ "$failure_percentage" -ge "$warning_percentage" ]; then
        echo "Warning: Failure threshold ($failure_percentage%) should typically be lower than Warning threshold ($warning_percentage%)."
    fi

    echo "Thresholds captured: Warning=${warning_percentage}%, Failure=${failure_percentage}%"
fi


# Create attendance_checker.py
cat > "attendance_tracker_${input}/attendance_checker.py" << 'EOF'
import csv
import json
import os
from datetime import datetime

def run_attendance_check():
    # 1. Load Config
    with open('Helpers/config.json', 'r') as f:
        config = json.load(f)

    # 2. Archive old reports.log if it exists
    if os.path.exists('reports/reports.log'):
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        os.rename('reports/reports.log', f'reports/reports_{timestamp}.log.archive')

    # 3. Process Data
    with open('Helpers/assets.csv', mode='r') as f, open('reports/reports.log', 'w') as log:
        reader = csv.DictReader(f)
        total_sessions = config['total_sessions']

        log.write(f"--- Attendance Report Run: {datetime.now()} ---\n")

        for row in reader:
            name = row['Names']
            email = row['Email']
            attended = int(row['Attendance Count'])

            attendance_pct = (attended / total_sessions) * 100

            message = ""
            if attendance_pct < config['thresholds']['failure']:
                message = f"URGENT: {name}, your attendance is {attendance_pct:.1f}%. You will fail this class."
            elif attendance_pct < config['thresholds']['warning']:
                message = f"WARNING: {name}, your attendance is {attendance_pct:.1f}%. Please be careful."

            if message:
                if config['run_mode'] == "live":
                    log.write(f"[{datetime.now()}] ALERT SENT TO {email}: {message}\n")
                    print(f"Logged alert for {name}")
                else:
                    print(f"[DRY RUN] Email to {email}: {message}")

if __name__ == "__main__":
    run_attendance_check()
EOF

# Create assets.csv
cat > "attendance_tracker_${input}/Helpers/assets.csv" << 'EOF'
Email,Names,Attendance Count,Absence Count
alice@example.com,Alice Johnson,14,1
bob@example.com,Bob Smith,7,8
charlie@example.com,Charlie Davis,4,11
diana@example.com,Diana Prince,15,0
EOF

# Create config.json
cat > "attendance_tracker_${input}/Helpers/config.json" << 'EOF'
{
    "thresholds": {
        "warning": 75,
        "failure": 50
    },
    "run_mode": "live",
    "total_sessions": 15
}
EOF

# Create reports.log
cat > "attendance_tracker_${input}/reports/reports.log" << 'EOF'
--- Attendance Report Run: 2026-02-06 18:10:01.468726 ---
[2026-02-06 18:10:01.469363] ALERT SENT TO bob@example.com: URGENT: Bob Smith, your attendance is 46.7%. You will fail this class.
[2026-02-06 18:10:01.469424] ALERT SENT TO charlie@example.com: URGENT: Charlie Davis, your attendance is 26.7%. You will fail this class.
EOF

# Apply threshold updates to config.json (only if user said y/Y)
if [ "$update_answer" == "y" ] || [ "$update_answer" == "Y" ]; then
    sed -i "s/\"warning\": [0-9]*/\"warning\": ${warning_percentage}/" "attendance_tracker_${input}/Helpers/config.json"
    sed -i "s/\"failure\": [0-9]*/\"failure\": ${failure_percentage}/" "attendance_tracker_${input}/Helpers/config.json"
    echo "config.json updated with new thresholds."
fi

echo "Setup complete! Project ready at: attendance_tracker_${input}/"
