#!/bin/bash

# Script downloads logs, processes them, and uploads the report
# Cron example, cmd argument (10 or 30) is the number of logs to process
    # Number of days if the webhost rotates the log each day as it does in my case
# Runs every 10 minutes
    # */10 * * * * /bin/bash /opt/goaccess/gen-reports.sh 10 > /opt/goaccess/gen-reports-10.log 2>&1
# Runs 5 minuts before the date rolls over, account for UTC offset if needed since the config converts to UTC
    # 55 23 * * *  /bin/bash /opt/goaccess/gen-reports.sh 30 > /opt/goaccess/gen-reports-30.log 2>&1

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <number_of_logs>"
    exit 1
fi

# Logs to process
log_day_count="$1"

# Log directory
logs_dir="/opt/goaccess/logs"

# Report directory
reports_dir="/opt/goaccess/reports"

# Copy down logs
# Exclude compressed logs (same name ends with .gz), include the access logs, exclude everything else not matching.
/usr/bin/rsync -avzP --exclude='*.gz' --include='access.log.*.*' --exclude='*' -e "ssh -i /path/to/ssh-key" user@web-host:logs/ $logs_dir

# Clear combined log file
# https://unix.stackexchange.com/a/485652
: > "$logs_dir/combined.access.log"

# Combine last x logs into one file
recent_logs=($(/usr/bin/ls -1t $logs_dir/access.log.*.* | /usr/bin/head -n "$log_day_count"))
# echo ${recent_logs[@]}
for log_file in "${recent_logs[@]}"
do
    /usr/bin/cat "$log_file" | /usr/bin/grep -v -e '/report.html' -e '/reports/' >> "$logs_dir/combined.access.log"
done

# Run goaccess on the combined log file
/usr/bin/goaccess "$logs_dir/combined.access.log" --config-file=/opt/goaccess/goaccess.conf --html-report-title="Visitor Statistics $log_day_count Days (UTC)" -o $reports_dir/report$log_day_count.html

# Upload reports
/usr/bin/rsync -avzP -e "ssh -i /path/to/ssh-key" $reports_dir/ user@web-host:reports/

# Clear combined log file
# https://unix.stackexchange.com/a/485652
: > "$logs_dir/combined.access.log"

echo "===== DONE ====="
