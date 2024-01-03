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

# Check if no options were provided
if [ $OPTIND -eq 1 ]; then
    print_help
    exit 1
fi

# Debugging
echo "Debug: compare_date=$compare_date, test_mode=$test_mode"

# Main logic
echo "Starting main logic"
for package in $(brew list); do
    echo "Processing package: $package"

    # Find the installation path of the package
    install_path=$(brew --prefix $package)
    echo "Package $package is installed at: $install_path"

    # Find the main executable of the package (if it exists in PATH)
    executable_path=$(which $package)
    if [ -n "$executable_path" ]; then
        echo "Executable for $package found at: $executable_path"
    else
        echo "No executable found in PATH for $package"
        continue # Skip to the next package if no executable is found
    fi

    # Get last access time of the executable
    last_access_str=$(stat -f "%Sm" -t "%b %d %Y" "$executable_path")
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
done

# Final output
if [ "$prune_count" -eq 0 ]; then
    echo "No packages found that meet the criteria for pruning."
else
    echo "$prune_count packages would be pruned."
fi