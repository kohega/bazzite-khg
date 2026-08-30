# Bazzite - KHG's ver.

# Purpose

This repository is my own custom [bootc](https://github.com/bootc-dev/bootc) image based on [Bazzite](https://github.com/ublue-os/bazzite/). This project started as a personal image for my HTPC, running the desktop variant because I use [flex-launcher](https://github.com/complexlogic/flex-launcher) as a home launcher.
Now running on all my PCs except Steam Deck.

# What's added

## Root folder mountpoints
- /data
- /videos
- /games

## Tools
- [Screenprofilerswap/Screenprofilerback](https://github.com/kohega/screenprofilerswap)
- EDID file support up to 4K120 HDR10+/DV for Sunshine dumped from my TV.
    - 1280x720@120
    - 1280x800@60/120
    - 1920x1080@60/120/240
    - 1920x1200@60/90/120
    - 2340x1600@60 (iPad 10th)
    - 2442x1290@120 (iPhone 14 Pro Max - Safe Area)
    - 2560x1440@120
    - 2560x1600@120
    - 2800x1800@120
    - 3840x2160@120
  
## Theme

[Monochrome KDE theme](https://gitlab.com/pwyde/monochrome-kde)

## Layered

### Productivity and Utilities
| Application  | Description                                                      |
|--------------|------------------------------------------------------------------|
| BleachBit    | System cleaner to free space and protect privacy.                |
| Lact         | Tool to manage keyboard shortcuts on Linux.                      |
| merkuro      | Calendar application for KDE.                                   |
| NAPS2                     | Tool for scanning documents.                                     |
| epson-inkjet-printer-escpr| Printer driver for Epson inkjet printers.                        |
| Citrix           |  Access virtual applications and desktops .                   |

### Internet and Network
| Application       | Description                                                      |
|-------------------|------------------------------------------------------------------|
| Discord           | Voice and text messaging app for communities.                   |
| FileZilla         | FTP, FTPS, and SFTP client for file transfers.                  |
| Firefox           | Open-source web browser.                                         |
| Thunderbird       | Open-source e-mail client.                                         |
| qBittorrent       | Open-source BitTorrent client.                                  |
| Syncthing         | Decentralized file synchronization tool.                        |
| Eddie-UI          | AirVPN client.                                                  |
| zerotier-one      | Tool for creating virtual networks.                             |

### Multimedia
| Application               | Description                                                      |
|----------------------------|------------------------------------------------------------------|
| Audacity                   | Open-source audio editor.                                        |
| Heroic Games Launcher (bin)| Game launcher for Epic Games and GOG on Linux.                   |
| Kodi                       | Media center for organizing and playing movies, music, etc.     |
| kodi-inputstream-adaptive  | Kodi plugin for adaptive streaming playback.                    |
| Flex-Launcher              | 10-foot HTPC application launcher.                    |

### Development and Libraries
 | Application               | Description                                                      |
 |---------------------------|------------------------------------------------------------------|
 | gh                        | Command-line tool to interact with GitHub.                       |
 | inih                      | Library for parsing INI files.                                  |
 | SDL2_ttf                  | Library for rendering TrueType fonts with SDL2.                 |
 | SDL2_image                | Library for loading images (PNG, JPEG, etc.) with SDL2.         |
 | python-elevate            | Python library for elevating privileges.                        |
 | python-keyboard           | Python library for keyboard control.                            |
 | python-pyv4l2             | Python bindings for Video4Linux2.                                |
 | opencv                    | Open-source computer vision library.                            |
 | opencv-devel              | Development files for OpenCV.                                   |
 | v4l-utils                 | Video4Linux utilities.                                           |


### Virtualization and System Administration
 | Application               | Description                                                      |
 |---------------------------|------------------------------------------------------------------|
 | virt-manager              | Graphical interface for managing virtual machines (KVM/QEMU).   |
 | gamemode                  | Tool to optimize system performance for games.                  |

### System and Terminal Tools
 | Application               | Description                                                      |
 |---------------------------|------------------------------------------------------------------|
 | aria2c                    | Command-line tool for downloading files (HTTP, FTP, etc.).      |
 | scrcpy                    | Tool to control an Android device from a PC.                    |
 | gaze                     | Tool for facial recognition. Windows Hello alternative            |
 | msttcore-fonts-installer  | Microsoft core fonts installer.                                  |

### KDE Applications
 | Application               | Description                                                      |
 |---------------------------|------------------------------------------------------------------|
 | kcalc                     | Scientific calculator for KDE.                                  |
 | konsole                   | Terminal emulator for KDE.                                      |
 | kate                      | Advanced text editor for KDE.                                    |
 | krename                   | Batch file renaming tool.                                        |
 | okular                    | Universal document viewer (PDF, EPUB, images, etc.).            |
 | gwenview                  | Image viewer for KDE.                                            |
 | ark                       | Archiving tool for KDE.                                          |
 | kget                      | Download manager for KDE.                                        |
 | kvantum                   | Tool for customizing Qt application styles.                     
