#!/bin/bash

# File to store the output
output_file="brew_package_usage.txt"
# Date to compare with (Jan 1, 2022)
compare_date=$(date -j -f "%Y%m%d" "20220101" +"%s")

# Clear the file if it already exists
> "$output_file"

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
        return 0 # Date is before 2022
    else
        return 1 # Date is in 2022 or later
    fi
}

# Function to check last access time and uninstall if older than 2022
check_and_uninstall() {
    local file_path=$1
    local package_name=$2
    if [ -f "$file_path" ]; then
        # Get last access time of the file
        local last_access_str=$(ls -lu "$file_path" | awk '{print $6, $7, $8}')

        if parse_and_compare_date "$last_access_str"; then
            echo "$package_name last accessed on $last_access_str, uninstalling..." | tee -a "$output_file"
            brew uninstall "$package_name"
            echo "$package_name successfully removed." | tee -a "$output_file"
        else
            echo "$package_name last accessed on $last_access_str, keeping it." >> "$output_file"
        fi
    else
        echo "$package_name executable/library not found in expected locations" >> "$output_file"
    fi
}

# List all installed Homebrew packages
for package in $(brew list); do
    # Check in /usr/local/bin
    executable_path="/usr/local/bin/$package"
    if [ -f "$executable_path" ]; then
        check_and_uninstall "$executable_path" "$package"
    else
        # Check in /usr/local/lib
        lib_path="/usr/local/lib/lib$package.dylib"
        check_and_uninstall "$lib_path" "$package"
    fi
done

echo "Script completed. Check $output_file for details."
