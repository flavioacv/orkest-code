import 'dart:math';

import 'package:cockpit/app/core/ui/themes/themes.dart';
import 'package:cockpit/i18n/strings.g.dart';
import 'package:flutter/widgets.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shad;

typedef OfficeAppearanceLoader =
    Future<Map<String, dynamic>> Function(Map<String, String> parts);

Future<void> showOfficeCharacterEditor(
  BuildContext context, {
  required OfficeAppearanceLoader load,
  required Map<String, String> initialParts,
  required ValueChanged<Map<String, String>> onSave,
}) => shad.showDialog<void>(
  context: context,
  barrierColor: context.colors.scrim,
  builder: (dialogContext) => _OfficeCharacterEditorDialog(
    load: load,
    initialParts: initialParts,
    onSave: onSave,
  ),
);

class _OfficeCharacterEditorDialog extends StatefulWidget {
  const _OfficeCharacterEditorDialog({
    required this.load,
    required this.initialParts,
    required this.onSave,
  });

  final OfficeAppearanceLoader load;
  final Map<String, String> initialParts;
  final ValueChanged<Map<String, String>> onSave;

  @override
  State<_OfficeCharacterEditorDialog> createState() =>
      _OfficeCharacterEditorDialogState();
}

class _OfficeCharacterEditorDialogState
    extends State<_OfficeCharacterEditorDialog> {
  late Map<String, String> _parts;
  Map<String, dynamic>? _data;
  bool _loading = true;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _parts = Map<String, String>.from(widget.initialParts);
    _refresh();
  }

  Future<void> _refresh() async {
    final generation = ++_generation;
    try {
      final result = await widget.load(_parts);
      if (!mounted || generation != _generation) return;
      setState(() {
        _data = result;
        _parts = Map<String, String>.from(
          (result['parts'] as Map).cast<String, String>(),
        );
        _loading = false;
      });
    } catch (_) {
      if (mounted && generation == _generation) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _choose(String key, String value) async {
    setState(() {
      _parts[key] = value;
      _loading = true;
    });
    await _refresh();
  }

  Future<void> _roll() async {
    final seed = Random.secure().nextInt(0x100000000);
    setState(() => _loading = true);
    try {
      final data = await widget.load(<String, String>{'__seed': '$seed'});
      if (!mounted) return;
      setState(() {
        _data = data;
        _parts = Map<String, String>.from(
          (data['parts'] as Map).cast<String, String>(),
        );
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.t.cockpit.officeWorld;
    final colors = context.colors;
    final options = (_data?['options'] as Map?)?.cast<String, dynamic>() ?? {};
    final preview = _data?['preview'] as String?;
    return shad.AlertDialog(
      title: Text(tr.editAppearance),
      content: SizedBox(
        width: 540,
        height: MediaQuery.sizeOf(context).height * 0.68,
        child: _loading && _data == null
            ? const Center(child: shad.CircularProgressIndicator())
            : Column(
                children: [
                  Row(
                    children: [
                      if (preview != null)
                        Container(
                          width: 116,
                          height: 142,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: colors.panel2,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Image.memory(
                            Uri.parse(preview).data!.contentAsBytes(),
                            gaplessPlayback: true,
                            filterQuality: FilterQuality.none,
                            scale: 0.2,
                          ),
                        ),
                      const SizedBox(width: 14),
                      shad.OutlineButton(
                        onPressed: _loading ? null : _roll,
                        child: Text(tr.randomizeAppearance),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView(
                      children: [
                        _group(context, tr.skin, ['skin'], options),
                        _group(context, tr.hair, [
                          'hairStyle',
                          'hair',
                        ], options),
                        _group(context, tr.beard, ['facialHair'], options),
                        _group(context, tr.eyes, ['eyes'], options),
                        _group(context, tr.top, [
                          'topStyle',
                          'top',
                          'topAccent',
                        ], options),
                        _group(context, tr.bottom, [
                          'bottomStyle',
                          'bottom',
                        ], options),
                        _group(context, tr.shoes, ['shoes'], options),
                        _group(context, tr.accessory, [
                          'accessory',
                          'accessoryColor',
                        ], options),
                      ],
                    ),
                  ),
                ],
              ),
      ),
      actions: [
        shad.GhostButton(
          onPressed: () {
            widget.onSave(const <String, String>{});
            Navigator.of(context).pop();
          },
          child: Text(tr.resetAppearance),
        ),
        shad.OutlineButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.t.common.cancel),
        ),
        shad.PrimaryButton(
          onPressed: () {
            widget.onSave(_parts..remove('__seed'));
            Navigator.of(context).pop();
          },
          child: Text(context.t.common.save),
        ),
      ],
    );
  }

  Widget _group(
    BuildContext context,
    String title,
    List<String> keys,
    Map<String, dynamic> options,
  ) {
    final colors = context.colors;
    final children = <Widget>[];
    for (final key in keys) {
      final values =
          (options[key] as List?)?.whereType<String>().toList() ?? [];
      if (values.isEmpty) continue;
      children.add(
        Padding(
          padding: const EdgeInsets.only(top: 5, bottom: 4),
          child: Text(
            _label(key),
            style: TextStyle(color: colors.text2, fontSize: 11),
          ),
        ),
      );
      children.add(
        Wrap(
          spacing: 5,
          runSpacing: 5,
          children: [
            for (final value in values)
              if (value.startsWith('#'))
                GestureDetector(
                  onTap: () => _choose(key, value),
                  child: Container(
                    width: 25,
                    height: 25,
                    decoration: BoxDecoration(
                      color: Color(
                        int.parse(value.substring(1), radix: 16) | 0xFF000000,
                      ),
                      border: Border.all(
                        color: _parts[key] == value
                            ? colors.accent
                            : colors.border,
                        width: _parts[key] == value ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                )
              else
                shad.OutlineButton(
                  onPressed: _loading ? null : () => _choose(key, value),
                  child: Text(_readable(value)),
                ),
          ],
        ),
      );
    }
    if (children.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(color: colors.text, fontWeight: FontWeight.w600),
          ),
          ...children,
        ],
      ),
    );
  }

  String _label(String key) => switch (key) {
    'hairStyle' || 'topStyle' || 'bottomStyle' => 'Estilo',
    'topAccent' => 'Detalhe',
    'accessoryColor' => 'Cor',
    _ => 'Cor',
  };

  String _readable(String value) {
    const labels = {
      'short': 'Curto',
      'buzz': 'Raspado',
      'spiky': 'Espetado',
      'side_part': 'Repartido',
      'curly': 'Cacheado',
      'afro': 'Black power',
      'bob': 'Chanel',
      'long': 'Longo',
      'ponytail': 'Rabo de cavalo',
      'bun': 'Coque',
      'pigtails': 'Maria-chiquinha',
      'mohawk': 'Moicano',
      'bald': 'Careca',
      'wavy': 'Ondulado',
      'tshirt': 'Camiseta',
      'hoodie': 'Moletom',
      'shirt_tie': 'Camisa e gravata',
      'sweater': 'Suéter',
      'jacket': 'Jaqueta',
      'blouse': 'Blusa',
      'polo': 'Polo',
      'pants': 'Calça',
      'shorts': 'Bermuda',
      'skirt': 'Saia',
      'none': 'Nenhum',
      'glasses': 'Óculos',
      'sunglasses': 'Óculos escuros',
      'headphones': 'Fone',
      'cap': 'Boné',
      'beanie': 'Gorro',
      'earrings': 'Brincos',
      'bow': 'Laço',
      'stubble': 'Por fazer',
      'beard': 'Barba',
      'mustache': 'Bigode',
      'goatee': 'Cavanhaque',
    };
    return labels[value] ?? value.replaceAll('_', ' ');
  }
}
