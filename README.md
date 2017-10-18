# Desktop-Folder
Bring your desktop back to life.

[![Get it on AppCenter](https://appcenter.elementary.io/badge.svg)](https://appcenter.elementary.io/com.github.spheras.desktopfolder)

![Desktop Folder Banner](https://raw.githubusercontent.com/spheras/desktopfolder/master/etc/banner.png)

## Description
Organize your desktop with panels that hold your things.
- Access files, folders and apps from your desktop
- Drop files, folders, links and .desktop launchers inside panels
- Resize, position and color panels
- Display photos and keep notes on your desktop
- Reveal the desktop with ⌘-D

![Example1](https://raw.githubusercontent.com/spheras/desktopfolder/master/etc/gif01.gif)
![Example2](https://raw.githubusercontent.com/spheras/desktopfolder/master/etc/gif02.gif)
![Example3](https://raw.githubusercontent.com/spheras/desktopfolder/master/etc/gif03.gif)
![Example4](https://raw.githubusercontent.com/spheras/desktopfolder/master/etc/gif04.gif)

## How to install
If you use elementary OS, you can get it directly from the AppCenter.

[![Get it on AppCenter](https://appcenter.elementary.io/badge.svg)](https://appcenter.elementary.io/com.github.spheras.desktopfolder)

If you use GNOME 3, you should use the latest [.deb release](https://github.com/spheras/desktopfolder/releases). To install the .deb with apt:

`sudo apt install ./com.github.spheras.desktopfolder_[version]_amd64.deb`

After installing, re-login to start using Desktop Folder.

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
