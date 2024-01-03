#!/bin/bash

# Calculate the date two years ago
default_date=$(date -v-2y +%Y%m%d)
compare_date=$(date -j -f "%Y%m%d" "$default_date" +"%s")
test_mode=0
process_casks=0
process_packages=0
package_prune_count=0
cask_prune_count=0

# Help menu
print_help() {
    echo "Usage: $0 [-a] [-c] [-d date] [-h] [-p] [-t]"
    echo "  -a        Process all (both packages and casks)."
    echo "  -c        Include Homebrew casks in the pruning process."
    echo "  -d date   Specify a date (format YYYYMMDD) to prune packages not accessed since that date."
    echo "  -h        Display this help and exit."
    echo "  -p        Include Homebrew packages in the pruning process."
    echo "  -t        Test mode. Display packages that would be deleted without actually deleting them."
}

# Process packages
process_packages() {
    echo "Starting main logic for packages"
    for package in $(brew list --formula); do

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
            ((package_prune_count++))
        else
            echo "$package last accessed on $last_access_str, uninstalling..."
            brew uninstall "$package"
            echo "$package successfully removed."
        fi
    fi
done
}

# Function to find the application path for a given cask
find_app_path() {
    local cask_name=$1
    local app_name

    # Try direct match first
    if [ -d "/Applications/${cask_name}.app" ]; then
        echo "/Applications/${cask_name}.app"
        return
    fi

    # Try case-insensitive and partial match using awk
    for app in /Applications/*.app; do
        app_name=$(basename "$app" .app)
        if echo "$app_name" | awk -v cask="$cask_name" 'tolower($0) ~ tolower(cask) {exit}' ; then
            echo "$app"
            return
        fi
    done

    echo ""
}

# Process casks
process_casks() {
    echo "Starting main logic for casks"
    for cask in $(brew list --cask); do
        echo "Processing cask: $cask"

        # Find the application path using the find_app_path function
        app_path=$(find_app_path "$cask")
        if [ -n "$app_path" ]; then
            # Get the last used date using mdls
            last_used_str=$(mdls -name kMDItemLastUsedDate "$app_path" | awk '{print $3}')
            if [[ "$last_used_str" != "(null)" && -n "$last_used_str" ]]; then
                last_used_date=$(date -j -f "%Y-%m-%d" "$last_used_str" +"%s")
                echo "Last used date for $cask: $last_used_str"

                # Compare last used date with compare_date
                if [ "$last_used_date" -lt "$compare_date" ]; then
                    if [ "$test_mode" -eq 1 ]; then
                        echo "$cask would be removed (last used on $last_used_str)."
                        ((cask_prune_count++))
                    else
                        echo "$cask last used on $last_used_str, uninstalling..."
                        brew uninstall --cask "$cask"
                        echo "$cask successfully removed."
                       ((cask_prune_count++))
                    fi
                fi
            else
                echo "No valid last used date available for $cask."
            fi
        else
            echo "Application for cask $cask not found in /Applications."
        fi
    done
}

# Parse options
while getopts "d:acpth" opt; do
    case $opt in
        a)
            process_casks=1
            process_packages=1
            ;;
        c)
            process_casks=1
            ;;
        d)
            compare_date=$(date -j -f "%Y%m%d" "$OPTARG" +"%s")
            ;;
        h)
            print_help
            exit 0
            ;;
        p)
            process_packages=1
            ;;
        t)
            test_mode=1
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
echo "Debug: compare_date=$compare_date, test_mode=$test_mode, process_casks=$process_casks, process_packages=$process_packages"

# Run processing functions based on flags
[ "$process_packages" -eq 1 ] && process_packages
[ "$process_casks" -eq 1 ] && process_casks

# Final output
if [ "$package_prune_count" -eq 0 ] && [ "$cask_prune_count" -eq 0 ]; then
    echo "No packages or casks found that meet the criteria for pruning."
else
    echo "$package_prune_count packages and $cask_prune_count casks would be pruned."
fi
