#!/bin/bash

read -p "Enter the version:" input

mkdir "attendance_tracker-$input"

mkdir "attendance_tracker-$input/attendance_checker.py"

mkdir "attendance_tracker-$input/Helpers"

mkdir "attendance_tracker-$input/reports"

touch "attendance_tracker-$input/Helpers/assets.csv"

touch "attendance_tracker-$input/Helpers/config.json"

touch "attendance_tracker-$input/reports/reports.log"
