<p align="center"><img src="https://raw.githubusercontent.com/christianloopp/komorebi/master/screenshots/komorebi-icon.png" width="130"></p>
<h2 align="center">Komorebi - Animated Wallpapers for Linux</h2>
<p align="center">(n) sunlight filtering through trees.</p>



<p align="center">
	<a href="http://www.kernel.org"><img alt="Platform (GNU/Linux)" src="https://img.shields.io/badge/platform-GNU/Linux-blue.svg"></a>
	<a href="https://github.com/sindresorhus/awesome"><img alt="Awesome" src="https://cdn.rawgit.com/sindresorhus/awesome/d7305f38d29fed78fa85652e3a63e154dd8e8829/media/badge.svg"></a>
	<a href="https://travis-ci.org/christianloopp/komorebi"><img alt="Build Status" src="https://travis-ci.org/phw/peek.svg?branch=master"></a>
</p>

<p align="center">
<a href="http://www.youtube.com/watch?feature=player_embedded&v=NvfRy5qMsos
" target="_blank"><img src="http://img.youtube.com/vi/NvfRy5qMsos/0.jpg" 
alt="Komorebi Demo" width="240" height="180" border="10" /><br>Watch demo</a>
</p>

## What is Komorebi?

Komorebi is an awesome animated wallpapers manager for all Linux platforms.
It provides fully customizeable image, video, and web page wallpapers that can be tweaked at any time!

