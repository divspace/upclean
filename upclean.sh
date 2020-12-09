#!/usr/bin/env bash

VERSION=1.0.0

# ------------------------------------------------------------------------------
# UpClean v1.0.0 (https://upclean.app) — An update and cleanup script for macOS.
# ------------------------------------------------------------------------------

bold="\033[1m"
cyan="\033[0;36m"
green="\033[0;32m"
yellow="\033[33m"
reset="\033[0m"

shouldClean=true
shouldClearMemory=true
shouldFlushDns=true
shouldUpdate=true
shouldUpdateComposer=true
shouldUpdateComposerPackages=true
shouldUpdateHomebrew=true
shouldUpdateMas=true

# ------------------------------------------------------------------------------

function usage() {
    printf "UpClean %b%s%b 🧼 %bupclean.app%b\n\n" "$green" "$VERSION" "$reset" "$cyan" "$reset"
    printf "An update and cleanup script for macOS.\n\n"
    printf "%bUsage:%b\n" "$yellow" "$reset"
    printf -- "  upclean [options]\n\n"
    printf "%bOptions:%b\n" "$yellow" "$reset"
    printf -- "%b      --skip-clean               %bSkip cleaning\n" "$green" "$reset"
    printf -- "%b      --skip-composer            %bSkip updating Composer\n" "$green" "$reset"
    printf -- "%b      --skip-composer-packages   %bSkip updating Composer packages\n" "$green" "$reset"
    printf -- "%b      --skip-dns                 %bSkip flushing DNS cache\n" "$green" "$reset"
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
        printf "%b%s %b%s%b..." "$yellow" "$action" "$bold" "$message" "$reset"
    else
        printf "%bdone!%b\n" "$green" "$reset"
    fi
}

function keepSudoAlive() {
    sudo -v

    while true; do
        sleep 60
        sudo -n true
        kill -0 "$$" || exit
    done 2>/dev/null &
}

# ------------------------------------------------------------------------------
# Cleaning Functions...
# ------------------------------------------------------------------------------

function cleanAdobe() {
    if [[ -d /Library/Logs/Adobe/ ]] || [[ -d ~/Library/Application\ Support/Adobe/Common/Media\ Cache\ Files ]]; then
        info "clean" "Adobe"
        rm -rf /Library/Logs/Adobe/* &>/dev/null
        rm -rf ~/Library/Application\ Support/Adobe/Common/Media\ Cache\ Files/* &>/dev/null
        info "done"
    fi
}

function cleanComposer() {
    if type "composer" &>/dev/null; then
        info "clean" "Composer"
        composer clear-cache &>/dev/null
        info "done"
    fi
}

function cleanDocker() {
    if type "docker" &>/dev/null; then
        info "clean" "Docker"
        docker system prune --all --force &>/dev/null
        info "done"
    fi
}

function cleanDropbox() {
    if [[ -d ~/Dropbox/.dropbox.cache ]]; then
        info "clean" "Dropbox"
        rm -rf ~/Dropbox/.dropbox.cache/* &>/dev/null
        info "done"
    fi
}

function cleanGoogleChrome() {
    if [[ -d ~/Library/Application\ Support/Google/Chrome/Default/Application\ Cache ]]; then
        info "clean" "Google Chrome"
        rm -rf ~/Library/Application\ Support/Google/Chrome/Default/Application\ Cache/* &>/dev/null
        info "done"
    fi
}

function cleanGoogleDrive() {
    if [[ -d ~/Library/Application\ Support/Google/DriveFS ]]; then
        info "clean" "Google Drive"
        killall "Google Drive File Stream" &>/dev/null
        rm -rf ~/Library/Application\ Support/Google/DriveFS/[0-9a-zA-Z]*/content_cache &>/dev/null
        info "done"
    fi
}

