// Extra Zen prefs, appended verbatim to the generated user.js. Typed settings
// belong in `my.zen.settings`; this file is for blocks whose comments are the
// point.

// Disable GTK native emoji picker (Ctrl+. / Ctrl+;)
user_pref("widget.gtk.native-emoji-dialog", false);

// ─────────────────────────────────────────────────────────────
// Memory management — added 2026-08-08
// Rationale: Zen removed its time-based tab unloader and delegates
// to Firefox's native pressure-based one. Linux low-memory detection
// only landed in bug 1532955 (FIXED 2025-11-20); present in FF152.
// See: https://firefox-source-docs.mozilla.org/browser/tabunloader/
// ─────────────────────────────────────────────────────────────

// -- Layer 2: native tab unloader (safety net) --
user_pref("browser.tabs.unloadOnLowMemory", true);
// Force the detector to fire eagerly. On a 54GB machine genuine memory
// pressure never occurs, so the unloader would otherwise never run.
// Dial DOWN (50, 25) if unloading feels too aggressive.
user_pref("browser.low_commit_space_threshold_percent", 100);
user_pref("browser.low_commit_space_threshold_mb", 8192);
// Don't unload a tab touched within the last 5 minutes (avoids thrash).
user_pref("browser.tabs.min_inactive_duration_before_unload", 300000);
// Visually fade unloaded tabs so the state is legible.
user_pref("browser.tabs.fadeOutUnloadedTabs", true);
user_pref("browser.tabs.unloadTabInContextMenu", true);

// -- Layer 3: stop the accumulation --
// 1 = home page, 3 = restore previous session. This is what let 276
// tabs survive every reboot. Escape hatch: set back to 3.
user_pref("browser.startup.page", 1);
user_pref("browser.sessionstore.max_tabs_undo", 10);
user_pref("browser.sessionstore.max_windows_undo", 3);
// Restored/background tabs load only when clicked.
user_pref("browser.sessionstore.restore_on_demand", true);
user_pref("browser.sessionstore.restore_pinned_tabs_on_demand", true);
// Session file was 4.9MB rewritten every 15s; ease off the disk.
user_pref("browser.sessionstore.interval", 60000);
