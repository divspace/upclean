#!/usr/bin/env bash

VERSION=2.0

# ------------------------------------------------------------------------------
# UpClean v2.0 — An update and cleanup script for macOS.
# Cloned from https://github.com/divspace/upclean
# ------------------------------------------------------------------------------

soap=🧼

bold="\033[1m"
cyan="\033[0;36m"
green="\033[0;32m"
red="\033[41m"
yellow="\033[33m"
reset="\033[0m"

configFile=~/.upcleanrc
baseDir=$(dirname "$0")

shouldClean=true
shouldCleanDocker=true
shouldClearMemory=true
shouldFlushDns=true
shouldUpdate=true
shouldUpdateComposer=true
shouldUpdateComposerPackages=true
shouldUpdateHomebrew=true
shouldUpdateMas=true
shouldUpdateNPM=true
shouldUpdatePIP=true
shouldUpdateMicrosoft=true
shouldUpdateConda=true
shouldUpdateOhMyZsh=true

outputOfShell=$baseDir/log.txt
# outputOfShell=/dev/null
# ------------------------------------------------------------------------------

function usage() {
    printf "UpClean %b%s%b %s %bupclean.app%b\n\n" "$green" "$VERSION" "$reset" "$soap" "$cyan" "$reset"
    printf "An update and cleanup script for macOS.\n\n"
    printf "%bUsage:%b\n" "$yellow" "$reset"
    printf -- "  upclean [options]\n\n"
    printf "%bOptions:%b\n" "$yellow" "$reset"
    printf -- "%b      --skip-clean               %bSkip cleaning\n" "$green" "$reset"
    printf -- "%b      --skip-composer            %bSkip updating Composer\n" "$green" "$reset"
    printf -- "%b      --skip-composer-packages   %bSkip updating Composer packages\n" "$green" "$reset"
    printf -- "%b      --skip-dns                 %bSkip flushing DNS cache\n" "$green" "$reset"
    printf -- "%b      --skip-docker              %bSkip cleaning Docker\n" "$green" "$reset"
    printf -- "%b      --skip-homebrew            %bSkip updating Homebrew\n" "$green" "$reset"
    printf -- "%b      --skip-mas                 %bSkip updating Mac App Store applications\n" "$green" "$reset"
    printf -- "%b      --skip-memory              %bSkip clearing inactive memory\n" "$green" "$reset"
    printf -- "%b      --skip-update              %bSkip updating\n" "$green" "$reset"
    printf -- "%b  -h, --help                     %bDisplay this help message\n" "$green" "$reset"

    exit 0
}

function info() {
    local action
    local message

    case $1 in
        "clean") action=Cleaning; shift; message=$1 ;;
        "update") action=Updating; shift; message=$1 ;;
        "done") unset action message ;;
        *) action=$1; shift; message=$1 ;;
    esac

    shift

    if [[ -n $action ]] && [[ -n $message ]]; then
        message=$(printf "%s %b%s%b..." "$action" "$bold" "$message" "$reset")

        startSpinner "$message"
    else
        stopSpinner $?
    fi
}

function keepSudoAlive() {
    sudo -v

    while true; do
        sleep 60
        sudo -n true
        kill -0 "$$" || exit
    done >>$outputOfShell 2>&1 # 2>/dev/null &
}

function deleteLog(){
    if [ -f "$outputOfShell" ] ; then
        rm "$outputOfShell"
    fi
}
# ------------------------------------------------------------------------------
# Configuration Functions...
# ------------------------------------------------------------------------------

function hasConfigFile() {
    [[ -s $configFile ]] && return

    false
}

function loadConfigFile() {
    local configOptions

    IFS=$'\r\n' GLOBIGNORE="*" command eval "configOptions=($(cat $configFile))"

    checkOptions "${configOptions[@]}"
}

# ------------------------------------------------------------------------------
# Spinner Functions...
# ------------------------------------------------------------------------------

