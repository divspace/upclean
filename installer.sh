#!/usr/bin/env sh

VERSION=1.6.0

# ------------------------------------------------------------------------------
# UpClean v1.6.0 (https://upclean.app) — An update and cleanup script for macOS.
# ------------------------------------------------------------------------------

green="\033[0;32m"
yellow="\033[33m"
reset="\033[0m"

info() {
    if [ -n "$1" ]; then
        printf "%bUpClean 🧼 %b%s%b has been %s!%b\n" "$green" "$yellow" "$VERSION" "$green" "$1" "$reset"
    fi
}

install() {
    curl -o upclean https://raw.githubusercontent.com/divspace/upclean/master/upclean.sh
    chmod +x upclean
    sudo mv -f upclean /usr/local/bin/upclean
    touch ~/.upcleanrc
    info "$1"
}

uninstall() {
    rm -f /usr/local/bin/upclean ~/.upcleanrc
    info "uninstalled"
}

case $1 in
    "uninstall") uninstall ;;
    "update") install "updated" ;;
    *) install "installed" ;;
esac

exit 0
