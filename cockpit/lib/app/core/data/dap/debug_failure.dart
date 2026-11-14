enum DebugFailureKind { configuration, adapter, transport, request }

/// Protocol/OS details are retained; presentation belongs to the workbench.
class DebugFailure implements Exception {
  const DebugFailure(this.kind, this.detail, {this.command});
  final DebugFailureKind kind;
  final String detail;
  final String? command;
  @override
  String toString() => command == null ? detail : '$command: $detail';
}
