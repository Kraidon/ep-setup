## Description
**ep-setup** (where 'ep' is 'Epwell') is used for quick installation and customization of necessary software on SBC's, VPS, and any other Linux-machines.

## Platforms
This script works on the following platforms:

| Architecture | ArchLinux | Ubuntu | Debian | Manjaro |
| :----------- | :-------: | :----: | :----: | :-----: |
| x86_64       | +         | +      | ?      | ?       |
| aarch64      | +         | +      | +      | ?       |

## Packages and Plugins
- Packages:
    - [vim](https://www.vim.org) - text redactor.
    - [mc](https://midnight-commander.org) - file-manager.
    - [btop](https://github.com/aristocratos/btop) - system-analyzer.
    - [fish](https://fishshell.com) (4.9.2) - shell environment.
    - [zellij](https://zellij.dev) (v0.45.1) - window manager.
- Plug-managers:
    - [vim-plug](https://github.com/junegunn/vim-plug) (0.14.0) - plugin manager for vim.
    - [oh-my-fish](https://github.com/oh-my-fish/oh-my-fish) (v8) - plugin manager for fish.
- Vim-plugins:
    - [vim-fugitive](https://github.com/tpope/vim-fugitive)
    - [vim-surround](https://github.com/tpope/vim-surround)
    - [vim-airline](https://github.com/vim-airline/vim-airline)
    - [vim-airline-themes](https://github.com/vim-airline/vim-airline-themes)
    - [vim-gitgutter](https://github.com/airblade/vim-gitgutter)

## Structure
(this schema created by 'tree')
```bash
.
├── config.env
├── install.sh
└── .resource
    ├── archives    # Contains all downloaded archives
    ├── bin         # Contains all extracted binaries
    ├── dirs        # Contains all extracted directories
    └── logs        # Contains all log-files
```

## Installation
```bash
./install.sh
```
