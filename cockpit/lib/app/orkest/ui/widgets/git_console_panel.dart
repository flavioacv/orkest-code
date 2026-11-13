import 'package:orkest_code/app/core/ui/themes/themes.dart';
import 'package:orkest_code/app/orkest/ui/viewmodels/git_controller.dart';
import 'package:orkest_code/i18n/strings.g.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

class GitConsolePanel extends StatelessWidget {
  const GitConsolePanel({super.key, required this.git, required this.root});
  final GitController git;
  final String root;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: git,
    builder: (context, _) {
      final tr = context.t.orkest.gitDesktop;
      final entries = git.commandLogs
          .where((entry) => entry.root == root)
          .toList()
          .reversed
          .toList();
      return Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: GhostButton(
              key: const ValueKey('git-console-clear'),
              onPressed: entries.isEmpty
                  ? null
                  : () => git.clearCommandLogs(root: root),
              child: Text(tr.clearConsole),
            ),
          ),
          Expanded(
            child: entries.isEmpty
                ? Center(
                    child: Text(
                      tr.consoleEmpty,
                      style: context.typo.label.copyWith(
                        color: context.colors.text3,
                      ),
                    ),
                  )
                : ListView.builder(
                    key: PageStorageKey('git-console-$root'),
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      final color = entry.isRunning
                          ? context.colors.warn
                          : entry.exitCode == 0
                          ? context.colors.gitStaged
                          : context.colors.error;
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(10, 4, 10, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  entry.isRunning
                                      ? Icons.hourglass_empty
                                      : entry.exitCode == 0
                                      ? Icons.check
                                      : Icons.close,
                                  size: 13,
                                  color: color,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: SelectableText(
                                    entry.command,
                                    style: context.typo.mono.copyWith(
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                                Text(
                                  entry.isRunning
                                      ? tr.running
                                      : tr.exitCode(code: entry.exitCode ?? -1),
                                  style: context.typo.mono.copyWith(
                                    fontSize: 10,
                                    color: color,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '${entry.startedAt.toLocal()} · ${entry.root}',
                              style: context.typo.mono.copyWith(
                                fontSize: 10,
                                color: context.colors.text3,
                              ),
                            ),
                            if (entry.lines.isNotEmpty)
                              SelectableText(
                                entry.lines.join('\n'),
                                style: context.typo.mono.copyWith(
                                  fontSize: 10,
                                  color: context.colors.text2,
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      );
    },
  );
}
