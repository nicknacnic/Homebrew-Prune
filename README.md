# homebrew-prune 🍺
A tool that identifies installed homebrew formulae, when they were last accessed, and removes them based off set date of expiry. 

## prune

> [!NOTE]
> ```brew-autoremove``` removes orphaned dependencies, ```brew cleanup``` removes outdated formulae and clears old downloads/logs/cache. These are definitely un-needed, but what about 'actively updated' not orphaned packages you don't use anymore? Enter prune.

## Usage

### Installation:
Tap the formulae.
```brew tap nicknacnic/prune```

Install the formulae.
```brew install prune```

Run the formulae.
```prune -h```

## Example
```prune -d 20210101``` will find all items prior to 1 Jan 2021 and prune them. 

> [!TIP]
> Use -t for test / dry-run purposes. ```prune -d 20210101 -t```

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

### Notes:
> [!IMPORTANT]
> Backup: Before running this script, ensure you have a backup of your system or at least a list of installed packages. The script will uninstall software based on the last access date, which might sometimes lead to the removal of packages still needed.

> [!WARNING]
> Date Formats: The script assumes specific date formats for the ls -lu output. If your system uses a different format, the script might need adjustments.

> [!CAUTION]
> Manual Review Recommended: It's advisable to manually review the list of packages to be uninstalled before running the script, especially if you have critical Homebrew packages installed.

## To Do
- [ ] Add casks to logic 
- [ ] Use built-in brew commands to locate non-default-location packages
- [ ] Schedule function (spring cleaning)
- [ ] brew pin catch
