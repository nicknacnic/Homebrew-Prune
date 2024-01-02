#!/bin/bash

# Variables
test_mode=0
verbose_mode=0
process_casks=0
process_packages=0
package_prune_count=0
cask_prune_count=0
total_size_kb=0
DAYS_THRESHOLD=730
current_datetime=$(date)
uninstalled_list="uninstalled_packages.txt"

# Logging function
log_message() {
    echo "$1" >> brew_package_usage.txt
    if [ "$verbose_mode" -eq 1 ]; then
        echo "$1"
    fi
}

# Function to convert size in KB to human-readable format
convert_size() {
    local size_kb=$1
    local size_human=""
    
    if [ "$size_kb" -ge 1048576 ]; then
        size_human=$(awk "BEGIN {printf \"%.2f GB\", $size_kb/1048576}")
    elif [ "$size_kb" -ge 1024 ]; then
        size_human=$(awk "BEGIN {printf \"%.2f MB\", $size_kb/1024}")
    else
        size_human="${size_kb} KB"
    fi

    echo "$size_human"
}

# Function to calculate the date two years prior
calculate_default_date() {
    # Get the current date in YYYY-MM-DD format
    local current_date=$(date +%Y-%m-%d)

    # Extract year, month, and day
    local year=$(echo $current_date | cut -d '-' -f 1)
    local month=$(echo $current_date | cut -d '-' -f 2)
    local day=$(echo $current_date | cut -d '-' -f 3)

    # Subtract two years from the current year
    local year_two_years_ago=$((year - 2))

    # Return the date in YYYYMMDD format
    echo "${year_two_years_ago}${month}${day}"
}

# Calculate the default date (two years prior to the current date)
default_date=$(calculate_default_date)

# Initially set compare_date to default_date
compare_date=$default_date
prune_count=0

# Help menu
print_help() {
    echo "Usage: $0 [-a] [-c] [-d date] [-h] [-p] [-t]"
    echo ""
    echo "  -a        Prune all (both packages and casks)."
    echo "  -c        Prune only casks."
    echo "  -d date   Specify a date (format YYYYMMDD) to prune packages not accessed since that date."
    echo "  -g        Generate a test case cask and package to be pruned."
    echo "  -h        Display the help menu."
    echo "  -p        Prune only packages."
    echo "  -r        Reinstall pruned packages and casks from uninstalled_packages.txt (requires pruning first)."
    echo "            If used with -t, displays what would be reinstalled."
    echo "  -t        Test mode. Display prune targets without deleting them."
    echo "  -v        Verbose mode."    
}

# Function to get the last opened date of an application using find
get_last_opened_date() {
    local app_path=$1
    local last_opened_str

    # Check if the app path is valid
    if [ ! -d "$app_path" ]; then
        log_message "Application path for $app_path does not exist."
        echo "0"  # Return 0 if the path is not valid
        return
    fi

    # Get the last opened date using find
    last_opened_str=$(find "$app_path" -type f -exec stat -f "%Sm" -t "%Y-%m-%d" {} + 2>/dev/null)
    if [ -n "$last_opened_str" ]; then
        # Find the most recent last opened date among files
        last_opened_date=$(echo "$last_opened_str" | sort -r | head -n 1)
        echo "$last_opened_date"
    else
        log_message "No valid last opened date available for $app_path."
        echo "0"  # Return 0 if no valid date is found
    fi
}

# Get the list of pinned packages
pinned_packages=$(brew list --pinned)

# Function to check if a package is pinned
is_pinned() {
    local package=$1
    if [[ $pinned_packages == *"$package"* ]]; then
        return 0 # 0 means true in shell script
    else
        return 1 # 1 means false
    fi
}

# Function to calculate the date in seconds since the epoch for the compare_date
calculate_compare_date_epoch() {
    compare_date_epoch=$(date -j -f "%Y%m%d" "$compare_date" +"%s")
}

