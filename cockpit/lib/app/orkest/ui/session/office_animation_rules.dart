// Timing/precedence shared by terminal snapshots and the native Office. Values
// match the vendored Office simulation; none depend on a harness/tool name.
enum OfficeShellStage { popcorn, restless, cobweb, nap }

abstract final class OfficeAnimationRules {
  static const foregroundWaitMs = 10000;
  static const socialShellMinMs = 40000;
  static const longIdleMs = 600000;
  static const shellSuccessMs = 2200;
  static const shellFailureMs = 4000;
  static const partyCheerMs = 2600;

  static OfficeShellStage shellStage(int ageMs) {
    if (ageMs >= 1500000) return OfficeShellStage.nap;
    if (ageMs >= 600000) return OfficeShellStage.cobweb;
    if (ageMs >= 180000) return OfficeShellStage.restless;
    return OfficeShellStage.popcorn;
  }

  static bool shouldRun(double tiles, String mode) => switch (mode) {
    'waiting' => tiles > 2,
    'working' => tiles > 12,
    'shell' => tiles > 20,
    _ => false,
  };

  static (int, int) idleRange(String liveliness) => switch (liveliness) {
    'calm' => (16000, 42000),
    'lively' => (3000, 10000),
    _ => (6000, 20000),
  };

  static double lightLevel(bool on, int elapsedMs) {
    final e = elapsedMs < 0 ? 0 : elapsedMs;
    if (on) {
      if (e < 70) return .75;
      if (e < 160) return .1;
      if (e < 220) return .9;
      if (e < 330) return .25;
      return (.25 + (e - 330) / 220).clamp(0, 1);
    }
    if (e < 60) return .55;
    if (e < 120) return .95;
    return (.95 * (1 - (e - 120) / 480)).clamp(0, 1);
  }

  static String screenMode(String? activity) => switch (activity) {
    'edit' || 'write' || 'thinking' || 'think' => 'code',
    'command' || 'run' || 'test' || 'git' => 'terminal',
    'web' || 'browser' || 'mcp' => 'browser',
    'search' => 'search',
    'read' || 'respond' || 'compact' => 'docs',
    'plan' || 'skill' => 'tasks',
    'delegate' || 'needs_input' || 'prompt' || 'communicate' || 'ask' => 'chat',
    'wait' || 'error' => 'alert',
    'done' => 'idle',
    _ => 'code',
  };
}
