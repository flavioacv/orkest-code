# Cockpit flterm snapshot

Source: jacobaraujo7/libghostty, commit a342abbec8f744714bf6c38fb5516acf19114486
(tag cockpit-pin-flterm-upstream-2026-10d). Original MIT license retained.
Only lib/, pubspec.yaml and LICENSE are vendored; workspace resolution removed.

Local fix: ViewAttachment releases its controller lease immediately on disposal,
but defers disposal of renderer listenables to the end of the frame. Flutter
reattaches GlobalKey render objects before rebuilding them with the replacement
attachment. Synchronous disposal caused addListener on a disposed ChangeNotifier
when closing/reparenting workspace terminals.

Regression: test/ui/ghostty_terminal_reparent_test.dart in the Cockpit app.
