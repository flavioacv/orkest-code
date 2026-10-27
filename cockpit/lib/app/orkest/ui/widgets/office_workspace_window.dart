import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart'
    show IconButton, Icons, Divider;
import 'package:orkest_code/app/core/ui/themes/themes.dart';

class OfficeWorkspaceWindow extends StatefulWidget {
  const OfficeWorkspaceWindow({
    super.key,
    required this.title,
    required this.projectName,
    required this.onClose,
    required this.child,
  });

  final String title;
  final String projectName;
  final VoidCallback onClose;
  final Widget child;

  @override
  State<OfficeWorkspaceWindow> createState() => _OfficeWorkspaceWindowState();
}

class _OfficeWorkspaceWindowState extends State<OfficeWorkspaceWindow> {
  Rect? _bounds;
  bool _maximized = false;

  Rect _fit(Rect rect, Size area) {
    final width = rect.width
        .clamp(math.min(420.0, area.width), area.width)
        .toDouble();
    final height = rect.height
        .clamp(math.min(260.0, area.height), area.height)
        .toDouble();
    return Rect.fromLTWH(
      rect.left.clamp(0, area.width - width),
      rect.top.clamp(0, area.height - height),
      width,
      height,
    );
  }

  void _toggleMaximized() => setState(() => _maximized = !_maximized);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final area = constraints.biggest;
          final initial = Rect.fromLTWH(
            area.width * .11,
            area.height * .11,
            area.width * .78,
            area.height * .78,
          );
          final normal = _fit(_bounds ?? initial, area);
          final rect = _maximized ? Offset.zero & area : normal;
          Widget handle(int x, int y) => Positioned(
            left: x <= 0 ? 0 : null,
            right: x >= 0 ? 0 : null,
            top: y <= 0 ? 0 : null,
            bottom: y >= 0 ? 0 : null,
            width: x == 0 ? null : 8,
            height: y == 0 ? null : 8,
            child: MouseRegion(
              cursor: x == 0
                  ? SystemMouseCursors.resizeUpDown
                  : y == 0
                  ? SystemMouseCursors.resizeLeftRight
                  : x == y
                  ? SystemMouseCursors.resizeUpLeftDownRight
                  : SystemMouseCursors.resizeUpRightDownLeft,
              child: GestureDetector(
                key: ValueKey('office-resize-$x-$y'),
                behavior: HitTestBehavior.opaque,
                onPanUpdate: (event) {
                  final minWidth = math.min(420.0, area.width);
                  final minHeight = math.min(260.0, area.height);
                  var left = normal.left;
                  var top = normal.top;
                  var right = normal.right;
                  var bottom = normal.bottom;
                  if (x < 0) {
                    left = (left + event.delta.dx).clamp(0, right - minWidth);
                  }
                  if (x > 0) {
                    right = (right + event.delta.dx).clamp(
                      left + minWidth,
                      area.width,
                    );
                  }
                  if (y < 0) {
                    top = (top + event.delta.dy).clamp(0, bottom - minHeight);
                  }
                  if (y > 0) {
                    bottom = (bottom + event.delta.dy).clamp(
                      top + minHeight,
                      area.height,
                    );
                  }
                  setState(
                    () => _bounds = Rect.fromLTRB(left, top, right, bottom),
                  );
                },
              ),
            ),
          );
          return Stack(
            children: [
              const Positioned.fill(
                child: ColoredBox(color: Color(0x44000000)),
              ),
              Positioned.fromRect(
                rect: rect,
                child: DecoratedBox(
                  key: const ValueKey('office-workspace-frame'),
                  decoration: BoxDecoration(
                    color: colors.bg,
                    border: Border.all(color: colors.border),
                    borderRadius: BorderRadius.circular(_maximized ? 0 : 10),
                    boxShadow: const [
                      BoxShadow(color: Color(0x66000000), blurRadius: 28),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(
                            _maximized ? 0 : 10,
                          ),
                          child: Column(
                            children: [
                              SizedBox(
                                height: 38,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: GestureDetector(
                                        key: const ValueKey(
                                          'office-workspace-titlebar',
                                        ),
                                        behavior: HitTestBehavior.opaque,
                                        onDoubleTap: _toggleMaximized,
                                        onPanUpdate: _maximized
                                            ? null
                                            : (event) => setState(() {
                                                _bounds = _fit(
                                                  normal.shift(event.delta),
                                                  area,
                                                );
                                              }),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                          ),
                                          child: Align(
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              widget.projectName.isEmpty ||
                                                      widget.projectName ==
                                                          widget.title
                                                  ? widget.title
                                                  : '${widget.projectName} · ${widget.title}',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: colors.text,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    IconButton.ghost(
                                      key: const ValueKey(
                                        'office-workspace-maximize',
                                      ),
                                      icon: Icon(
                                        _maximized
                                            ? Icons.fullscreen_exit
                                            : Icons.fullscreen,
                                        size: 16,
                                      ),
                                      onPressed: _toggleMaximized,
                                    ),
                                    IconButton.ghost(
                                      key: const ValueKey(
                                        'office-workspace-close',
                                      ),
                                      icon: const Icon(Icons.close, size: 16),
                                      onPressed: widget.onClose,
                                    ),
                                    const SizedBox(width: 6),
                                  ],
                                ),
                              ),
                              Divider(height: 1, color: colors.border),
                              Expanded(child: widget.child),
                            ],
                          ),
                        ),
                      ),
                      if (!_maximized) ...[
                        handle(-1, 0),
                        handle(1, 0),
                        handle(0, -1),
                        handle(0, 1),
                        handle(-1, -1),
                        handle(1, -1),
                        handle(-1, 1),
                        handle(1, 1),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
