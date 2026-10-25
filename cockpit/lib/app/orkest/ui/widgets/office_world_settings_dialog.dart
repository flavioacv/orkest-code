import 'package:orkest_code/app/core/ui/settings_controller.dart';
import 'package:orkest_code/app/core/ui/themes/themes.dart';
import 'package:orkest_code/i18n/strings.g.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shad;

Future<void> showOfficeWorldSettings(BuildContext context) {
  final settings = context.read<SettingsController>();
  return shad.showDialog<void>(
    context: context,
    barrierColor: context.colors.scrim,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, refresh) {
        final tr = context.t.orkest.officeWorld;
        final prefs = settings.settings;
        void update({
          String? theme,
          bool? showNames,
          String? bubbles,
          String? liveliness,
          String? daylight,
          bool? sounds,
          double? soundVolume,
          bool? soundAlerts,
          bool? soundKeys,
          bool? soundElevator,
          bool? soundSocial,
        }) {
          settings.setOfficeWorldOptions(
            theme: theme,
            showNames: showNames,
            bubbles: bubbles,
            liveliness: liveliness,
            daylight: daylight,
            sounds: sounds,
            soundVolume: soundVolume,
            soundAlerts: soundAlerts,
            soundKeys: soundKeys,
            soundElevator: soundElevator,
            soundSocial: soundSocial,
          );
          refresh(() {});
        }

        return shad.AlertDialog(
          title: Text(
            tr.appearance,
            style: context.typo.title.copyWith(
              fontSize: 16,
              color: context.colors.text,
            ),
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _OfficeChoiceRow(
                    label: tr.officeTheme,
                    selected: prefs.officeTheme,
                    options: [
                      ('auto', tr.themeAuto),
                      ('none', tr.themeNone),
                      ('christmas', tr.themeChristmas),
                      ('halloween', tr.themeHalloween),
                    ],
                    onSelected: (value) => update(theme: value),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          tr.showNames,
                          style: context.typo.body.copyWith(
                            color: context.colors.text,
                          ),
                        ),
                      ),
                      shad.Switch(
                        value: prefs.officeShowNames,
                        onChanged: (value) => update(showNames: value),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _OfficeChoiceRow(
                    label: tr.bubbles,
                    selected: prefs.officeBubbles,
                    options: [
                      ('all', tr.bubblesAll),
                      ('important', tr.bubblesImportant),
                      ('none', tr.bubblesNone),
                    ],
                    onSelected: (value) => update(bubbles: value),
                  ),
                  const SizedBox(height: 12),
                  _OfficeChoiceRow(
                    label: tr.movement,
                    selected: prefs.officeLiveliness,
                    options: [
                      ('calm', tr.movementCalm),
                      ('normal', tr.movementNormal),
                      ('lively', tr.movementLively),
                    ],
                    onSelected: (value) => update(liveliness: value),
                  ),
                  const SizedBox(height: 12),
                  _OfficeChoiceRow(
                    label: tr.daylight,
                    selected: prefs.officeDaylight,
                    options: [
                      ('auto', tr.daylightAuto),
                      ('day', tr.daylightDay),
                      ('night', tr.daylightNight),
                    ],
                    onSelected: (value) => update(daylight: value),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          tr.sounds,
                          style: context.typo.body.copyWith(
                            color: context.colors.text,
                          ),
                        ),
                      ),
                      shad.Switch(
                        value: prefs.officeSounds,
                        onChanged: (value) => update(sounds: value),
                      ),
                    ],
                  ),
                  if (prefs.officeSounds) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${tr.soundVolume}: ${prefs.officeSoundVolume.round()}%',
                          ),
                        ),
                        SizedBox(
                          width: 190,
                          child: shad.Slider(
                            value: shad.SliderValue.single(
                              prefs.officeSoundVolume,
                            ),
                            min: 0,
                            max: 100,
                            onChanged: (value) =>
                                update(soundVolume: value.value),
                          ),
                        ),
                      ],
                    ),
                    _OfficeSoundToggle(
                      label: tr.soundAlerts,
                      value: prefs.officeSoundAlerts,
                      onChanged: (v) => update(soundAlerts: v),
                    ),
                    _OfficeSoundToggle(
                      label: tr.soundKeys,
                      value: prefs.officeSoundKeys,
                      onChanged: (v) => update(soundKeys: v),
                    ),
                    _OfficeSoundToggle(
                      label: tr.soundElevator,
                      value: prefs.officeSoundElevator,
                      onChanged: (v) => update(soundElevator: v),
                    ),
                    _OfficeSoundToggle(
                      label: tr.soundSocial,
                      value: prefs.officeSoundSocial,
                      onChanged: (v) => update(soundSocial: v),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            shad.PrimaryButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(context.t.common.gotIt),
            ),
          ],
        );
      },
    ),
  );
}

class _OfficeSoundToggle extends StatelessWidget {
  const _OfficeSoundToggle({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 5),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: context.typo.body.copyWith(color: context.colors.text2),
          ),
        ),
        shad.Switch(value: value, onChanged: onChanged),
      ],
    ),
  );
}

class _OfficeChoiceRow extends StatelessWidget {
  const _OfficeChoiceRow({
    required this.label,
    required this.selected,
    required this.options,
    required this.onSelected,
  });

  final String label;
  final String selected;
  final List<(String, String)> options;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: context.typo.body.copyWith(color: context.colors.text),
      ),
      const SizedBox(height: 6),
      Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final option in options)
            option.$1 == selected
                ? shad.PrimaryButton(
                    onPressed: () => onSelected(option.$1),
                    child: Text(option.$2),
                  )
                : shad.OutlineButton(
                    onPressed: () => onSelected(option.$1),
                    child: Text(option.$2),
                  ),
        ],
      ),
    ],
  );
}
