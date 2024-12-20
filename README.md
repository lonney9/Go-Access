# GoAccess Script

[GoAccess](https://goaccess.io/) cron script and config file.

- Downloads logs from webhost via rsync
- Combines log files into one file for processing
  - The number of logs to combine is a command line argument
  - If the webhost rotates the logs each day this sets the number of days to process
  - The same script can be used to generate different report time frames
- Generates the report (times converted to UTC)
- Uses a custom config file to simplify the options passed to GoAccess
- Uploads the report back to the webhost via rsync