# Process packages
process_packages() {
    # Calculate the compare_date_epoch
    calculate_compare_date_epoch

    log_message "Starting main logic for packages"
    for package in $(brew list --formula); do
        log_message "Processing package: $package"
        if is_pinned "$package"; then
            log_message "Package $package is pinned and will not be pruned."
            continue
        fi

        # Find the installation path of the package
        install_path=$(brew --prefix $package)
        log_message "Package $package is installed at: $install_path"

        # Find the main executable of the package (if it exists in PATH)
        executable_path=$(which $package)
        if [ -n "$executable_path" ]; then
            log_message "Executable for $package found at: $executable_path"
            # Get last access time of the executable
            last_access_str=$(stat -f "%Sm" -t "%b %d %Y" "$executable_path")
            last_access_date=$(date -j -f "%b %d %Y" "$last_access_str" +"%s")
            log_message "Last access date for $package: $last_access_str"

            # Calculate the size of the installation path using 'du' command
            local install_size_kb=$(du -sk "$install_path" | cut -f1)
            log_message "Size calculated for $package installation path: $install_size_kb KB"

            # Calculate the size of the executable using 'du' command
            local exec_size_kb=$(du -sk "$executable_path" | cut -f1)
            log_message "Size calculated for $package executable: $exec_size_kb KB"

            # Choose the non-zero size for incrementing
            if [ "$install_size_kb" -gt 0 ]; then
                size_kb=$((size_kb + install_size_kb))
            elif [ "$exec_size_kb" -gt 0 ]; then
                size_kb=$((size_kb + exec_size_kb))
            fi

            if [ -n "$last_access_date" ] && [ "$last_access_date" -lt "$compare_date_epoch" ]; then
                log_message "Calculating size for $package..."
                total_size_kb=$((total_size_kb + size_kb))
                
                if [ "$test_mode" -eq 1 ]; then
                    log_message "$package would be removed (last accessed on $last_access_str)."
                    ((package_prune_count++))
                else
                    log_message "$package last accessed on $last_access_str, uninstalling..."
                    log_message "$package" >> "$uninstalled_list"
                    brew uninstall "$package"
                    log_message "$package successfully removed."
                fi
            else
                log_message "Package $package has been used after $compare_date or has no valid last access date."
            fi
        else
            log_message "No executable found in PATH for $package, skipping..."
        fi
    done
}

# Function to find the application path for a given cask
find_app_path() {
    local cask_name=$1
    local app_name
    local found_app=""

    # Extract the application name from Homebrew cask metadata
    app_name=$(brew info --json=v2 --cask "$cask_name" | jq -r '.casks[0].artifacts[] | select(has("app")) | .app[0]')

    # Construct the application path
    if [ -n "$app_name" ]; then
        found_app="/Applications/${app_name}"
    fi

    # Return the found path or an empty string if no match was found
    if [ -n "$found_app" ] && [ -d "$found_app" ]; then
        echo "$found_app"
    else
        echo ""
    fi
}

# Process casks
process_casks() {
    log_message "Starting main logic for casks"
    for cask in $(brew list --cask); do
        log_message "Processing cask: $cask"
        if is_pinned "$cask"; then
            log_message "Cask $cask is pinned and will not be pruned."
            continue
        fi

        # Find the application path using the find_app_path function
        app_path=$(find_app_path "$cask")
        if [ -n "$app_path" ]; then
            # Get the last used date using the get_last_opened_date function
            last_used_date=$(get_last_opened_date "$app_path")

            # Check if last_used_date is a valid date
            if [[ "$last_used_date" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
                # Convert compare_date to YYYY-MM-DD format for comparison
                compare_date_hyphenated=$(date -j -f "%Y%m%d" "$compare_date" +"%Y-%m-%d")

                if [ "$last_used_date" \< "$compare_date_hyphenated" ]; then
                    log_message "Calculating size for $cask..."
                    # Calculate cask size by checking the application bundle size
                    local size_kb=$(du -sk "$app_path" | cut -f1)
                    log_message "Size calculated for $cask: $size_kb KB"
                    total_size_cask_kb=$((total_size_cask_kb + size_kb))
                    if [ "$test_mode" -eq 1 ]; then
                        log_message "$cask would be removed (last used on $last_used_date)."
                        ((cask_prune_count++))
                    else
                        log_message "$cask last used on $last_used_date, uninstalling..."
                        log_message "$cask" >> "$uninstalled_list"
                        brew uninstall --cask "$cask"
                        log_message "$cask successfully removed."
                        ((cask_prune_count++))
                    fi
                else
                    log_message "No action taken for $cask (last used on $last_used_date)."
                fi
            else
                log_message "No valid last used date available for $cask."
            fi
        else
            log_message "Application for cask $cask not found in /Applications."
        fi
    done
}

# Run processing functions based on flags
[ "$process_packages" -eq 1 ] && process_packages
[ "$process_casks" -eq 1 ] && process_casks

# Parse options
while getopts "d:acpthrvg" opt; do
    case $opt in
        a)
            process_casks=1
            process_packages=1
            ;;
        c)
            process_casks=1
            ;;
        d)
            # Update compare_date based on the user-provided date
            compare_date=$(date -j -f "%Y%m%d" "$OPTARG" +"%Y%m%d")
            ;;
        g)
            echo "Installing test package and cask."
            log_message "Installing test cask 'penc'"
            brew install --cask penc
            log_message "Modifying last open date to 201501010000"
            touch -t 201501010000 /Applications/Penc.app
            log_message "Installing test package 'briss'"
            brew install countdown
            log_message "Modifying last open date to 201501010000"
            touch -t 201501010000 /usr/local/bin/countdown
            echo "Install successful, run prune with -t to find penc and briss."    
            ;;
        h)
            print_help
            exit 0
            ;;
        p)
            process_packages=1
            ;;
        r)
            if [ "$test_mode" -eq 1 ]; then
                echo "Test mode is active. The following packages/casks would be reinstalled:"
                cat "$uninstalled_list" || echo "No packages/casks to reinstall."
            elif [ -f "$uninstalled_list" ]; then
                while read -r line; do
                    brew install "$line"
                    log_message "Reinstalled $line"
                done < "$uninstalled_list"
            else
                log_message "No uninstalled packages to reinstall."
            fi
            exit 0
            ;;
        t)
            test_mode=1
            ;;
        v)
            verbose_mode=1
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            print_help
            exit 1
            ;;
    esac
