//
//  Copyright (C) 2016-2017 @christianloopp
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

using Komorebi.OnScreen;
using Komorebi.Utilities;

namespace Komorebi {

    BackgroundWindow[] backgroundWindows;

    public static bool checkDesktopCompatible() {

        // Komorebi is X11-only: it relies on X11 desktop-window semantics
        // (DESKTOP window type hint, stick(), keep-below). Under Wayland the
        // Cogl/EGL path fails and the app crashes, so refuse it up front.

        // Allow an explicit override for users who want to try XWayland via
        // `GDK_BACKEND=x11 ./komorebi`.
        var gdkBackend = Environment.get_variable ("GDK_BACKEND");
        if(gdkBackend != null && gdkBackend.down().contains("x11"))
            return true;

        // XDG_SESSION_TYPE is the reliable signal ("wayland" / "x11" / "tty").
        // NB: XDG_SESSION_DESKTOP is the desktop *name* (e.g. "ubuntu") and
        // must not be used for this check.
        var sessionType = Environment.get_variable ("XDG_SESSION_TYPE");
        if(sessionType != null && sessionType.down() == "wayland")
            return false;

        // Fallback: a Wayland session always exports WAYLAND_DISPLAY.
        var waylandDisplay = Environment.get_variable ("WAYLAND_DISPLAY");
        if(waylandDisplay != null && waylandDisplay != "" &&
           (sessionType == null || sessionType.down() != "x11"))
            return false;

        return true;
    }

    public static void main (string [] args) {

        print("Welcome to Komorebi\n");

        if(args[1] == "--version" || args[1] == "version") {
            print("Version: 2.1 - Summit\nCreated by: @christianloopp\n\n");
            return;
        }

        if(!checkDesktopCompatible()) {
            print("[ERROR]: Wayland session detected. Komorebi is X11-only and is not supported on Wayland (yet).\n");
            print("[INFO]: Log in to an Xorg/X11 session (\"Ubuntu on Xorg\" from the login screen gear menu),\n");
            print("[INFO]: or try running under XWayland with: GDK_BACKEND=x11 ./komorebi\n");
            print("[INFO]: Contribute to Komorebi and add native Wayland support! <3\n");
            return;
        }

        GtkClutter.init (ref args);
        Gtk.init (ref args);

        readConfigurationFile();

        if(OnScreen.enableVideoWallpapers) {

            print("[INFO]: loading Gst\n");
            Gst.init (ref args);
        }

        Gtk.Settings.get_default().gtk_application_prefer_dark_theme = true;

        var screen = Gdk.Screen.get_default ();
        int monitorCount = screen.get_n_monitors();


        initializeClipboard(screen);

        readWallpaperFile();

        backgroundWindows = new BackgroundWindow[monitorCount];
        for (int i = 0; i < monitorCount; ++i)
            backgroundWindows[i] = new BackgroundWindow(i);


        var mainSettings = Gtk.Settings.get_default ();
        // mainSettings.set("gtk-xft-dpi", (int) (1042 * 100), null);
        mainSettings.set("gtk-xft-antialias", 1, null);
        mainSettings.set("gtk-xft-rgba" , "none", null);
        mainSettings.set("gtk-xft-hintstyle" , "slight", null);

        for (int i = 0; i < monitorCount; ++i)
            backgroundWindows[i].fadeIn();

        Clutter.main();
    }
}
