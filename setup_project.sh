#!/bin/bash

# Trap to handle script interruption
handle_termination() {
    echo -e "\n\n⚠️  Interrupted! Cleaning up..."

    # Use the specific version variable you captured
    local target="attendance_tracker_${input}"

    # Check if THAT specific directory exists
    if [ -n "$input" ] && [ -d "$target" ]; then
        echo "Archiving current project: $target"
        tar -czf "${target}_archive.tar.gz" "$target"
        rm -rf "$target"
        echo "Done. Workspace clean."
    else
        # This handles the case where you hit Ctrl+C before typing a version
        echo "No specific project folder found to archive."
    fi

    exit 1
}

trap handle_termination SIGINT

# Check if python3 is installed
if python3 --version &> /dev/null; then
    echo "Health Check: Python 3 is installed and ready to use."
else
    echo "Warning: Python 3 is NOT found. The application may not run correctly."

fi

# Ask the user for an input regarding what version of the Attendance Tracker they'd like
read -p "Enter the version:" input

#Check if main directory exists
if [ -d "attendance_tracker_${input}" ]; then
	echo "Directory exists"
        exit 1
fi

# Ask the 'Yes/No' question for the user to update their settings
read -p "Would you like to update the attendance thresholds? (y/n):" update_answer

# Use an if statement to check if they said yes
if [ "$update_answer" == "y" ]; then

# Ask the user for the Warning Threshold (Default 75%)
read -p "Enter new Warning threshold (e.g., 80):" warning_percentage

# Ask the user for the Failure Threshold (Default 50%)
read -p "Enter new Failure threshold (e.g., 40):" failure_percentage

# Message they'll recieve
echo "Updating thresholds to $warning_percentage% and $failure_percentage%..."

fi

# Create the directory according to the input they gave you
mkdir attendance_tracker_${input}
echo "attendance tracker folder created"

# Create the Python file
touch "attendance_tracker_${input}/attendance_checker.py"

# Add content in the Python file
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
            
            # Simple Math: (Attended / Total) * 100
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

# Create the Helpers directory
mkdir "attendance_tracker_${input}/Helpers"

# Create the reports directory
mkdir "attendance_tracker_${input}/reports"

# Create the assets.csv file in the Helpers directory and add content in it 
cat > "attendance_tracker_${input}/Helpers/assets.csv" << 'EOF'
Email,Names,Attendance Count,Absence Count
alice@example.com,Alice Johnson,14,1
bob@example.com,Bob Smith,7,8
charlie@example.com,Charlie Davis,4,11
diana@example.com,Diana Prince,15,0
EOF

# Create the config.json file in the Helpers directory and add content in it
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

# Create the reports.log file in the reports directory and add content in it
cat > "attendance_tracker_${input}/reports/reports.log" << 'EOF'
--- Attendance Report Run: 2026-02-06 18:10:01.468726 ---
[2026-02-06 18:10:01.469363] ALERT SENT TO bob@example.com: URGENT: Bob Smith, your attendance is 46.7%. You will fail this class.
[2026-02-06 18:10:01.469424] ALERT SENT TO charlie@example.com: URGENT: Charlie Davis, your attendance is 26.7%. You will fail this class.
EOF

# The sed command
sed -i "s/\"warning\": [0-9]*/\"warning\": $warning_percentage/" "attendance_tracker_${input}/Helpers/config.json"
sed -i "s/\"failure\": [0-9]*/\"failure\": $failure_percentage/" "attendance_tracker_${input}/Helpers/config.json"
