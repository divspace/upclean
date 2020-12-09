# UpClean

An update and cleanup script for macOS.

- [Installation](#installation)
- [Update](#update)
- [Uninstall](#uninstall)
- [Usage](#usage)

![Screenshot](./screenshot.png)

## Installation

You can use any of the methods below to install UpClean:

```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/divspace/upclean/master/installer.sh)"
```

```bash
sh -c "$(wget https://raw.githubusercontent.com/divspace/upclean/master/installer.sh -O -)"
```

```bash
curl -o upclean https://raw.githubusercontent.com/divspace/upclean/master/upclean.sh
chmod +x upclean
mv upclean /usr/local/bin/upclean
```

## Update

```bash
curl -fsSL "https://raw.githubusercontent.com/divspace/upclean/master/installer.sh" | bash -s update
```

## Uninstall

```bash
curl -fsSL "https://raw.githubusercontent.com/divspace/upclean/master/installer.sh" | bash -s uninstall
```

## Usage

```
$ upclean --help

UpClean 1.0.0 🧼 upclean.app

An update and cleanup script for macOS.

Usage:
  upclean [options]

Options:
      --skip-clean               Skip cleaning
      --skip-composer            Skip updating Composer
      --skip-composer-packages   Skip updating Composer packages
      --skip-dns                 Skip flushing DNS cache
      --skip-homebrew            Skip updating Homebrew
      --skip-mas                 Skip updating Mac App Store applications
      --skip-memory              Skip clearing inactive memory
      --skip-update              Skip updating
  -h, --help                     Display this help message
```