# mpv-setup

A collection of scripts, shaders, and configuration files for MPV.

## Shaders

Anime4K shaders are based on **v4.0.1**.

* Original repository: https://github.com/bloc97/Anime4K
* Fork used in this setup: https://github.com/DirmdsLab/Anime4K

## Scripts

### Playlist Manager

Source: https://github.com/jonniek/mpv-playlistmanager

## Contents

* Scripts
* Shaders
* Configuration files

# Installation

Clone this repository or download it as a ZIP archive.

## Linux

Copy the following:

* `shaders/`
* `scripts/`
* `conf/linux/mpv.conf`
* `conf/linux/input.conf`

to:

```text
~/.config/mpv/
├── shaders/
├── scripts/
├── mpv.conf
└── input.conf
```

## Windows
run win win_setup.bat auto

Manual Copy:

* `shaders/`
* `scripts/`
* `conf/windows/mpv.conf`
* `conf/windows/input.conf`

to:

```text
%APPDATA%/mpv/
├── shaders/
├── scripts/
├── mpv.conf
└── input.conf
```

## Android

### Install MPV

* Google Play: https://play.google.com/store/apps/details?id=is.xyz.mpv
* Official website: https://mpv.io/installation/

Copy:

* `shaders/`
* `scripts/`
* `conf/android/mpv.conf`
* `conf/android/input.conf`


If the folder doesn't exist, just create one.

to:

```text
/storage/emulated/0/Android/media/is.xyz.mpv/
├── shaders/
├── scripts/
├── mpv.conf
└── input.conf
```

Then overwrite the existing scripts with:

```text
conf/android/scripts/
```

into:

```text
scripts/
```

## Android Configuration

Open MPV and go to:

**Settings → Touch gestures**

Set the following actions to **Custom**:

* Double tap left
* Double tap center
* Double tap right

Then go to:

**Settings → Advanced → Edit mpv.conf**

Add the following line:

```conf
include=/storage/emulated/0/Android/media/is.xyz.mpv/mpv.conf
```

## Android Gesture Controls

* **Double tap left** → Clear shader
* **Double tap center** → High quality
* **Double tap right** → Fast mode

If it doesn't work, try changing the HW to SW or vice versa.