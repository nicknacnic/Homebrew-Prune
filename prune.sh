#!/bin/bash

# Default date to compare with (Jan 1, 2022)
default_date="20220101"
compare_date=$(date -j -f "%Y%m%d" "$default_date" +"%s")
test_mode=0
include_casks=0
prune_count=0

# Help menu
print_help() {
    echo "Usage: $0 [-d date] [-t] [-c]"
    echo "  -d date   Specify a date (format YYYYMMDD) to prune packages not accessed since that date."
    echo "  -t        Test mode. Display packages that would be deleted without actually deleting them."
    echo "  -c        Include Homebrew casks in the pruning process."
    echo "  -h        Display this help and exit."
}

# Parse options
while getopts "d:tch" opt; do
    case $opt in
        d)
            compare_date=$(date -j -f "%Y%m%d" "$OPTARG" +"%s")
            ;;
        t)
            test_mode=1
            ;;
        c)
            include_casks=1
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
echo "Debug: compare_date=$compare_date, test_mode=$test_mode, include_casks=$include_casks"

# Main logic for formulae
echo "Starting main logic for formulae"
for package in $(brew list --formula); do
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

# Main logic for casks (if -c flag is used)
if [ "$include_casks" -eq 1 ]; then
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
                        ((prune_count++))
                    else
                        echo "$cask last used on $last_used_str, uninstalling..."
                        brew uninstall --cask "$cask"
                        echo "$cask successfully removed."
                        ((prune_count++))
                    fi
                fi
            else
                echo "No valid last used date available for $cask."
            fi
        else
            echo "Application for cask $cask not found in /Applications."
        fi
    done
fi



# Final output
if [ "$prune_count" -eq 0 ]; then
    echo "No packages or casks found that meet the criteria for pruning."
else
    echo "$prune_count packages/casks would be pruned."
fi
