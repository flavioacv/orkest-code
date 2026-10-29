import 'dart:io';

// Kill descendants before their parent so they cannot be orphaned by timeout.
// This is used by both local execution and proc.run on the remote host.
Future<void> terminateProcessTree(Process process) async {
  try {
    if (Platform.isWindows) {
      final result = await Process.run('taskkill', [
        '/PID',
        '${process.pid}',
        '/T',
        '/F',
      ]);
      if (result.exitCode == 0) return;
    } else {
      final result = await Process.run('ps', ['-axo', 'pid=,ppid=']);
      if (result.exitCode == 0) {
        final parents = <int, int>{};
        for (final line in '${result.stdout}'.split('\n')) {
          final fields = line.trim().split(RegExp(r'\s+'));
          if (fields.length != 2) continue;
          final pid = int.tryParse(fields[0]);
          final parent = int.tryParse(fields[1]);
          if (pid != null && parent != null) parents[pid] = parent;
        }
        final descendants = <int>{process.pid};
        var changed = true;
        while (changed) {
          changed = false;
          for (final entry in parents.entries) {
            if (descendants.contains(entry.value) &&
                descendants.add(entry.key)) {
              changed = true;
            }
          }
        }
        for (final pid in descendants.toList().reversed) {
          if (pid != process.pid) Process.killPid(pid, ProcessSignal.sigkill);
        }
      }
    }
  } on ProcessException {
    // The platform utility may be unavailable; still terminate the root.
    process.kill(ProcessSignal.sigkill);
    return;
  }
  process.kill(ProcessSignal.sigkill);
}
