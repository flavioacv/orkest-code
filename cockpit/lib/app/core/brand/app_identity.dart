/// Public identity of this independent distribution.
/// Updates stay offline until publisher-owned feeds and signing keys exist.
abstract final class AppIdentity {
  static const name = 'Orkest Code';
  static const tagline = 'Orchestrate AI. Build Better.';
  static const applicationId = 'com.flavioacv.orkestcode';
  static const cli = 'orkest';
  static const homeDirectory = '.orkest';
  static const repository = 'https://github.com/flavioacv/remote_pi';
  static const updatesEnabled = true;
  static const feedBaseUrl = 'https://orkest-updates.pages.dev/downloads/orkest';
}
