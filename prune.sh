#!/bin/bash

# Default date to compare with (Jan 1, 2022)
default_date="20220101"
compare_date=$(date -j -f "%Y%m%d" "$default_date" +"%s")
test_mode=0

# Help menu
print_help() {
    echo "Usage: $0 [-d date] [-t]"
    echo "  -d date   Specify a date (format YYYYMMDD) to prune packages not accessed since that date."
    echo "  -t        Test mode. Display packages that would be deleted without actually deleting them."
    echo "  -h        Display this help and exit."
}

# Parse options
while getopts "d:th" opt; do
    case $opt in
        d)
            compare_date=$(date -j -f "%Y%m%d" "$OPTARG" +"%s")
            ;;
        t)
            test_mode=1
            ;;
        h)
            print_help
            exit 0
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            print_help
            exit 1
            ;;
    esac
done

# Rest of the script...
# [The script logic remains the same, except for the uninstallation part]

# Function to check last access time and (un)install if older than specified date
check_and_uninstall() {
    # [Function body remains the same]

    if [ "$last_access_date" -lt "$compare_date" ]; then
        if [ "$test_mode" -eq 1 ]; then
            echo "$package_name would be removed (last accessed on $last_access_str)." | tee -a "$output_file"
        else
            echo "$package_name last accessed on $last_access_str, uninstalling..." | tee -a "$output_file"
            brew uninstall "$package_name"
            echo "$package_name successfully removed." | tee -a "$output_file"
        fi
    else
        echo "$package_name last accessed on $last_access_str, keeping it." >> "$output_file"
    fi
}

# [Rest of the script logic]

# Check if no options were provided
if [ $OPTIND -eq 1 ]; then
    print_help
    exit 1
fi

# [Rest of the script logic]