function spinner() {
    case $1 in
        "start")
            (( column=60 - ${#2} ))
            printf "%s%${column}s" "$2"

            i=1
            delay=0.13
            frames="-\|/"

            while true; do
                printf "\b%s" ${frames:i++%${#frames}:1}
                sleep "$delay"
            done
            ;;
        "stop")
            [[ -z $3 ]] && fail "Spinner is not running!"

            kill "$3" >>$outputOfShell 2>&1

            if [[ $2 -eq 1 ]]; then
                printf "\b%b✓%b\n" "${green}" "${reset}"
            else
                printf "\b%b𐊴%b\n" "${red}" "${reset}"
            fi
            ;;
    esac
}

function startSpinner() {
    spinner "start" "$1" &
    spinnerProcessId=$!
    disown
}

function stopSpinner() {
    spinner "stop" "$1" "$spinnerProcessId"
    unset spinnerProcessId
}

# ------------------------------------------------------------------------------
# Disk Space Functions...
# ------------------------------------------------------------------------------

function getAvailableDiskSpace() {
    df -k / | tail -n1 | awk '{ print $4 }'
}

function calculateDiskSpaceSavings() {
    if [[ -n $availableDiskSpaceBefore ]] && [[ -n $availableDiskSpaceAfter ]]; then
        local diskSpaceDifference

        (( diskSpaceDifference=availableDiskSpaceAfter - availableDiskSpaceBefore ))

        if [[ $diskSpaceDifference -gt 0 ]] && [[ $diskSpaceDifference -lt 10000 ]]; then
            unit=MB
            diskSpaceSaved=$(echo "$diskSpaceDifference" | awk '{ print $1=$1/1024 }')
        fi

        if [[ $diskSpaceDifference -ge 10000 ]]; then
            unit=GB
            diskSpaceSaved=$(echo "$diskSpaceDifference" | awk '{ print $1=$1/1024^2 }')
        fi
    fi
}

function showDiskSpaceSavings() {
    [[ -n $diskSpaceSaved ]] && LC_NUMERIC=en_US printf "\n%b%s Cleaned up %b%'.f %s%b of disk space!%b\n" \
        "$bold" "$soap" "$cyan$bold" "$diskSpaceSaved" "$unit" "$reset$bold" "$reset"
}

# ------------------------------------------------------------------------------
# Cleaning Functions...
# ------------------------------------------------------------------------------

function cleanAdobe() {
    if [[ -d /Library/Logs/Adobe/ ]] || [[ -d ~/Library/Application\ Support/Adobe/Common/Media\ Cache\ Files ]]; then
        info "clean" "Adobe"
        rm -rf /Library/Logs/Adobe/* >>$outputOfShell 2>&1
        rm -rf ~/Library/Application\ Support/Adobe/Common/Media\ Cache\ Files/* >>$outputOfShell 2>&1
        info "done"
    fi
}

function cleanComposer() {
    if type "composer" >>$outputOfShell 2>&1; then
        info "clean" "Composer"
        composer clear-cache >>$outputOfShell 2>&1
        info "done"
    fi
}

function cleanDocker() {
    if type "docker" >>$outputOfShell 2>&1; then
        info "clean" "Docker"
        docker system prune --all --force >>$outputOfShell 2>&1
        info "done"
    fi
}

function cleanDropbox() {
    if [[ -d ~/Dropbox/.dropbox.cache ]]; then
        info "clean" "Dropbox"
        rm -rf ~/Dropbox/.dropbox.cache/* >>$outputOfShell 2>&1
        info "done"
    fi
}

function cleanGoogleChrome() {
    if [[ -d ~/Library/Application\ Support/Google/Chrome/Default/Application\ Cache ]]; then
        info "clean" "Google Chrome"
        rm -rf ~/Library/Application\ Support/Google/Chrome/Default/Application\ Cache/* >>$outputOfShell 2>&1
        info "done"
    fi
}

function cleanGoogleDrive() {
    if [[ -d ~/Library/Application\ Support/Google/DriveFS ]]; then
        info "clean" "Google Drive"
        killall "Google Drive File Stream" >>$outputOfShell 2>&1
        rm -rf ~/Library/Application\ Support/Google/DriveFS/[0-9a-zA-Z]*/content_cache >>$outputOfShell 2>&1
        info "done"
    fi
}

function cleanGradle() {
    if [[ -d ~/.gradle/caches ]]; then
        info "clean" "Gradle"
        rm -rf ~/.gradle/caches/* >>$outputOfShell 2>&1
        info "done"
    fi
}

function cleanHomebrew() {
    if type "brew" >>$outputOfShell 2>&1; then
        info "clean" "Homebrew"
        brew cleanup -s >>$outputOfShell 2>&1
        rm -rf "$(brew --cache)" >>$outputOfShell 2>&1
        brew autoremove >>$outputOfShell 2>&1
        brew tap --repair >>$outputOfShell 2>&1
        brew doctor >>$outputOfShell 2>&1
        brew missing >>$outputOfShell 2>&1
        info "done"
    fi
}

function cleanNpm() {
    if type "npm" >>$outputOfShell 2>&1; then
        info "clean" "npm"
        # npm cache clean --force >>$outputOfShell 2>&1
        npm cache verify >>$outputOfShell 2>&1
        npm doctor >>$outputOfShell 2>&1
        info "done"
    fi
}

function cleanRubyGems() {
    if type "gem" >>$outputOfShell 2>&1; then
        info "clean" "Ruby Gems"
        gem cleanup >>$outputOfShell 2>&1
        info "done"
    fi
}

function cleanSystem() {
    info "clean" "system"
    rm -rf /Library/Caches/* >>$outputOfShell 2>&1
    rm -rf /Library/Logs/DiagnosticReports/* >>$outputOfShell 2>&1
    rm -rf /System/Library/Caches/* >>$outputOfShell 2>&1
    rm -rf /private/var/log/asl/*.asl >>$outputOfShell 2>&1
    rm -rf ~/Library/Caches/* >>$outputOfShell 2>&1
    rm -rf ~/Library/Containers/com.apple.mail/Data/Library/Logs/Mail/* >>$outputOfShell 2>&1
    rm -rf ~/Library/Logs/CoreSimulator/* >>$outputOfShell 2>&1
    info "done"
}

function cleanXcode() {
    if [[ -d ~/Library/Developer/Xcode/Archives ]] || [[ -d ~/Library/Developer/Xcode/DerivedData ]]; then
        info "clean" "Xcode"
        rm -rf ~/Library/Developer/Xcode/Archives/* >>$outputOfShell 2>&1
        rm -rf ~/Library/Developer/Xcode/DerivedData/* >>$outputOfShell 2>&1
        rm -rf ~/Library/Developer/Xcode/iOS Device Logs/* >>$outputOfShell 2>&1
        info "done"
    fi
}

function cleanYarn() {
    if type "yarn" >>$outputOfShell 2>&1; then
        info "clean" "Yarn"
        yarn cache clean --force >>$outputOfShell 2>&1
        info "done"
    fi
}

function cleanConda() {
    if type "conda" >>$outputOfShell 2>&1; then
        info "clean" "Conda"
        conda clean --all --yes >>$outputOfShell 2>&1
        info "done"
    fi
}

# ------------------------------------------------------------------------------
# Updating Functions...
# ------------------------------------------------------------------------------

function updateComposer() {
    if type "composer" >>$outputOfShell 2>&1; then
        info "update" "Composer"
        composer self-update --clean-backups >>$outputOfShell 2>&1
        info "done"
    fi
}

function updateComposerPackages() {
    if type "composer" >>$outputOfShell 2>&1; then
        info "update" "Composer packages"
        composer global update >>$outputOfShell 2>&1
        info "done"
    fi
}

function updateHomebrew() {
    if type "brew" >>$outputOfShell 2>&1; then
        info "update" "Homebrew"
        brew update-reset >>$outputOfShell 2>&1
        brew outdated >>$outputOfShell 2>&1
        # brew update --force >>$outputOfShell 2>&1
        brew upgrade >>$outputOfShell 2>&1
        brew upgrade --cask >>$outputOfShell 2>&1
        info "done"
    fi
}

function updateMacAppStore() {
    if type "mas" >>$outputOfShell 2>&1 && [[ -n $(mas outdated) ]]; then
        info "update" "Mac & App Store"
        softwareupdate -i -a >>$outputOfShell 2>&1
        mas outdated >>$outputOfShell 2>&1
        mas upgrade >>$outputOfShell 2>&1
        info "done"
    fi
}

function updateNPM() {
    if type "npm" >>$outputOfShell 2>&1; then
        info "update" "NPM"
        # npm cache clear --force >>$outputOfShell 2>&1
        npm i -g npm >>$outputOfShell 2>&1
        npm install --no-shrinkwrap --update-binary >>$outputOfShell 2>&1
        # npm update -g >>$outputOfShell 2>&1
        info "done"
    fi
}

function updatePIP() {
    if type "pip" >>$outputOfShell 2>&1; then
        info "update" "PIP"
        python3 -c "import pkg_resources; from subprocess import call; packages = [dist.project_name for dist in pkg_resources.working_set]; call('pip install --upgrade ' + ' '.join(packages), shell=True)" >>$outputOfShell 2>&1
        pipupgrade --ignore-error --force --yes --jobs 12  >>$outputOfShell 2>&1
        info "done"
    fi
}

function updateConda() {
    if type "conda" >>$outputOfShell 2>&1; then
        info "update" "Conda"
        # conda activate base
        conda update conda --yes >>$outputOfShell 2>&1
        conda clean --all --yes >>$outputOfShell 2>&1
        conda update -n base --all --yes >>$outputOfShell 2>&1
        info "done"
    fi
}

function updateOhMyZsh(){
    if type "omz" >>$outputOfShell 2>&1; then
        info "update" "OhMyZsh"
        omz update >>$outputOfShell 2>&1
        info "done"
    fi
}

function updateMicrosoft() {
    microsoftUpdaterPath=/Library/Application\ Support/Microsoft/MAU2.0/Microsoft\ AutoUpdate.app/Contents/MacOS/msupdate

    if [ -f "$microsoftUpdaterPath" ] ; then
        info "update" "Microsoft"
        /Library/Application\ Support/Microsoft/MAU2.0/Microsoft\ AutoUpdate.app/Contents/MacOS/msupdate --install >>$outputOfShell 2>&1
        info "done"
    fi
}

# ------------------------------------------------------------------------------
# Other Functions...
# ------------------------------------------------------------------------------

function clearMemory() {
    info "Clearing" "memory"
    sudo purge
    info "done"
}

function emptyTrash() {
    info "Emptying" "trash"
    rm -rf /Volumes/*/.Trashes/* >>$outputOfShell 2>&1
    rm -rf ~/.Trash/* >>$outputOfShell 2>&1
    info "done"
}

function flushDns() {
    info "Flushing" "DNS"
    sudo dscacheutil -flushcache
    sudo killall -HUP mDNSResponder
    info "done"
}

# ------------------------------------------------------------------------------
# Initializers...
# ------------------------------------------------------------------------------

function initializeCleanup() {
    availableDiskSpaceBefore=$(getAvailableDiskSpace)

    cleanAdobe
    cleanComposer
    $shouldCleanDocker && cleanDocker
    cleanDropbox
    cleanGoogleChrome
    cleanGoogleDrive
    cleanGradle
    cleanHomebrew
    cleanNpm
    cleanRubyGems
    cleanSystem
    cleanXcode
    cleanYarn
    cleanConda

    emptyTrash

    availableDiskSpaceAfter=$(getAvailableDiskSpace)

    calculateDiskSpaceSavings
}

function initializeUpdate() {
    $shouldUpdateComposer && updateComposer
    $shouldUpdateComposerPackages && updateComposerPackages
    $shouldUpdateHomebrew && updateHomebrew
    $shouldUpdateNPM && updateNPM
    $shouldUpdatePIP && updatePIP
    $shouldUpdateConda && updateConda
    $shouldUpdateOhMyZsh && updateOhMyZsh
}

function initializeMacOsUpdate() {
    $shouldUpdateMas && updateMacAppStore
    # $shouldUpdateMicrosoft && updateMicrosoft
}

# ------------------------------------------------------------------------------
# Options...
# ------------------------------------------------------------------------------

function checkOptions() {
    for option in "$@"; do
        case $option in
            "-h"|"--help") usage ;;
            "--skip-clean") shouldClean=false ;;
            "--skip-composer") shouldUpdateComposer=false ;;
            "--skip-composer-packages") shouldUpdateComposerPackages=false ;;
            "--skip-dns") shouldFlushDns=false ;;
            "--skip-docker") shouldCleanDocker=false ;;
            "--skip-homebrew") shouldUpdateHomebrew=false ;;
            "--skip-mas") shouldUpdateMas=false ;;
            "--skip-memory") shouldClearMemory=false ;;
            "--skip-update") shouldUpdate=false ;;
        esac
    done
}

function handleOptions() {
    deleteLog
    echo "Starting..."
    echo "Click here to view the log ->" $outputOfShell
    echo "------------------------------------------------------------------------------"
    $shouldUpdate && initializeUpdate
    $shouldClean && initializeCleanup

    # Reinitialize the sudo timestamp since Homebrew invalidates it
    $shouldClearMemory || $shouldFlushDns && keepSudoAlive

    $shouldClearMemory && clearMemory
    $shouldFlushDns && flushDns

    $shouldUpdateMas && initializeMacOsUpdate
}

hasConfigFile && loadConfigFile
checkOptions "$@"
handleOptions
showDiskSpaceSavings

exit 0

## Brew Update & Clean
# brew update-reset && echo "->List of outdated apps:" && brew outdated && brew upgrade && echo "->List of outdated casks:" && brew outdated --cask --greedy && brew upgrade --cask && echo "->Cleaning up:" && brew cleanup -s && echo "->Brew Doctor:" && brew doctor -q && brew missing

## Update AppStore Apps
# mas upgrade

## Update all System Softwares
# softwareupdate --install --all --verbose

## Conda Update
# conda update conda --yes && conda clean --all --yes && conda update -n base --all --yes