done

# Check if no options were provided
if [ $OPTIND -eq 1 ]; then
    print_help
    exit 1
fi

# Debugging
echo "Debug: compare_date=$compare_date, test_mode=$test_mode"

# Run processing functions based on flags
[ "$process_packages" -eq 1 ] && process_packages
[ "$process_casks" -eq 1 ] && process_casks
# Main logic
echo "Starting main logic"
for package in $(brew list); do
    echo "Processing package: $package"

    # Check for executable or library
    executable_path="/usr/local/bin/$package"
    lib_path="/usr/local/lib/lib$package.dylib"
    file_path=""

    if [ -f "$executable_path" ]; then
        file_path="$executable_path"
    elif [ -f "$lib_path" ]; then
        file_path="$lib_path"
    fi

    if [ -n "$file_path" ]; then
        # Get last access time of the file
        last_access_str=$(stat -f "%Sm" -t "%b %d %Y" "$file_path")
        last_access_date=$(date -j -f "%b %d %Y" "$last_access_str" +"%s")

        echo "Last access date for $package: $last_access_str"

        if [ "$last_access_date" -lt "$compare_date" ]; then
            if [ "$test_mode" -eq 1 ]; then
                echo "$package would be removed (last accessed on $last_access_str)."
                ((prune_count++))
            else
                echo "$package last accessed on $last_access_str, uninstalling..."
                brew uninstall "$package"
                echo "$package successfully removed."
            fi
        fi
    else
        echo "No executable or library found for $package."
    fi
done

# Final output
if [ "$package_prune_count" -eq 0 ] && [ "$cask_prune_count" -eq 0 ]; then
    echo ""
    echo "No packages or casks found that meet the criteria for pruning."
    echo ""
else
    total_size_kb_total=$((total_size_kb + total_size_cask_kb))
    
    if [ "$package_prune_count" -gt 0 ]; then
        echo ""
        echo "$package_prune_count packages would be pruned."
        echo ""
    fi

    if [ "$cask_prune_count" -gt 0 ]; then
        echo ""
        echo "$cask_prune_count casks would be pruned."
        echo ""
    fi
    
    echo ""
    echo "Total space that would be freed: $(convert_size $total_size_kb_total)"
    echo ""

    if [ "$package_prune_count" -gt 0 ]; then
        echo ""
        echo "Total space freed from packages: $(convert_size $total_size_kb)"
        echo ""
    fi

    if [ "$cask_prune_count" -gt 0 ]; then
        echo ""
        echo "Total space freed from casks: $(convert_size $total_size_cask_kb)"
        echo ""
    fi
fi
