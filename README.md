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

or just run ./linux_setup.sh

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

or just run win_setup.bat

## Android

### Install MPV

* Google Play: https://play.google.com/store/apps/details?id=is.xyz.mpv
* Official website: https://mpv.io/installation/

manual recomend manual

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

run script via termux

make sure the termux storage settings are set

just run ./termux_setup.sh

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


## Keybind
### Volume Control
- `W` → Increase volume (+5)
- `S` → Decrease volume (-5)

### Seeking
- `A` → Seek backward (-5s)
- `D` → Seek forward (+5s)

---

## Playlist Control

 `Ctrl + Shift + P` → Toggle playlist loop mode
  ```text
  cycle-values loop-playlist no inf
````

# High-End GPU Presets (Quality Mode)

### CTRL + 1 — Mode A (HQ)

```text
Anime4K: Mode A (HQ)
```

### CTRL + 2 — Mode B (HQ)

```text
Anime4K: Mode B (HQ)
```

### CTRL + 3 — Mode C (HQ)

```text
Anime4K: Mode C (HQ)
```

### CTRL + 4 — Mode A+A (HQ)

```text
Anime4K: Mode A+A (HQ)
```

### CTRL + 5 — Mode B+B (HQ)

```text
Anime4K: Mode B+B (HQ)
```

### CTRL + 6 — Mode C+A (HQ)

```text
Anime4K: Mode C+A (HQ)
```

### CTRL + U — Alternative Mode A+A (HQ)

```text
Anime4K: Mode A+A (HQ)
```

---

# Low-End GPU Presets (Performance Mode)

### CTRL + ALT + 1 — Mode A (Fast)

```text
Anime4K: Mode A (Fast)
```

### CTRL + ALT + 2 — Mode B (Fast)

```text
Anime4K: Mode B (Fast)
```

### CTRL + ALT + 3 — Mode C (Fast)

```text
Anime4K: Mode C (Fast)
```

### CTRL + ALT + 4 — Mode A+A (Fast)

```text
Anime4K: Mode A+A (Fast)
```

### CTRL + ALT + 5 — Mode B+B (Fast)

```text
Anime4K: Mode B+B (Fast)
```

### CTRL + ALT + 6 — Mode C+A (Fast)

```text
Anime4K: Mode C+A (Fast)
```
### CTRL + 0 — Clear shaders

```text
GLSL shaders cleared
```

# Color
### CTRL + SHIFT + ! — Default Color Profile

```text
Default
````

### CTRL + SHIFT + @ — Color Boost Profile

```text
Color Boost saturation +70
```

# Frame Info

### . — Next Frame

```text
Frame step forward
````

### , — Previous Frame

```text
Frame step backward
```

# Playlist Controls

### CTRL + L — Shuffle Playlist

```text
Shuffle playlist
````

### SHIFT + R — Reverse Playlist

```text
Reverse playlist order
```

### CTRL + S — Save Playlist

```text
Save playlist
```

---

### SHIFT + ENTER — Show Playlist

```text
Show playlist
```

### CTRL + SHIFT + ENTER — Open Menu

```text
Open menu
```
# Change Resolution

### ctrl + r 

```text
resolution menu
```

