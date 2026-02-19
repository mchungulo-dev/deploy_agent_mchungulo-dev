Written by: Memory Chungulo
Email: m.chungulo@alustudent.com
Video Link:

# Student Attendance Tracker - Project Factory

A shell script that automates the creation and configuration of a Student Attendance Tracker project workspace.

## How to Run the Script

### Step 1: Make the script executable
```bash
chmod +x setup_project.sh
```

### Step 2: Run the script
```bash
./setup_project.sh
```

### Step 3: Follow the prompts
1. **Enter a directory name** when prompted (e.g., `v1`, `project1`)
2. **Choose whether to update thresholds** - Enter `y` or `n`
   - If yes, enter new Warning and Failure threshold values
   - Press Enter to use default values
3. **Review the health check** - The script will verify Python installation and directory structure

### Step 4: Navigate to the created directory and run the attendance checker
```bash
cd attendance_tracker_{your_directory_name}
python3 attendance_checker.py
```

## How to Trigger the Archive Feature

The archive feature is automatically triggered when you **interrupt the script** during execution.

### To trigger the archive:
1. Run the script: `./setup_project.sh`
2. Press **Ctrl+C** at any time during the setup process

### What happens:
- The script catches the interrupt signal
- Creates an archive folder: `attendance_tracker_{input}_archive`
- Removes the incomplete directory to keep workspace clean
- Displays a confirmation message

### Example:
```bash
./setup_attendance.sh
Enter the directory name: test
^C
Script interrupted! Cleaning up...
Incomplete project archived as: attendance_tracker_test_archive.tar.gz
Incomplete directory removed.
Exiting script.
```

The archive file will be saved in the same directory where you ran the script.
