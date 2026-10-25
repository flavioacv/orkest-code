import 'package:orkest_code/app/core/domain/contracts/settings_store.dart';
import 'package:orkest_code/app/core/domain/entities/app_settings.dart';
import 'package:orkest_code/app/core/ui/settings_controller.dart';
import 'package:flutter_test/flutter_test.dart';

class _Store implements SettingsStore {
  AppSettings? saved;

  @override
  Future<AppSettings> load() async => const AppSettings();

  @override
  Future<void> save(AppSettings settings) async => saved = settings;
}

void main() {
  test('Orkest editor is the default and uses the stable engine key', () {
    const settings = AppSettings();
    expect(settings.fileEditorEngine, FileEditorEngine.orkest);
    expect(settings.toJson()['editor.engine'], 'orkest');
    expect(settings.toJson(), isNot(contains('editor.neovim.enabled')));
  });

  test('Neovim engine round-trips with a stable key', () {
    const settings = AppSettings(fileEditorEngine: FileEditorEngine.neovim);
    final json = settings.toJson();
    expect(json['editor.engine'], 'neovim');
    expect(
      AppSettings.fromJson(json).fileEditorEngine,
      FileEditorEngine.neovim,
    );
  });

  test('legacy Neovim boolean migrates and new key takes precedence', () {
    expect(
      AppSettings.fromJson({'editor.neovim.enabled': true}).fileEditorEngine,
      FileEditorEngine.neovim,
    );
    expect(
      AppSettings.fromJson({
        'editor.engine': 'orkest',
        'editor.neovim.enabled': true,
      }).fileEditorEngine,
      FileEditorEngine.orkest,
    );
  });

  test('unknown editor engine falls back to Orkest', () {
    expect(
      AppSettings.fromJson({'editor.engine': 'flack'}).fileEditorEngine,
      FileEditorEngine.orkest,
    );
  });

  test('SettingsController persists Neovim changes', () async {
    final store = _Store();
    final controller = SettingsController(store);
    await controller.load();

    controller.setFileEditorEngine(FileEditorEngine.neovim);
    await Future<void>.delayed(Duration.zero);

    expect(controller.settings.fileEditorEngine, FileEditorEngine.neovim);
    expect(store.saved?.fileEditorEngine, FileEditorEngine.neovim);
  });
}
