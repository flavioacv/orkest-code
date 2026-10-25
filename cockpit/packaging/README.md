# Orkest Code packaging

The independent app ID is com.flavioacv.orkestcode. macOS builds produce
Orkest Code.app; the terminal command is orkest. Updates are disabled until
a publisher-owned feed and update signing key are configured.

```sh
flutter build macos --debug
```

Release publication requires our Apple Developer/notarization credentials,
Windows signing service, Android keystore, artifact storage and signed update
feeds. Do not use credentials or endpoints from the upstream runbook. Original
publishing workflows are archived outside the active workflows directory.

Platform package templates use the new identity. Linux/Windows/mobile packages
still require verification on their respective build hosts before publication.

## Private Apple Silicon test DMG

```sh
flutter build macos --release --no-pub
bash tool/package-test-dmg.sh
```

The packager checks the Release bundle ID, arm64 slices in the app/CLI/server,
and the code-signature seal. It copies only the compiled application and
notices into a temporary staging folder, adds an Applications symlink and a
Portuguese test guide, creates a compressed DMG, verifies it and exports a
SHA-256 sidecar. Output is under `dist/`; existing DMGs are not overwritten.

This is a private test package with local ad-hoc signing, not an Apple
Developer ID / notarized public release. The recipient may need to approve
the first launch in macOS Privacy & Security. No global Gatekeeper settings
are changed. The minimum macOS version comes from the compiled Info.plist.
No Flutter/Dart installation is required on the recipient's machine; agent
CLIs and their accounts must be installed/authenticated separately.

Private build generated on 2026-10-24: `0.1.0+1`, Apple Silicon, macOS 12+.
The DMG checksum and mounted app's ad-hoc signature were verified; the bundled
CLI and server executed from a read-only mount. The test image was then ejected.
GUI acceptance testing on the recipient's Mac remains the purpose of this build.
