import 'package:orkest_code/app/core/domain/entities/harness.dart';

// Process identity is informative metadata. It is never a condition for
// accepting activities or selecting animation behavior.
class OfficeHarnessIdentity {
  const OfficeHarnessIdentity(this.id, this.label, this.source);
  final String id, label, source;

  static OfficeHarnessIdentity resolve(HarnessKind? process, String? reported) {
    final spec = process == null ? null : HarnessCatalog.getSpec(process);
    if (spec != null) {
      return OfficeHarnessIdentity(spec.kind.name, spec.label, 'process');
    }
    if (reported != null &&
        RegExp(r'^[A-Za-z0-9_.:/-]{1,80}$').hasMatch(reported)) {
      return OfficeHarnessIdentity(reported, reported, 'reported');
    }
    return const OfficeHarnessIdentity('orkest', 'Orkest', 'unknown');
  }

  String get short {
    final words = label
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty)
        .toList();
    final text = words.length > 1
        ? words.take(2).map((s) => s[0]).join()
        : label;
    return text.substring(0, text.length > 2 ? 2 : text.length).toUpperCase();
  }
}
