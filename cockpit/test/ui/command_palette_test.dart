import 'package:flutter_test/flutter_test.dart';
import 'package:orkest_code/app/core/ui/commands/command_item.dart';

void main() {
  group('AppCommandItem e AppCommandRegistry - Unificação de Ações e Paleta (W02)', () {
    test('matches pesquisa por título e categoria de forma case-insensitive', () {
      const item = AppCommandItem(
        id: 'file.save',
        title: 'Salvar Arquivo',
        category: 'Arquivo',
        onSelected: _noop,
      );

      expect(item.matches('salvar'), isTrue);
      expect(item.matches('arquivo'), isTrue);
      expect(item.matches('SALVAR'), isTrue);
      expect(item.matches('arq salv'), isTrue);
      expect(item.matches('inexistente'), isFalse);
    });

    test('AppCommandRegistry.filter respeita prefixo > e prioriza habilitados', () {
      var saveCalled = false;
      var formatCalled = false;

      final commands = [
        AppCommandItem(
          id: 'edit.format',
          title: 'Formatar Documento',
          category: 'Editar',
          isEnabled: false,
          disabledReason: 'Nenhum editor ativo',
          onSelected: () => formatCalled = true,
        ),
        AppCommandItem(
          id: 'file.save',
          title: 'Salvar Documento',
          category: 'Arquivo',
          isEnabled: true,
          onSelected: () => saveCalled = true,
        ),
        const AppCommandItem(
          id: 'terminal.new',
          title: 'Novo Terminal',
          category: 'Terminal',
          isEnabled: true,
          onSelected: _noop,
        ),
      ];

      final registry = AppCommandRegistry(commands);

      // Com prefixo '>' típico de paleta estilo VSCode
      final filtered = registry.filter('> doc');
      expect(filtered.length, 2);

      // O comando habilitado (Salvar) deve vir antes do desabilitado (Formatar)
      expect(filtered.first.id, 'file.save');
      expect(filtered.first.isEnabled, isTrue);

      expect(filtered.last.id, 'edit.format');
      expect(filtered.last.isEnabled, isFalse);
      expect(filtered.last.disabledReason, 'Nenhum editor ativo');

      // Executa o primeiro
      filtered.first.onSelected();
      expect(saveCalled, isTrue);
      expect(formatCalled, isFalse);
    });

    test('filtro vazio retorna todos os comandos disponíveis', () {
      final commands = [
        const AppCommandItem(
          id: 'cmd.1',
          title: 'Comando 1',
          category: 'Geral',
          onSelected: _noop,
        ),
        const AppCommandItem(
          id: 'cmd.2',
          title: 'Comando 2',
          category: 'Geral',
          onSelected: _noop,
        ),
      ];

      final registry = AppCommandRegistry(commands);
      expect(registry.filter('').length, 2);
      expect(registry.filter('>').length, 2);
      expect(registry.filter('   ').length, 2);
    });
  });
}

void _noop() {}