![s1](https://raw.githubusercontent.com/christianloopp/komorebi/master/screenshots/collage.jpg)


## How do I install Komorebi?

Two ways:

### Packaged install (easy)

1. Download `Komorebi` from the [Komorebi releases page](https://github.com/christianloopp/komorebi/releases).
2. Install Komorebi using your favorite package installer (aka. double click on it)
3. Launch Komorebi!

### Manual Installing (advanced)

Run the following:
```
sudo add-apt-repository ppa:gnome3-team/gnome3 -y
sudo add-apt-repository ppa:vala-team -y
sudo add-apt-repository ppa:gnome3-team/gnome3-staging -y
sudo apt install cmake valac libgtk-3-dev libgee-0.8-dev libclutter-gtk-1.0-dev libclutter-1.0-dev libwebkit2gtk-4.1-dev libclutter-gst-3.0-dev
git clone https://github.com/christianloopp/komorebi.git
cd komorebi
mkdir build && cd build
cmake .. && sudo make install && ./komorebi
```

> Note: on modern distros (Ubuntu 22.04+) use `libwebkit2gtk-4.1-dev`. Older
> systems can still use `libwebkit2gtk-4.0-dev`; the build auto-detects the
> package at configure time.

## Compatibility: X11 only (no Wayland yet)

Komorebi is **X11-only**. It paints a real X11 window per monitor with the
`DESKTOP` window-type hint (desktop layer, kept below everything, stuck on all
workspaces), which is how it layers behind icons and renders image/video/web
wallpapers. None of that exists on Wayland, and the GTK3/Clutter/Cogl rendering
path cannot create a Wayland surface. Behaviour depends on the session:

* **Wayland with XWayland** (most compositors, incl. GNOME/Mutter on Ubuntu):
  the app detects the Wayland session, sets `GDK_BACKEND=x11` itself and runs
  against the XWayland display (`src/Main.vala`). Launching it from the menu or
  autostart therefore just works. This is what this build is validated against.
* **Wayland without an X11 display**: Komorebi prints a clear error and exits
  instead of half-rendering or crashing.
* **X11 / Xorg session**: runs natively, no workarounds needed.
* You can always force a specific backend manually:
  ```
  GDK_BACKEND=x11 ./komorebi
  ```
* Native Wayland support requires rewriting the render layer (Clutter/Cogl
  would need a Wayland backend or a move to Wlroots/GTK4) — a substantial
  project.

## How it works (architecture)

Everything is written in Vala against GTK3 + Clutter (GPU-scaled actor graph)
and a `GtkClutter.Embed` stage per monitor.

* `src/Main.vala` — entry point. Sanity-checks the compositor/session, inits
  GTK/Clutter (and GStreamer only when a *video* wallpaper is active), reads
  config, then creates one `BackgroundWindow` per monitor.
* `src/Utilities.vala` — shared globals and helpers: reading `~/.Komorebi.prop`
  and each wallpaper's `config` key-file, icon lookup, pixbuf→RGBA conversion
  (Cogl GLES backends abort on 24-bit RGB textures), and the wallpaper-name
  path-traversal guards.
* `src/OnScreen/` — the actor/window layer:
  - `BackgroundWindow.vala` — the per-monitor `DESKTOP`-hinted Gtk window;
    owns the wallpaper actor, the optional GStreamer video player, the webview
    actor, and the date-time / asset / menu / icon layers. Also hosts the
    right-click bubble menu handlers, drag-drop, and parallax motion.
  - `DesktopIcons.vala` + `Icon.vala` + `ResponsiveGrid.vala` — the desktop
    icon grid (only on monitor 0), watching `~/Desktop` with a `FileMonitor`.
  - `DateTimeBox.vala` — clock + date overlay with parallax/drag, margins,
    rotation, and shadow blur.
  - `AssetActor.vala` — the animated overlay layer (`clouds` / `light` modes)
    on top of the base wallpaper.
  - `BubbleMenu.vala` + `BubbleMenuItem.vala` — the right-click desktop/icon
    menu.
  - `WallpapersSelector.vala` + `Thumbnail.vala` — the "Change Wallpaper" grid
    that scans `/System/Resources/Komorebi/`.
  - `PreferencesWindow.vala` — settings window (24h clock, icons, video) and
    wallpaper picker.
  - `InfoWindow.vala`, `RowLabel.vala` — "Get Info" dialogs.
* Wallpapers live in `/System/Resources/Komorebi/<name>/` (kept in the macOS-like
  layout for historical reasons) as a `wallpaper.jpg`, optional `assets.png`, and a
  `config` key-file (see `data/Wallpapers/`). The daemon renders whatever
  `config` describes: `WallpaperType=image|video|web_page`.
* `extra/wallpaper-creator/` — a separate Gtk app that packages a new wallpaper
  from an image, video, or URL.

### Bugs fixed in this build

* **Startup texture crash (Cogl):** creating a `ClutterGst.Playback` on every
  launch made Cogl pre-allocate a blank video frame before any wallpaper was
  loaded; on several GLES/XWayland setups that aborts the whole app with
  `Failed to create texture 2d due to size/format constraints`. The video
  pipeline is now only created when the active wallpaper is actually a video.
* **Multi-monitor crash:** only monitor 0 has a `desktopIcons` grid; right-click
  menu handling and the Preferences "show icons" toggle hit `null` on other
  monitors and crashed. All such paths are null-guarded now.
* **Broken desktop entries / symlinks:** malformed `.desktop` files or broken
  symlinks on the desktop raised uncaught `GLib.Error`s that took down the daemon.
  They are now skipped or degraded gracefully.
* **RGB vs RGBA textures:** pixbufs are converted to RGBA before being uploaded
  to Cogl (24-bit RGB textures are rejected by many drivers).
* **Wallpaper/thumbnail loading:** missing or corrupt `wallpaper.jpg`,
  `assets.png`, or `wallpaper.jpg` thumbnails no longer throw; they fall back to
  a blank texture / warning.
* **`--version` handling:** the args check no longer reads `args[1]` when no
  argument was passed.
* **Wayland sessions now fall back to XWayland automatically:** instead of only
  printing "Wayland detected" advice and quitting, Komorebi sets
  `GDK_BACKEND=x11` itself when an X11 display is reachable, so the menu /
  autostart launcher works out of the box on Wayland.
* **Texture-upload failures are handled:** environments where the GL/EGL
  fallback cannot create textures (e.g. software GL) previously emitted uncaught
  `CRITICAL`s from `wallpaperImage`, `AssetActor` and icon uploads. These are
  caught now and degrade to a plain background instead.

## Running Komorebi as an always-on daemon

Launching `komorebi &` from a terminal ties the process to that shell: when the
shell exits (or the process dies) the wallpaper disappears. To make Komorebi
start at every login **and** come back by itself if it crashes or is killed,
run it as a systemd *user* service — no root required:

**`~/.config/systemd/user/komorebi.service`**
```ini
[Unit]
Description=Komorebi animated wallpaper daemon
After=graphical-session.target
PartOf=graphical-session.target

[Service]
Type=simple
Environment=GDK_BACKEND=x11
ExecStart=/System/Applications/komorebi
Restart=always
RestartSec=3

[Install]
WantedBy=default.target
```

What each bit does:

* `After=graphical-session.target` (+ `PartOf`) — waits until the desktop session
  is up so the display server exists, then starts the wallpaper with it.
* `Environment=GDK_BACKEND=x11` — pins the X11 backend explicitly (they run on
  XWayland from a Wayland session), see *Compatibility* above.
* `Restart=always` / `RestartSec=3` — systemd respawns Komorebi ~3s after any
  crash or `kill`. This is the piece the XDG-autostart entry does *not* provide.
* `WantedBy=default.target` — enables start-on-login.

Enable it once:

```sh
systemctl --user daemon-reload
systemctl --user enable --now komorebi.service
```

Day-to-day management:

```sh
systemctl --user status  komorebi.service      # is it running (expect: active (running))?
systemctl --user restart komorebi.service      # after rebuilding / reinstalling
systemctl --user stop    komorebi.service
systemctl --user disable --now komorebi.service   # undo everything
```

### Don't double-launch it

The installer's `postinst` script also drops `komorebi.desktop` into
`~/.config/autostart/`, which starts a *second* daemon at login — a second set
of desktop windows fighting over the config. When you use the systemd service,
neutralise that entry:

```sh
mv ~/.config/autostart/komorebi.desktop ~/.config/autostart/komorebi.desktop.disabled
```

> If you ever re-run `sudo make install`, `postinst` recreates the autostart
> file, so move it aside again (or prefer one mechanism and drop the other).

## Change Wallpaper & Desktop Preferences
To change desktop preferences or your wallpaper, right click anywhere on the desktop to show the menu.

![s1](https://raw.githubusercontent.com/christianloopp/komorebi/master/screenshots/preferences.jpg)

## How do I create my own wallpaper?

Komorebi provides a simple tool to create your own wallpapers! Simply, open your apps and search for 'Wallpaper Creator'

![s1](https://raw.githubusercontent.com/christianloopp/komorebi/master/screenshots/wallpaper_creator.jpg)

You can use either an image, a video, or a web page as a wallpaper and you have many different options to customize your very own wallpaper!

## Uninstall

### If you installed a packaged version of Komorebi

1. Open Terminal
2. `sudo apt remove komorebi`

### If you manually installed Komorebi

1. Open Terminal
2. `cd komorebi/build`
3. `sudo make uninstall`

## Questions? Issues?

### My video wallpaper doesn't play (or the list says video support is missing)

Video playback goes through GStreamer, which needs the ffmpeg-based
`gstreamer1.0-libav` package to decode common containers (H.264, HEVC, ...). If
it's missing, Komorebi shows "gstreamer1.0-libav is missing" in Desktop
Preferences (the wallpaper selector still lists the pack, but it won't render).
Install it and restart the daemon:

```sh
sudo apt install -y gstreamer1.0-libav
systemctl --user restart komorebi.service
```

`src/Utilities.vala:canPlayVideos()` probes the usual
`/usr/lib/.../gstreamer-1.0/libgstlibav.so` paths to decide.

### How do I use my own video file as a wallpaper?

A video wallpaper is just a folder under `/System/Resources/Komorebi/<name>/`
holding a `config` key-file, the video itself, and an optional `wallpaper.jpg`
poster (needed for the "Change Wallpaper" picker to list it). For example, a
4K clip from `~/Downloads` as `my_4k_video`:

```
sudo install -d -m 0755 /System/Resources/Komorebi/my_4k_video
sudo install -m 0644 ~/Downloads/<file>.mp4 /System/Resources/Komorebi/my_4k_video/video.mp4
# writes a poster frame + then the config below
```

`/System/Resources/Komorebi/my_4k_video/config`:
```ini
[Info]
WallpaperType=video
VideoFileName=video.mp4

[DateTime]
Visible=false
Parallax=false

MarginLeft=0
MarginTop=0
MarginBottom=0
MarginRight=0

RotationX=0
RotationY=0
RotationZ=0

Position=center
Alignment=center
AlwaysOnTop=false

Color=white
Alpha=255

ShadowColor=black
ShadowAlpha=120

TimeFont=Lato Light 50
DateFont=Lato Light 30

[Wallpaper]
Parallax=false

[Asset]
Visible=false
AnimationMode=noanimation
AnimationSpeed=100

Width=0
Height=0
```

Then activate it (either pick it in Desktop Preferences → Wallpapers, or set the
name directly):
```sh
sed -i 's/^WallpaperName=.*/WallpaperName=my_4k_video/' ~/.Komorebi.prop
systemctl --user restart komorebi.service
```

> `VideoFileName` and `WallpaperName` must stay single plain path components —
> they're validated against path traversal (see `SECURITY.md`).

### Komorebi is slow. What can I do about it?

Komorebi includes support for video wallpapers that might slow your computer down. You can disable support for video wallpapers in 'Desktop Preferences' → uncheck 'Enable Video Wallpapers'.

_note: you need to quit and re-open Komorebi after changing this option_


### After uninstalling, my desktop isn't working right (blank or no icons)

The latest Komorebi should already have a fix for this issue. If you've already uninstalled Komorebi and would like to fix the issue, simply run this (in the Terminal):
`curl -s https://raw.githubusercontent.com/christianloopp/komorebi/master/data/Other/postrm | bash -s`

If your issue has not already been reported, please report it *[`here`](https://github.com/christianloopp/komorebi/issues/new)* and I'll try my best to fix them.

### Why does Komorebi install files in a macOS-like structure?

Komorebi was originally intended to run on an unreleased OS project. Since many people already use Komorebi, an update could potentially break Komorebi and custom-made wallpapers.

It is possible to change the file structure with code changes and a `postinst` script but I'd rather keep it as is for now or if you have the time to make one, feel free to do so and submit a PR!


## Status of Development

Komorebi still receives updates but they are not as frequent due to my involvement in other open-source projects.


### Thanks To:

Pete Lewis ([@PJayB](https://github.com/PJayB)) for adding mult-monitor support
