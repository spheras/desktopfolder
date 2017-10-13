# Desktop-Folder
Come back to life your Pantheon or Gnome3 desktop!

NOT YET IN ELEMENTARY APPCENTER!

[![Get it on AppCenter](https://appcenter.elementary.io/badge.svg)](https://appcenter.elementary.io/com.github.spheras.desktopfolder)

![Desktop-Folder Banner](https://raw.githubusercontent.com/spheras/desktopfolder/master/etc/banner.png)

## Description
Organize your desktop using folders panels.Come back to life your minimalist desktop and organize it dropping files, folder, launchers, and notes!
- Color and Transparent Panels
- Resize and position everything
- Drop files/folders everywhere
- Drop launchers .desktop to panels
- Create soft links to files and folders
- Create colorful notes
- Photos over your desktop
- Show Desktop Hotkey ⌘-D
- Autostart on login
- Open source project

![Example1](https://raw.githubusercontent.com/spheras/desktopfolder/master/etc/gif01.gif)
![Example2](https://raw.githubusercontent.com/spheras/desktopfolder/master/etc/gif02.gif)
![Example3](https://raw.githubusercontent.com/spheras/desktopfolder/master/etc/gif03.gif)
![Example4](https://raw.githubusercontent.com/spheras/desktopfolder/master/etc/gif04.gif)

## How to install
(under construction)

## Building, Testing, and Installation
You'll need the following dependencies to build:

* libgee-0.8-dev,
* libcairo2-dev,
* libjson-glib-dev,
* libgdk-pixbuf2.0-dev,
* libwnck-3-dev
* meson
* valac

Run `meson build` to configure the build environment and then change to the build directory and run `ninja` to build

    meson build
    cd build
    mesonconf -Dprefix=/usr
    ninja

To install, use `ninja install`, then execute with `com.github.spheras.desktopfolder`

    sudo ninja install
    com.github.spheras.desktopfolder
