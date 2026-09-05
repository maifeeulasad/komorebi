# Security Policy

## Reporting a vulnerability

Please report suspected security issues by opening an issue with the
`security` label, or by contacting the maintainer privately if the problem is
sensitive. Include reproduction steps and the affected version.

## Threat model

Komorebi renders **wallpaper packs** — directories containing a `config` file
plus media (`wallpaper.jpg`, `assets.png`, `video.mp4`) and, for
`WallpaperType=web_page`, a URL that is loaded in an embedded WebKit view.

**A wallpaper pack is untrusted input.** Installing a third-party pack means:

- Its media files are decoded by GdkPixbuf and GStreamer/libav. A malformed
  file targets memory-safety bugs in those libraries.
- A `web_page` pack runs web content (potentially with JavaScript) persistently
  on your desktop with your user privileges.

Only install wallpaper packs from sources you trust.

## Dependency surface

Komorebi links against several libraries with large, historically
CVE-prone attack surfaces. Keep them patched to your distribution's latest
security releases:

| Dependency        | Minimum (see CMakeLists) | Why it matters                          |
| ----------------- | ------------------------ | --------------------------------------- |
| `webkit2gtk-4.1`  | 4.1 (4.0 fallback)       | Renders `web_page` wallpapers (JS/HTML) |
| `gtk+-3.0`        | >= 3.14                  | UI toolkit                              |
| `glib-2.0`        | >= 2.38                  | Config parsing, GIO                     |
| `clutter-gst-3.0` | as packaged              | Video wallpaper playback (GStreamer)    |
| `gstreamer-1.0`   | as packaged              | Media decode                            |

WebKitGTK in particular should never be pinned to an old version: it is a full
browser engine and receives frequent security fixes upstream. Prefer the
distribution package so it tracks security updates automatically.

## Hardening notes

- `web_page` wallpapers load only `http`/`https`/`file` URLs, and the WebView
  disables file/universal access from file URLs, plugins, and Java.
- Wallpaper and video file names are validated against path traversal.
- Enum-like config fields are constrained to known-good values.
- Install paths under `/System/...` are installed without group/world write
  permission.

These mitigations reduce, but do not eliminate, the risk of running untrusted
packs. Treat pack installation as running third-party code.
