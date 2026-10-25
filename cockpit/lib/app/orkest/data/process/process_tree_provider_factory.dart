import 'dart:io';

import 'package:orkest_code/app/orkest/data/process/linux_process_tree_provider.dart';
import 'package:orkest_code/app/orkest/data/process/macos_process_tree_provider.dart';
import 'package:orkest_code/app/orkest/data/process/windows_process_tree_provider.dart';
import 'package:orkest_code/app/orkest/data/process/wsl_process_tree_provider.dart';
import 'package:orkest_code/app/orkest/domain/contracts/process_tree_provider.dart';
import 'package:orkest_code/app/orkest/domain/services/terminal_harness_monitor.dart';
import 'package:orkest_code/app/core/ui/window_activity_controller.dart';

/// Host-native process inspector for the current platform.
ProcessTreeProvider createHostProcessTreeProvider() {
  if (Platform.isMacOS) return MacosProcessTreeProvider();
  if (Platform.isWindows) return WindowsProcessTreeProvider();
  return LinuxProcessTreeProvider();
}

/// Builds a WSL distro inspector. Used when a terminal profile carries
/// `wslDistro` on Windows.
ProcessTreeProvider createWslProcessTreeProvider(String distro) {
  return WslProcessTreeProvider(distro: distro);
}

/// App-facing monitor with host provider + lazy WSL adapters.
class OrkestTerminalHarnessMonitor extends TerminalHarnessMonitor {
  OrkestTerminalHarnessMonitor(
    ProcessTreeProvider provider,
    WindowActivityController activity,
  ) : super(
        provider: provider,
        wslProviderForDistro: createWslProcessTreeProvider,
        windowIsActive: () => activity.isActive,
      );
}
