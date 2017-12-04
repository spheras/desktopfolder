# Build on Arch Linux

- Clone this repo

```bash
git clone https://github.com/spheras/desktopfolder
```

- Navigate to the `desktopfolder/arch` folder

```bash
cd desktopfolder/arch
```

- Build the package (it may ask for your root password to install dependencies)

```bash
makepkg -s
```

- Install the newly built package

```bash
sudo pacman -U *.pkg.tar.xz
```
