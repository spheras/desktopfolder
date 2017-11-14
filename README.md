# Desktop Folder
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

![Example1](https://raw.githubusercontent.com/spheras/desktopfolder/master/etc/test-color.gif)
![Example2](https://raw.githubusercontent.com/spheras/desktopfolder/master/etc/test-grid.gif)
![Example3](https://raw.githubusercontent.com/spheras/desktopfolder/master/etc/test-item.gif)
![Example4](https://raw.githubusercontent.com/spheras/desktopfolder/master/etc/test-link.gif)
![Example5](https://raw.githubusercontent.com/spheras/desktopfolder/master/etc/test-note.gif)
![Example6](https://raw.githubusercontent.com/spheras/desktopfolder/master/etc/test-photo.gif)

## How to Install
If you use elementary OS, you can get it directly from the AppCenter.

[![Get it on AppCenter](https://appcenter.elementary.io/badge.svg)](https://appcenter.elementary.io/com.github.spheras.desktopfolder)

The main target is Elementary, but this should work also on GNOME 3. The bad news is that we have experienced problems with Wayland (i.e. used in the last Ubuntu). We are working hard to fix those issues regarding Wayland. Anyway, if you want to check you should use the latest [.deb release](https://github.com/spheras/desktopfolder/releases). To install the .deb with apt:

`sudo apt install ./com.github.spheras.desktopfolder_[version]_amd64.deb`

Open it like any other app after installing. Desktop Folder will launch automatically when you next log in.

## Contributing

See the [Contributing page](https://github.com/spheras/desktopfolder/wiki/Contributing) on the wiki.

## Building and Installing
You'll need the following dependencies to build:

* libgee-0.8-dev
* libcairo2-dev
* libjson-glib-dev
* libgdk-pixbuf2.0-dev
* libwnck-3-dev
* libgtksourceview-3.0-dev
* meson
* valac

Run `meson build` to configure the build environment and then change to the build directory and run `ninja` to build:

    meson build
    cd build
    meson configure -D prefix=/usr
    ninja

To install, use `ninja install`, then execute with `com.github.spheras.desktopfolder`:

    sudo ninja install
    com.github.spheras.desktopfolder
