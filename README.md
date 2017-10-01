# Desktop-Folder
Come back to life your elementary desktop!

[![Get it on AppCenter](https://appcenter.elementary.io/badge.svg)](https://appcenter.elementary.io/org.spheras.desktopfolder)

![Desktop-Folder Banner](https://github.com/spheras/Desktop-Folder/blob/master/data/banner.png?raw=true)

## Description
Organize your desktop using folders panels.Come back to life your minimalist desktop and organize it dropping files, folder, launchers, and notes!
- Color and Transparent Panels
- Resize and position everything
- Drop files/folders everywhere
- Create colorful notes
- Open source project

## Building, Testing, and Installation
You'll need the following dependencies to build:

* libgranite-dev
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

To install, use `ninja install`, then execute with `org.spheras.desktopfolder`

    sudo ninja install
    org.spheras.desktopfolder
