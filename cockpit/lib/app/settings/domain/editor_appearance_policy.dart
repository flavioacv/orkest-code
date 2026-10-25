import 'package:orkest_code/app/core/domain/entities/app_settings.dart';

/// Visibilidade das opções que controlam o editor integrado. O tamanho de
/// código continua exposto quando ainda é a fonte do tamanho do terminal.
abstract final class EditorAppearancePolicy {
  static bool showCodeFont(AppSettings settings) =>
      settings.fileEditorEngine == FileEditorEngine.orkest;

  static bool showCodeSize(AppSettings settings) =>
      settings.fileEditorEngine == FileEditorEngine.orkest ||
      settings.terminalSize == null;
}