function cleanGradle() {
    if [[ -d ~/.gradle/caches ]]; then
        info "clean" "Gradle"
        rm -rf ~/.gradle/caches/* &>/dev/null
        info "done"
    fi
}

function cleanHomebrew() {
    if type "brew" &>/dev/null; then
        info "clean" "Homebrew"
        brew cleanup -s &>/dev/null
        rm -rf "$(brew --cache)" &>/dev/null
        brew tap --repair &>/dev/null
        info "done"
    fi
}

function cleanNpm() {
    if type "npm" &>/dev/null; then
        info "clean" "npm"
        npm cache clean --force &>/dev/null
        info "done"
    fi
}

function cleanRubyGems() {
    if type "gem" &>/dev/null; then
        info "clean" "Ruby Gems"
        gem cleanup &>/dev/null
        info "done"
    fi
}

function cleanSystem() {
    info "clean" "system"
    rm -rf /Library/Caches/* &>/dev/null
    rm -rf /Library/Logs/DiagnosticReports/* &>/dev/null
    rm -rf /System/Library/Caches/* &>/dev/null
    rm -rf /private/var/log/asl/*.asl &>/dev/null
    rm -rf ~/Library/Caches/* &>/dev/null
    rm -rf ~/Library/Containers/com.apple.mail/Data/Library/Logs/Mail/* &>/dev/null
    rm -rf ~/Library/Logs/CoreSimulator/* &>/dev/null
    info "done"
}

function cleanXcode() {
    if [[ -d ~/Library/Developer/Xcode/Archives ]] || [[ -d ~/Library/Developer/Xcode/DerivedData ]]; then
        info "clean" "Xcode"
        rm -rf ~/Library/Developer/Xcode/Archives/* &>/dev/null
        rm -rf ~/Library/Developer/Xcode/DerivedData/* &>/dev/null
        rm -rf ~/Library/Developer/Xcode/iOS Device Logs/* &>/dev/null
        info "done"
    fi
}

function cleanYarn() {
    if type "yarn" &>/dev/null; then
        info "clean" "Yarn"
        yarn cache clean --force &>/dev/null
        info "done"
    fi
}

# ------------------------------------------------------------------------------
# Updating Functions...
# ------------------------------------------------------------------------------

function updateComposer() {
    if type "composer" &>/dev/null; then
        info "update" "Composer"
        composer self-update --clean-backups &>/dev/null
        info "done"
    fi
}

function updateComposerPackages() {
    if type "composer" &>/dev/null; then
        info "update" "Composer packages"
        composer global update &>/dev/null
        info "done"
    fi
}

function updateHomebrew() {
    if type "brew" &>/dev/null; then
        info "update" "Homebrew"
        brew update --force &>/dev/null
        brew upgrade &>/dev/null
        info "done"
    fi
}

function updateMacAppStore() {
    if type "mas" &>/dev/null && [[ -n $(mas outdated) ]]; then
        info "update" "Mac App Store"
        mas upgrade &>/dev/null
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
    rm -rf /Volumes/*/.Trashes/* &>/dev/null
    rm -rf ~/.Trash/* &>/dev/null
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
    cleanAdobe
    cleanComposer
    cleanDocker
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

    emptyTrash
}

function initializeUpdate() {
    $shouldUpdateComposer && updateComposer
    $shouldUpdateComposerPackages && updateComposerPackages
    $shouldUpdateHomebrew && updateHomebrew
    $shouldUpdateMas && updateMacAppStore
}

# ------------------------------------------------------------------------------
# Options...
# ------------------------------------------------------------------------------

function handleOptions() {
    $shouldUpdate && initializeUpdate
    $shouldClean && initializeCleanup

    # Reinitialize the sudo timestamp since Homebrew invalidates it
    $shouldClearMemory || $shouldFlushDns && keepSudoAlive

    $shouldClearMemory && clearMemory
    $shouldFlushDns && flushDns
}

while [[ $# -gt 0 ]]; do
    case $1 in
        "--skip-clean") shouldClean=false ;;
        "--skip-composer") shouldUpdateComposer=false ;;
        "--skip-composer-packages") shouldUpdateComposerPackages=false ;;
        "--skip-dns") shouldFlushDns=false ;;
        "--skip-homebrew") shouldUpdateHomebrew=false ;;
        "--skip-mas") shouldUpdateMas=false ;;
        "--skip-memory") shouldClearMemory=false ;;
        "--skip-update") shouldUpdate=false ;;
        *) usage ;;
    esac

    shift
done

handleOptions

exit 0