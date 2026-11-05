import 'package:flutter/services.dart';
import 'package:orkest_code/app/core/ui/commands/command_item.dart';
import 'package:orkest_code/app/core/ui/themes/themes.dart';
import 'package:orkest_code/app/core/ui/widgets/app_tooltip.dart';
import 'package:orkest_code/app/core/ui/widgets/apple_glass_surface.dart';
import 'package:orkest_code/app/core/ui/widgets/hover_tap.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

/// Abre a Command Palette unificada centrada no topo.
Future<void> showCommandPalette(
  BuildContext context, {
  required List<AppCommandItem> commands,
  String initialQuery = '',
}) {
  return showDialog<void>(
    context: context,
    barrierColor: context.colors.scrim,
    builder: (context) => CommandPalette(
      commands: commands,
      initialQuery: initialQuery,
    ),
  );
}

class CommandPalette extends StatefulWidget {
  const CommandPalette({
    super.key,
    required this.commands,
    this.initialQuery = '',
  });

  final List<AppCommandItem> commands;
  final String initialQuery;

  @override
  State<CommandPalette> createState() => _CommandPaletteState();
}

class _CommandPaletteState extends State<CommandPalette> {
  late final TextEditingController _ctrl;
  final FocusNode _focus = FocusNode();
  final ScrollController _scroll = ScrollController();
  late final AppCommandRegistry _registry;

  List<AppCommandItem> _filtered = const <AppCommandItem>[];
  int _selected = 0;

  @override
  void initState() {
    super.initState();
    _registry = AppCommandRegistry(widget.commands);
    _ctrl = TextEditingController(text: widget.initialQuery);
    _filtered = _registry.filter(widget.initialQuery);
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    setState(() {
      _filtered = _registry.filter(value);
      _selected = 0;
    });
  }

  void _move(int delta) {
    if (_filtered.isEmpty) return;
    setState(() {
      _selected = (_selected + delta).clamp(0, _filtered.length - 1);
    });
    _ensureVisible();
  }

  void _ensureVisible() {
    if (!_scroll.hasClients) return;
    const itemHeight = 36.0;
    final target = _selected * itemHeight;
    final top = _scroll.offset;
    final bottom = top + _scroll.position.viewportDimension;
    if (target < top) {
      _scroll.jumpTo(target);
    } else if (target + itemHeight > bottom) {
      _scroll.jumpTo(target + itemHeight - _scroll.position.viewportDimension);
    }
  }

  void _runSelected() {
    if (_selected < 0 || _selected >= _filtered.length) return;
    final item = _filtered[_selected];
    if (!item.isEnabled) return;
    Navigator.of(context).pop();
    item.onSelected();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowDown:
        _move(1);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowUp:
        _move(-1);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.enter:
      case LogicalKeyboardKey.numpadEnter:
        _runSelected();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.escape:
        Navigator.of(context).pop();
        return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typo = context.typo;

    return Align(
      alignment: const Alignment(0, -0.55),
      child: AppleGlassSurface(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 460),
        radius: 14,
        blurSigma: 28,
        surfaceColor: colors.panel,
        opacity: 0.88,
        shadows: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 32,
            offset: const Offset(0, 14),
          ),
        ],
        child: Focus(
          onKeyEvent: _onKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(10),
                child: TextField(
                  controller: _ctrl,
                  focusNode: _focus,
                  placeholder: Text(
                    '> Type a command or action…',
                    style: typo.body.copyWith(color: colors.text4),
                  ),
                  style: typo.body.copyWith(color: colors.text),
                  border: Border.all(color: colors.border),
                  borderRadius: BorderRadius.circular(8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 9,
                  ),
                  onChanged: _onChanged,
                ),
              ),
              Container(height: 1, color: colors.border.withValues(alpha: 0.6)),
              Flexible(
                child: _filtered.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.fromLTRB(14, 16, 14, 20),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'No matching commands.',
                            style: typo.label.copyWith(color: colors.text4),
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: _scroll,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 6,
                        ),
                        itemCount: _filtered.length,
                        itemBuilder: (context, i) => _row(context, i),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(BuildContext context, int index) {
    final colors = context.colors;
    final typo = context.typo;
    final item = _filtered[index];
    final selected = index == _selected;

    final rowContent = HoverTap(
      color: selected ? colors.accentSoft : null,
      hoverColor: item.isEnabled
          ? (selected ? colors.accentSoft : colors.panel2)
          : null,
      borderRadius: BorderRadius.circular(8),
      onTap: item.isEnabled
          ? () {
              Navigator.of(context).pop();
              item.onSelected();
            }
          : null,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      child: Opacity(
        opacity: item.isEnabled ? 1.0 : 0.45,
        child: Row(
          children: [
            if (item.icon != null) ...[
              Icon(
                item.icon,
                size: 15,
                color: selected && item.isEnabled
                    ? colors.accentText
                    : colors.text3,
              ),
              const SizedBox(width: 8),
            ],
            Text(
              item.category,
              style: typo.label.copyWith(
                fontSize: 11,
                color: colors.text3,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 6),
            const Text('›', style: TextStyle(color: Color(0x66888888), fontSize: 11)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                item.title,
                overflow: TextOverflow.ellipsis,
                style: typo.body.copyWith(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
                  color: selected && item.isEnabled
                      ? colors.accentText
                      : colors.text,
                ),
              ),
            ),
            if (item.shortcutHint != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: colors.panel2,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: colors.border.withValues(alpha: 0.5)),
                ),
                child: Text(
                  item.shortcutHint!,
                  style: typo.mono.copyWith(
                    fontSize: 10,
                    color: colors.text3,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );

    if (!item.isEnabled && item.disabledReason != null) {
      return AppTooltip(
        message: item.disabledReason!,
        child: rowContent,
      );
    }

    return rowContent;
  }
}
