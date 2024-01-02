# Homebrew-Prune
A utility that identifies installed home-brew formulae, when they were last accessed, and removes them. 

## Homebrew Prune (prune.sh)

### Overview:
This script is designed to help clean up your macOS system by uninstalling Homebrew packages that haven't been used for a significant amount of time. 

### How It Works:
The script operates in several steps:

1. Date Comparison Setup: It sets up a comparison date against which the last access dates of the packages will be compared.

2. Iterating Over Homebrew Packages: The script lists all packages installed via Homebrew and processes each one individually.

3. Determining File Paths: For each package, the script checks for the presence of its main executable or library file in standard Homebrew installation paths (/usr/local/bin for executables and /usr/local/lib for libraries).

5. Last Access Time Retrieval: If the file is found, the script retrieves its last access time using the ls -lu command.

6. Date Parsing and Comparison: The script then parses this last access date. It handles different date formats depending on whether the date is from the current year or a previous year. The parsed date is compared against the set comparison date.

7. Conditional Uninstallation: If a package's last access date is before the comparison date, the script uninstalls the package using brew uninstall.

8. Logging: All actions, including checks, uninstallations, and any errors (like missing files), are logged to an output file (brew_package_usage.txt) for review.

### Usage:
To use this script:

Ensure you have Homebrew installed and that it's up to date.
Copy the script ```git clone https://github.com/nicknacnic/Homebrew-Prune```
Make the script executable: ```chmod +x prune.sh```
Run the script with a -d date flag in YYYYMMDD format: ```./prune.sh -d YYYYMMDD```
Use the ```-t``` for a dry-run testing mode.
Review the brew_package_usage.txt file to see which packages were uninstalled or kept.

### Important Notes:

Backup: Before running this script, ensure you have a backup of your system or at least a list of installed packages. The script will uninstall software based on the last access date, which might sometimes lead to the removal of packages still needed.

Date Formats: The script assumes specific date formats for the ls -lu output. If your system uses a different format, the script might need adjustments.

Manual Review Recommended: It's advisable to manually review the list of packages to be uninstalled before running the script, especially if you have critical Homebrew packages installed.

