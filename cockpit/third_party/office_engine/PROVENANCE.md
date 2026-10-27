# Office engine provenance

Derived from Habblaud, source snapshot `de913185c16bfc5d680aeeec092bcf02a2fcad4b`, copied 2026-10-24.
MIT copyright notices are retained in LICENSE.
Only the runtime import graph and shared contracts are included.
Orkest changes: neutral reception overlay; branding is not loaded into the map.
The adapter and session lifecycle changes live in tool/office_world.
Local contract changes: Provider accepts arbitrary descriptive identifiers, and
Sim.accounts preserves the supplied provider instead of reducing it to Codex.
Harness identity does not select simulation behavior. The native exporter reads
the same layout/art sources to generate collision and furniture animation data.
