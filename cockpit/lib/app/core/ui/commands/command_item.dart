import 'package:flutter/widgets.dart';

/// Uma ação executável disponível na Command Palette do sistema.
class AppCommandItem {
  const AppCommandItem({
    required this.id,
    required this.title,
    required this.category,
    this.shortcutHint,
    this.icon,
    this.isEnabled = true,
    this.disabledReason,
    required this.onSelected,
  });

  /// Identificador único e estável da ação (ex.: `file.save`, `terminal.new`).
  final String id;

  /// Rótulo visível para o desenvolvedor.
  final String title;

  /// Categoria ou agrupamento do comando (ex.: `File`, `Edit`, `View`, `Terminal`).
  final String category;

  /// Atalho de teclado exibido como hint textual (ex.: `⌘P`, `⇧⌘P`, `⌘S`).
  final String? shortcutHint;

  /// Glifo opcional associado.
  final IconData? icon;

  /// `true` se a ação pode ser executada no contexto atual.
  final bool isEnabled;

  /// Justificativa textual quando [isEnabled] for `false`.
  final String? disabledReason;

  /// Callback disparado ao executar o comando.
  final VoidCallback onSelected;

  /// Retorna `true` se o termo casa com o título ou com a categoria (case-insensitive).
  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    final full = '$category: $title'.toLowerCase();
    if (full.contains(q)) return true;

    // Correspondência de prefixos por palavras
    final words = q.split(RegExp(r'\s+'));
    return words.every((w) => full.contains(w));
  }
}

/// Registro e resolvedor de comandos para a Command Palette.
class AppCommandRegistry {
  AppCommandRegistry(this.commands);

  final List<AppCommandItem> commands;

  /// Filtra e ordena os comandos conforme o termo digitado.
  List<AppCommandItem> filter(String query) {
    final clean = query.startsWith('>') ? query.substring(1).trim() : query.trim();
    if (clean.isEmpty) return List<AppCommandItem>.from(commands);

    final matched = commands.where((cmd) => cmd.matches(clean)).toList();

    // Prioriza comandos habilitados e correspondências no início do título
    matched.sort((a, b) {
      if (a.isEnabled != b.isEnabled) {
        return a.isEnabled ? -1 : 1;
      }
      final qLower = clean.toLowerCase();
      final aStarts = a.title.toLowerCase().startsWith(qLower);
      final bStarts = b.title.toLowerCase().startsWith(qLower);
      if (aStarts != bStarts) {
        return aStarts ? -1 : 1;
      }
      return a.category.compareTo(b.category);
    });

    return matched;
  }
}
