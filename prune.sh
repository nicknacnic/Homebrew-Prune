#!/bin/bash

# Default date to compare with (Jan 1, 2022)
default_date="20220101"
compare_date=$(date -j -f "%Y%m%d" "$default_date" +"%s")
test_mode=0
prune_count=0

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

# Function to parse and compare dates
parse_and_compare_date() {
    local last_access_str=$1
    local last_access_date

    # Determine if the date string is from the current year or a previous year
    if [[ "$last_access_str" =~ [0-9]{2}:[0-9]{2} ]]; then
        # Current year: Format "Mon DD HH:MM"
        last_access_date=$(date -j -f "%b %d %H:%M %Y" "$last_access_str $(date +%Y)" +"%s")
    else
        # Previous year: Format "Mon DD YYYY"
        last_access_date=$(date -j -f "%b %d %Y" "$last_access_str" +"%s")
    fi

    if [ "$last_access_date" -lt "$compare_date" ]; then
        return 0 # Date is before the specified date
    else
        return 1 # Date is on or after the specified date
    fi
}

# Function to check last access time and (un)install if older than specified date
check_and_uninstall() {
    local file_path=$1
    local package_name=$2
    if [ -f "$file_path" ]; then
        # Get last access time of the file
        local last_access_str=$(ls -lu "$file_path" | awk '{print $6, $7, $8}')

        if parse_and_compare_date "$last_access_str"; then
            ((prune_count++))
            if [ "$test_mode" -eq 1 ]; then
                echo "$package_name would be removed (last accessed on $last_access_str)."
            else
                echo "$package_name last accessed on $last_access_str, uninstalling..."
                brew uninstall "$package_name"
                echo "$package_name successfully removed."
            fi
        fi
    fi
}

# Check if no options were provided
if [ $OPTIND -eq 1 ]; then
    print_help
    exit 1
fi

# Main logic
for package in $(brew list); do
    executable_path="/usr/local/bin/$package"
    lib_path="/usr/local/lib/lib$package.dylib"
    if [ -f "$executable_path" ]; then
        check_and_uninstall "$executable_path" "$package"
    elif [ -f "$lib_path" ]; then
        check_and_uninstall "$lib_path" "$package"
    fi
done

# Final output
if [ "$prune_count" -eq 0 ]; then
    echo "No packages found that meet the criteria for pruning."
else
    echo "$prune_count packages would be pruned."
fi
