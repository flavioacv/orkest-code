import 'dart:convert';
import 'dart:typed_data';

import 'package:orkest_code/app/orkest/domain/entities/db_connection.dart';
import 'package:orkest_code/app/orkest/domain/entities/db_result.dart';
import 'package:orkest_code/app/core/ui/file_operation_error_message.dart';
import 'package:orkest_code/app/orkest/domain/entities/dbq_document.dart';
import 'package:orkest_code/app/orkest/domain/entities/file_view.dart';
import 'package:orkest_code/app/orkest/domain/entities/sql_statements.dart';
import 'package:orkest_code/app/orkest/domain/services/db_export_service.dart';
import 'package:orkest_code/app/orkest/domain/services/db_row_edit_service.dart';
import 'package:orkest_code/app/orkest/ui/session/file_viewer_session.dart';
import 'package:orkest_code/app/orkest/ui/widgets/db_engine_icon.dart';
import 'package:orkest_code/app/orkest/ui/viewmodels/orkest_viewmodel.dart';
import 'package:orkest_code/app/orkest/ui/viewmodels/database_viewmodel.dart';
import 'package:orkest_code/app/core/ui/menu/editor_menu_bridge.dart';
import 'package:orkest_code/app/core/ui/themes/themes.dart';
import 'package:orkest_code/app/core/ui/widgets/app_menu.dart';
import 'package:orkest_code/app/core/ui/widgets/code_editing_controller.dart';
import 'package:orkest_code/app/core/ui/widgets/code_highlight.dart';
import 'package:orkest_code/app/orkest/ui/widgets/code_editor.dart';
import 'package:orkest_code/app/core/ui/widgets/hover_tap.dart';
import 'package:orkest_code/i18n/strings.g.dart';
import 'package:flutter/services.dart'
    show Clipboard, ClipboardData, LogicalKeyboardKey;
import 'package:flutter_modular/flutter_modular.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

/// Tab de um arquivo `.dbq` (plano 51): editor SQL em cima, grid de resultado
/// embaixo, split arrastável. O arquivo persiste conexão/limite como
/// frontmatter (`-- db:` / `-- limit:`) — o editor mostra **só o SQL**; a
/// conexão é escolhida no popup da top bar. File-watch externo (agente salvou)
/// re-executa a query automaticamente.
class DbQueryView extends StatefulWidget {
  const DbQueryView({
    super.key,
    required this.session,
    required this.active,
    required this.focused,
    required this.workspaceRoot,
    required this.onSave,
    this.databaseViewModel,
    this.menuBridge,
  });

  final FileViewerSession session;
  final bool active;
  final bool focused;

  /// Raiz do workspace da tab — resolve paths sqlite relativos e o registry.
  final String workspaceRoot;

  /// Grava o conteúdo completo (frontmatter + SQL) no disco.
  final Future<bool> Function(String content) onSave;

  /// ViewModel explícito (útil para testes de widgets sem modular routing).
  final DatabaseViewModel? databaseViewModel;
  final EditorMenuBridge? menuBridge;

  @override
  State<DbQueryView> createState() => _DbQueryViewState();
}

class _DbQueryViewState extends State<DbQueryView> {
  late final CodeEditingController _sql;
  final FocusNode _focus = FocusNode();
  EditorMenuBridge? _menuBridge;

  /// Conteúdo do disco como o conhecemos (baseline de dirty/discard).
  late String _baseline;
  String? _connName;
  int? _limit;

  bool _running = false;
  bool _discardRequested = false;
  bool _updating = false;
  int _executionGeneration = 0;

  /// Último `session.loading` visto. A aba nasce em `loading` com a `view`
  /// vazia e o conteúdo chega depois (async, local ou remoto) — sem este
  /// marcador a **chegada** do arquivo seria lida como escrita externa e
  /// dispararia o auto-run, executando o `.dbq` inteiro (DDL/INSERT incluso)
  /// só por abrir a aba.
  late bool _lastLoading;

  /// Estado de view (resultado, split, larguras…) — mora no
  /// [DatabaseViewModel] pra sobreviver ao re-mount quando a tab muda de pane
  /// (o widget State morre; a session e este side-car não).
  late final DbTabViewState _view;

  @override
  void initState() {
    super.initState();
    final vm = widget.databaseViewModel ?? context.read<DatabaseViewModel>();
    _view = vm.tabStateFor(widget.session.id);
    _lastLoading = widget.session.loading;
    _baseline = _diskText();
    final doc = DbqDocument.parse(_baseline);
    _connName = doc.db;
    _limit = doc.limit;
    _sql = CodeEditingController(text: doc.sql, language: 'sql');
    _sql.addListener(_onEdited);
    widget.session.addListener(_onSession);
    widget.session.saveDraft = _save;
    // Untitled nasce "unsaved" → acende a bolinha da tab de imediato.
    if (widget.session.scratch) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.session.setDirty(true);
      });
    }
    // Garante o registro de conexões carregado mesmo sem o painel aberto.
    Future.microtask(
      () => vm.setWorkspace(widget.session.projectId, widget.workspaceRoot),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _menuBridge = widget.menuBridge ?? context.read<EditorMenuBridge>();
  }

  @override
  void dispose() {
    _menuBridge?.clear(this);
    widget.session.removeListener(_onSession);
    if (widget.session.saveDraft == _save) widget.session.saveDraft = null;
    _sql.removeListener(_onEdited);
    _sql.dispose();
    _focus.dispose();
    super.dispose();
  }

  String _diskText() => switch (widget.session.view) {
    FileViewText(:final text) => text,
    FileViewMarkdown(:final text) => text,
    _ => '',
  };

  DbqDocument get _current =>
      DbqDocument(db: _connName, limit: _limit, sql: _sql.text);

  bool get _dirty {
    // Untitled: sempre "unsaved" até o primeiro save (vira arquivo real).
    if (widget.session.scratch) return true;
    final disk = DbqDocument.parse(_baseline);
    return disk.sql != _sql.text ||
        disk.db != _connName ||
        disk.limit != _limit;
  }

  void _onEdited() => _syncDirty();

  void _syncDirty() {
    widget.session.setDirty(_dirty);
    // Repinta o footer/menu ("unsaved" e Save habilitado).
    if (mounted) setState(() {});
  }

  /// Mudança vinda do disco (file watcher / rename): se o buffer não está
  /// sujo, adota o novo conteúdo e **re-executa** (decisão H — o agente salvou
  /// e o humano vê o resultado novo sem tocar em nada).
  void _onSession() {
    if (widget.session.scratch) return; // untitled: nada vem do disco
    final text = _diskText();
    // Fim do carregamento inicial: adota o conteúdo como baseline e **não**
    // executa. Abrir arquivo nunca roda SQL.
    if (_lastLoading && !widget.session.loading) {
      _lastLoading = false;
      _adopt(text);
      return;
    }
    _lastLoading = widget.session.loading;
    if (text == _baseline) return;
    if (widget.session.dirty) return; // edição local vence; não sobrescreve
    _adopt(text);
    if (_connName != null) _run(auto: true);
  }

  /// Traz o conteúdo do disco pro buffer (baseline + frontmatter + SQL), sem
  /// executar nada.
  void _adopt(String text) {
    final doc = DbqDocument.parse(text);
    setState(() {
      _baseline = text;
      _connName = doc.db;
      _limit = doc.limit;
      if (_sql.text != doc.sql) _sql.text = doc.sql;
    });
  }

  Future<bool> _save() async {
    if (!_dirty) return true;
    final content = _current.serialize();
    // Untitled: pede o nome e materializa o arquivo (VSCode-style).
    if (widget.session.scratch) {
      final name = await _promptName();
      if (name == null || !mounted) return false;
      final result = await context.read<OrkestViewModel>().saveScratchAs(
        widget.session.id,
        name,
        content,
      );
      if (!mounted) return false;
      final error = result.fold((_) => null, (f) => f);
      if (error != null) {
        _showSaveError(fileOperationErrorMessage(context, error));
        return false;
      }
      // saveScratchAs já retargou a sessão e limpou o scratch; baseline agora
      // é o conteúdo salvo.
      setState(() => _baseline = content);
      _syncDirty();
      return true;
    }
    final ok = await widget.onSave(content);
    if (!mounted) return ok;
    if (ok) {
      _baseline = content;
      _syncDirty();
    }
    return ok;
  }

  /// Prompt de nome do arquivo (só o basename; `.dbq` é anexado pela VM).
  Future<String?> _promptName() {
    final ctrl = TextEditingController(text: 'query.dbq');
    return showDialog<String>(
      context: context,
      builder: (context) {
        final colors = context.colors;
        return AlertDialog(
          title: Text(
            context.t.orkest.dbQueryView.saveQueryAs,
            style: context.typo.title.copyWith(
              fontSize: 15,
              color: colors.text,
            ),
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: TextField(
              controller: ctrl,
              autofocus: true,
              style: context.typo.mono.copyWith(
                fontSize: 12.5,
                color: colors.text,
              ),
              border: Border.all(color: colors.border),
              borderRadius: BorderRadius.circular(6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              onSubmitted: (v) => Navigator.of(context).pop(v),
            ),
          ),
          actions: [
            GhostButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(context.t.common.cancel),
            ),
            PrimaryButton(
              onPressed: () => Navigator.of(context).pop(ctrl.text),
              child: Text(context.t.common.save),
            ),
          ],
        );
      },
    );
  }

  void _showSaveError(String message) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          context.t.orkest.dbQueryView.couldNotSave,
          style: context.typo.title.copyWith(
            fontSize: 15,
            color: context.colors.text,
          ),
        ),
        content: Text(
          message,
          style: context.typo.body.copyWith(
            fontSize: 13,
            color: context.colors.text2,
          ),
        ),
        actions: [
          PrimaryButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.t.common.ok),
          ),
        ],
      ),
    );
  }

  void _discard() {
    final doc = DbqDocument.parse(_baseline);
    setState(() {
      _connName = doc.db;
      _limit = doc.limit;
      _sql.text = doc.sql;
    });
    _syncDirty();
  }

  Future<void> _run({bool auto = false}) async {
    if (_running || _updating) return;
    final vm = widget.databaseViewModel ?? context.read<DatabaseViewModel>();
    final connName = _connName;
    if (connName == null) return; // topbar mostra "Select database"

    // Arquivo real: Run salva primeiro (o arquivo é a fonte de verdade que o
    // agente lê). Untitled: executa o buffer direto, SEM forçar save — só
    // materializa em disco quando o usuário mandar salvar.
    if (!widget.session.scratch) {
      if (_dirty && !await _save()) return;
      if (!mounted) return;
    }

    // Semântica dos clients (DataGrip/DBeaver): Run = statement sob o
    // cursor; com seleção = os statements que ela TOCA (expandidos — nunca
    // fragmento literal); auto (watch/agente salvou) = o arquivo inteiro em
    // sequência, resultado do último.
    final statements = splitSqlStatements(_sql.text);
    if (statements.isEmpty) return;
    final sel = _sql.selection;
    final List<SqlStatement> toRun;
    if (auto) {
      toRun = statements;
    } else if (sel.isValid && !sel.isCollapsed) {
      toRun = statementsInRange(statements, sel.start, sel.end);
    } else {
      final at = statementAt(statements, sel.isValid ? sel.baseOffset : 0);
      toRun = at == null ? const [] : [at];
    }
    if (toRun.isEmpty) return;

    final gen = ++_executionGeneration;
    setState(() {
      _running = true;
      _discardRequested = false;
      _view.error = null;
    });
    try {
      final result = await vm.service.runStatements(
        workspaceRoot: widget.workspaceRoot,
        workspaceId: widget.session.projectId,
        connName: connName,
        statements: [for (final s in toRun) s.text],
        limit: _limit,
        isCancelled: () => _discardRequested || gen != _executionGeneration,
      );
      if (!mounted) return;
      if (_discardRequested || gen != _executionGeneration) {
        // Descarte explícito: rejeita resultado tardio
        return;
      }
      setState(() {
        _view.lastExecutedSql = toRun.last.text;
        _view.executedConnName = connName;
        _view.result = result;
        _view.baseWidths = _computeWidths(result);
        _view.manualWidths = null;
        _view.selectedRow = null;
      });
    } on DbQueryException catch (e) {
      if (!mounted) return;
      if (_discardRequested || gen != _executionGeneration) {
        // Erro tardio de operação descartada rejeitado
        return;
      }
      setState(() => _view.error = e);
    } finally {
      if (gen == _executionGeneration) {
        if (mounted) {
          setState(() {
            _running = false;
            _discardRequested = false;
          });
        } else {
          _running = false;
          _discardRequested = false;
        }
      }
    }
  }

  Future<void> _pickConnection(BuildContext anchor) async {
    if (_running || _updating) return;
    final vm = widget.databaseViewModel ?? context.read<DatabaseViewModel>();
    // Só engines SQL — a tab `.dbq` executa SQL; Redis/Mongo têm views
    // próprias (browse). Conexões com `agents: false` aparecem normalmente:
    // o gate é só do caminho da CLI, a GUI vê tudo.
    final conns = [
      for (final c in vm.connections)
        if (c.engine.isSql) c,
    ];
    final picked = await showAppMenu<String>(
      anchor,
      items: [
        for (final c in conns)
          AppMenuItem(
            value: c.name,
            label: '${c.name} · ${c.engine.label}',
            leading: DbEngineIcon(c.engine, size: 15),
            selected: c.name == _connName,
          ),
        if (conns.isEmpty)
          AppMenuItem(
            value: '',
            label: context.t.orkest.dbQueryView.noSqlConnections,
            enabled: false,
          ),
      ],
    );
    if (picked == null || picked.isEmpty || !mounted) return;
    setState(() => _connName = picked);
    // Persiste a escolha no frontmatter e já executa (fluxo do mockup).
    if (await _save()) await _run();
  }

  void _syncMenuBridge() {
    final bridge = _menuBridge;
    if (bridge == null) return;
    if (widget.focused) {
      bridge.publish(
        owner: this,
        canSave: _dirty,
        canDiscard: _dirty,
        canFormat: false,
        onSave: _save,
        onDiscard: _discard,
        onFormat: () {},
      );
    } else {
      bridge.clear(this);
    }
  }

  DbConnection? get _conn {
    final vm = widget.databaseViewModel ?? context.read<DatabaseViewModel>();
    for (final c in vm.connections) {
      if (c.name == _connName) return c;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    if (widget.databaseViewModel == null) {
      context.watch<DatabaseViewModel>(); // conexões (chip/picker) ao vivo
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncMenuBridge();
    });
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyS, meta: true): _save,
        const SingleActivator(LogicalKeyboardKey.keyS, control: true): _save,
        const SingleActivator(LogicalKeyboardKey.enter, meta: true): _run,
        const SingleActivator(LogicalKeyboardKey.enter, control: true): _run,
      },
      child: ColoredBox(
        color: colors.panel,
        child: Column(
          children: [
            _topBar(context),
            Expanded(
              child: LayoutBuilder(
                builder: (context, box) {
                  final editorH = (box.maxHeight * _view.split).clamp(
                    90.0,
                    box.maxHeight - 110,
                  );
                  return Column(
                    children: [
                      SizedBox(
                        height: editorH,
                        child: CodeEditor(controller: _sql, focusNode: _focus),
                      ),
                      MouseRegion(
                        cursor: SystemMouseCursors.resizeUpDown,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onVerticalDragUpdate: (d) => setState(() {
                            _view.split =
                                ((editorH + d.delta.dy) / box.maxHeight).clamp(
                                  0.12,
                                  0.85,
                                );
                          }),
                          child: SizedBox(
                            height: 7,
                            child: Center(
                              child: Container(
                                height: 1,
                                color: colors.border2,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(child: _resultArea(context)),
                    ],
                  );
                },
              ),
            ),
            _footer(context),
          ],
        ),
      ),
    );
  }

  Widget _topBar(BuildContext context) {
    final colors = context.colors;
    final typo = context.typo;
    // O botão Run troca de fundo conforme está habilitado (accent) ou não
    // (panel3), então o texto/ícone precisa sair do fundo efetivo. Fixo em
    // branco, o estado desabilitado ficava ilegível no tema claro.
    final runBg = _connName == null ? colors.panel3 : colors.accent;
    final runFg = onColor(runBg);
    final conn = _conn;
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Row(
        children: [
          conn == null
              ? Icon(Icons.storage, size: 14, color: colors.accent)
              : DbEngineIcon(conn.engine, size: 14),
          const SizedBox(width: 8),
          Builder(
            builder: (anchor) => HoverTap(
              onTap: _running || _updating ? null : () => _pickConnection(anchor),
              color: colors.panel3,
              borderRadius: const BorderRadius.all(Radius.circular(4)),
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _connName ?? context.t.orkest.dbQueryView.selectDatabase,
                    style: typo.label.copyWith(
                      fontSize: 11,
                      color: _connName == null ? colors.warn : colors.text2,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.keyboard_arrow_down,
                    size: 12,
                    color: colors.text3,
                  ),
                ],
              ),
            ),
          ),
          if (conn != null) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                border: Border.all(color: colors.border2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                conn.engine.label,
                style: typo.label.copyWith(fontSize: 10, color: colors.text3),
              ),
            ),
          ],
          const Spacer(),
          HoverTap(
            onTap: _running || _updating || _connName == null ? null : _run,
            color: runBg,
            hoverColor: colors.accent.withValues(alpha: 0.85),
            borderRadius: const BorderRadius.all(Radius.circular(5)),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _running ? Icons.hourglass_top : Icons.play_arrow,
                  size: 13,
                  color: runFg,
                ),
                const SizedBox(width: 4),
                ListenableBuilder(
                  listenable: _sql,
                  builder: (context, _) {
                    final sel = _sql.selection;
                    final hasSel = sel.isValid && !sel.isCollapsed;
                    final tr = context.t.orkest.dbQueryView;
                    return Text(
                      _running
                          ? (_discardRequested ? 'Descartando...' : tr.running)
                          : _updating
                          ? 'Atualizando...'
                          : hasSel
                          ? tr.runSelection
                          : tr.run,
                      style: typo.label.copyWith(fontSize: 11.5, color: runFg),
                    );
                  },
                ),
                const SizedBox(width: 6),
                Text(
                  '⌘↵',
                  style: typo.label.copyWith(
                    fontSize: 9.5,
                    color: runFg.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          if (_running) ...[
            const SizedBox(width: 6),
            HoverTap(
              key: const ValueKey('db-query-cancel'),
              onTap: _discardRequested
                  ? null
                  : () {
                      setState(() => _discardRequested = true);
                    },
              color: colors.panel3,
              borderRadius: const BorderRadius.all(Radius.circular(5)),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.stop, size: 13, color: colors.error),
                  const SizedBox(width: 4),
                  Text(
                    _discardRequested ? 'Descartando...' : 'Descartar resultado',
                    style: typo.label.copyWith(
                      fontSize: 11,
                      color: _discardRequested ? colors.text4 : colors.error,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _resultArea(BuildContext context) {
    final colors = context.colors;
    final typo = context.typo;
    final error = _view.error;
    if (error != null) {
      return Container(
        alignment: Alignment.topLeft,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.error_outline, size: 14, color: colors.error),
                const SizedBox(width: 6),
                Text(
                  error.kind,
                  style: typo.label.copyWith(
                    fontSize: 11.5,
                    color: colors.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SelectableText(
              error.message,
              style: typo.mono.copyWith(fontSize: 12, color: colors.text2),
            ),
          ],
        ),
      );
    }
    final result = _view.result;
    final tr = context.t.orkest.dbQueryView;
    if (result == null) {
      return Center(
        child: Text(
          _connName == null ? tr.pickDatabaseHint : tr.runQueryHint,
          style: typo.label.copyWith(fontSize: 12, color: colors.text3),
        ),
      );
    }
    if (result.affectedRows != null) {
      return Center(
        child: Text(
          tr.rowsAffected(n: result.affectedRows!),
          style: typo.label.copyWith(fontSize: 12.5, color: colors.text2),
        ),
      );
    }
    if (result.rows.isEmpty) {
      return Center(
        child: Text(
          tr.noRows,
          style: typo.label.copyWith(fontSize: 12, color: colors.text3),
        ),
      );
    }
    if (_view.asJson) return _JsonView(result: result);
    final baseWidths = _view.baseWidths.isEmpty ? _computeWidths(result) : _view.baseWidths;
    return _DbGrid(
      result: result,
      baseWidths: baseWidths,
      manualWidths: _view.manualWidths,
      selectedRow: _view.selectedRow,
      onSelectRow: (i) => setState(() => _view.selectedRow = i),
      onEditCell: (row, col, val) => _editCell(row, col, val),
      // Primeiro drag congela as larguras visuais atuais → o arrasto vira
      // 1:1 com o mouse (sem a re-escala proporcional "correndo" na frente).
      onResizeStart: (effective) => _view.manualWidths ??= [...effective],
      onResize: (col, delta) => setState(() {
        final w = _view.manualWidths;
        if (w == null) return;
        w[col] = (w[col] + delta).clamp(60.0, 2000.0);
      }),
    );
  }

  Future<void> _editCell(int rowIndex, int colIndex, Object? currentValue) async {
    if (_running || _updating) return;

    final initialResult = _view.result;
    final initialConnName = _connName;
    final initialSessionId = widget.session.id;
    final initialWorkspaceRoot = widget.workspaceRoot;
    final initialSql = _view.lastExecutedSql;
    final executedConnName = _view.executedConnName;

    if (initialResult == null) return;

    if (initialSql == null || initialSql.trim().isEmpty || executedConnName == null) {
      _showEditError(
        'Edição indisponível: resultado sem registro de proveniência (SQL ou conexão). Execute a consulta para habilitar a edição.',
      );
      return;
    }

    if (initialConnName != executedConnName) {
      _showEditError(
        'Edição recusada: a conexão selecionada ("$initialConnName") diverge da conexão utilizada na consulta ("$executedConnName"). Recarregue a consulta para editar.',
      );
      return;
    }

    bool isSnapshotValid() {
      if (!mounted) return false;
      if (_view.result != initialResult) return false;
      if (_view.lastExecutedSql != initialSql) return false;
      if (_view.executedConnName != executedConnName) return false;
      if (_connName != initialConnName) return false;
      if (widget.session.id != initialSessionId) return false;
      if (widget.workspaceRoot != initialWorkspaceRoot) return false;
      return true;
    }

    setState(() => _updating = true);
    try {
      final result = _view.result;
      if (result == null || rowIndex >= result.rows.length || colIndex >= result.columns.length) return;
      final col = result.columns[colIndex];
      final conn = _conn;
      if (conn == null) {
        _showEditError('Nenhuma conexão de banco ativa.');
        return;
      }

      final querySql = initialSql;

      const editService = DbRowEditService();
      final target = editService.extractEditableTable(querySql);
      if (target == null) {
        _showEditError(
          'Edição restrita a consultas SELECT diretas de uma única tabela sem aliases, expressões ou subconsultas.',
        );
        return;
      }

      final vm = widget.databaseViewModel ?? context.read<DatabaseViewModel>();
      final tableCols = await vm.columns(conn, target.table, schema: target.schema);
      if (!isSnapshotValid() || !mounted) return;

      final pkCols = [for (final c in tableCols) if (c.primaryKey) c.name];
      if (pkCols.isEmpty) {
        _showEditError(
          'Edição recusada: a tabela "${target.table}" precisa ter chave primária (PK) definida para atualização segura.',
        );
        return;
      }

      final missingPks = [
        for (final pk in pkCols)
          if (!result.columns.any((c) => c.name.toLowerCase() == pk.toLowerCase())) pk
      ];
      if (missingPks.isNotEmpty) {
        _showEditError(
          'Edição recusada: a consulta precisa incluir a(s) coluna(s) de chave primária (${missingPks.join(", ")}) no SELECT para permitir atualização.',
        );
        return;
      }

      final matchingTableCol = tableCols.cast<SchemaColumn?>().firstWhere(
        (c) => c?.name.toLowerCase() == col.name.toLowerCase(),
        orElse: () => null,
      );
      if (matchingTableCol == null) {
        _showEditError(
          'Edição recusada: a coluna "${col.name}" é uma expressão calculada ou não pertence à tabela "${target.table}".',
        );
        return;
      }

      final ctrl = TextEditingController(text: currentValue?.toString() ?? '');
      ({String text, bool isNull})? inputData;
      try {
        var isNullSelected = currentValue == null;
        inputData = await showDialog<({String text, bool isNull})>(
          context: context,
          builder: (context) => StatefulBuilder(
            builder: (context, setDialogState) {
              final colors = context.colors;
              return AlertDialog(
                title: Text(
                  'Editar valor de ${col.name}',
                  style: context.typo.title.copyWith(fontSize: 14),
                ),
                content: SizedBox(
                  width: 320,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        key: const ValueKey('db-grid-cell-edit-input'),
                        controller: ctrl,
                        enabled: !isNullSelected,
                        autofocus: !isNullSelected,
                        border: Border.all(color: colors.border),
                        borderRadius: BorderRadius.circular(4),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        onSubmitted: (v) => Navigator.of(context).pop((text: v, isNull: isNullSelected)),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Checkbox(
                            key: const ValueKey('db-grid-cell-edit-null'),
                            state: isNullSelected
                                ? CheckboxState.checked
                                : CheckboxState.unchecked,
                            onChanged: (v) {
                              setDialogState(() {
                                isNullSelected = v == CheckboxState.checked;
                              });
                            },
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () {
                              setDialogState(() {
                                isNullSelected = !isNullSelected;
                              });
                            },
                            child: Text(
                              'Definir como NULL',
                              style: context.typo.label.copyWith(fontSize: 12, color: colors.text2),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                actions: [
                  GhostButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(context.t.common.cancel),
                  ),
                  PrimaryButton(
                    key: const ValueKey('db-grid-cell-edit-save'),
                    onPressed: () => Navigator.of(context).pop((text: ctrl.text, isNull: isNullSelected)),
                    child: Text(context.t.common.save),
                  ),
                ],
              );
            },
          ),
        );
      } finally {
        ctrl.dispose();
      }

      if (inputData == null || !isSnapshotValid()) return;

      final typedNewVal = editService.parseValueForColumn(
        rawInput: inputData.text,
        columnType: matchingTableCol.type,
        isNull: inputData.isNull,
        currentValue: currentValue,
      );

      if (typedNewVal == currentValue) return;

      final pkValues = <Object?>[];
      for (final pk in pkCols) {
        final pkIdx = result.columns.indexWhere((c) => c.name.toLowerCase() == pk.toLowerCase());
        pkValues.add(result.rows[rowIndex][pkIdx]);
      }

      final updateSql = editService.generateOptimisticUpdateSql(
        engine: conn.engine,
        table: target.table,
        schema: target.schema,
        pkColumns: pkCols,
        pkValues: pkValues,
        modifiedColumn: matchingTableCol.name,
        oldValue: currentValue,
        newValue: typedNewVal,
      );

      final res = await vm.service.query(
        workspaceRoot: widget.workspaceRoot,
        workspaceId: widget.session.projectId,
        connName: conn.name,
        sql: updateSql,
        dml: true,
      );

      if (!isSnapshotValid()) return;

      if (res.affectedRows == 0) {
        _showEditError(
          'Falha na concorrência: nenhum registro atualizado (0 linhas afetadas). O dado pode ter sido alterado ou excluído por outro processo.',
        );
        return;
      }

      if (res.affectedRows == null) {
        _showEditError(
          'Resultado indeterminado: o driver não confirmou o número de linhas afetadas. A mudança pode ter sido aplicada no banco de dados; recarregue a consulta antes de tentar novamente.',
        );
        return;
      }

      if (res.affectedRows! > 1) {
        _showEditError(
          'Atenção: o driver reportou mais de uma linha alterada (${res.affectedRows}). Verifique o banco de dados e recarregue a consulta.',
        );
        return;
      }

      // res.affectedRows == 1 estritamente garantido
      setState(() {
        result.rows[rowIndex][colIndex] = typedNewVal;
      });
    } on DbEditException catch (e) {
      if (mounted) _showEditError(e.message);
    } on DbQueryException catch (e) {
      if (mounted) _showEditError(e.message);
    } catch (e) {
      if (mounted) _showEditError('Erro ao persistir alteração: $e');
    } finally {
      if (mounted) {
        setState(() => _updating = false);
      } else {
        _updating = false;
      }
    }
  }

  void _showEditError(String message) {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Não foi possível editar',
          style: context.typo.title.copyWith(fontSize: 14, color: context.colors.error),
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Text(
            message,
            style: context.typo.body.copyWith(fontSize: 12.5, color: context.colors.text2),
          ),
        ),
        actions: [
          PrimaryButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.t.common.ok),
          ),
        ],
      ),
    );
  }

  Future<void> _showExportMenu(BuildContext anchor, DbResult result) async {
    final action = await showAppMenu<String>(
      anchor,
      items: const [
        AppMenuItem(
          value: 'csv',
          label: 'Copiar como CSV (com cabeçalhos)',
          icon: Icons.table_view,
        ),
        AppMenuItem(
          value: 'json',
          label: 'Copiar como JSON formatado',
          icon: Icons.code,
        ),
      ],
    );
    if (action == null || !mounted) return;
    const exportService = DbExportService();
    if (action == 'csv') {
      final csv = exportService.exportCsv(result);
      await Clipboard.setData(ClipboardData(text: csv));
    } else if (action == 'json') {
      final json = exportService.exportJson(result, pretty: true);
      await Clipboard.setData(ClipboardData(text: json));
    }
  }

  Widget _footer(BuildContext context) {
    final colors = context.colors;
    final typo = context.typo;
    final tr = context.t.orkest.dbQueryView;
    final result = _view.result;
    final info = StringBuffer();
    if (result != null && result.affectedRows == null) {
      info.write(tr.rowsFooter(n: result.rows.length));
      if (result.truncated) info.write(tr.truncatedSuffix);
      info.write(' · ${result.elapsed.inMilliseconds} ms');
    }
    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: Row(
        children: [
          Text(
            info.toString(),
            style: typo.label.copyWith(fontSize: 10.5, color: colors.text3),
          ),
          const Spacer(),
          // Toggle Table / JSON (JSON é selecionável/copiável). Estado por tab,
          // fora do frontmatter.
          if (result != null && result.affectedRows == null) ...[
            Builder(
              builder: (anchor) => HoverTap(
                key: const ValueKey('db-query-export-button'),
                onTap: () => _showExportMenu(anchor, result),
                color: colors.panel3,
                borderRadius: const BorderRadius.all(Radius.circular(4)),
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.file_download_outlined, size: 12, color: colors.text3),
                    const SizedBox(width: 4),
                    Text(
                      'Exportar',
                      style: typo.label.copyWith(fontSize: 10.5, color: colors.text2),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            _ViewToggle(
              label: tr.table,
              active: !_view.asJson,
              onTap: () => setState(() => _view.asJson = false),
            ),
            _ViewToggle(
              label: tr.json,
              active: _view.asJson,
              onTap: () => setState(() => _view.asJson = true),
            ),
            const SizedBox(width: 10),
          ],
          Text(
            _dirty ? tr.unsaved : tr.saved,
            style: typo.label.copyWith(
              fontSize: 10.5,
              color: _dirty ? colors.warn : colors.text4,
            ),
          ),
        ],
      ),
    );
  }

  /// Larguras base por coluna: nome + amostra das primeiras linhas.
  static List<double> _computeWidths(DbResult result) {
    final widths = <double>[];
    for (var c = 0; c < result.columns.length; c++) {
      var chars = result.columns[c].name.length;
      for (var r = 0; r < result.rows.length && r < 20; r++) {
        final len = _cellText(result.rows[r][c]).length;
        if (len > chars) chars = len;
      }
      widths.add((chars * 7.5 + 26).clamp(64.0, 340.0));
    }
    return widths;
  }

  static String _cellText(Object? v) => switch (v) {
    null => 'NULL',
    Uint8List() => 'blob ${v.length} B',
    _ => v.toString(),
  };
}

/// Botão compacto do toggle Table/JSON no rodapé.
class _ViewToggle extends StatelessWidget {
  const _ViewToggle({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return HoverTap(
      onTap: onTap,
      color: active ? colors.panel3 : null,
      borderRadius: const BorderRadius.all(Radius.circular(4)),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Text(
        label,
        style: context.typo.label.copyWith(
          fontSize: 10.5,
          color: active ? colors.text : colors.text4,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────── json ──

/// Resultado como JSON (lista de objetos coluna→valor), selecionável e
/// copiável. BLOB vira `<blob N bytes>`, DateTime ISO-8601.
class _JsonView extends StatelessWidget {
  const _JsonView({required this.result});

  final DbResult result;

  /// Preview cap: acima disso o `SelectableText` único (não virtualizado)
  /// pesa. O preview mostra as primeiras [_previewRows]; **Copy leva tudo**.
  static const _previewRows = 500;

  bool get _capped => result.rows.length > _previewRows;

  String _buildJson(List<List<Object?>> rows) {
    final names = [for (final c in result.columns) c.name];
    final list = [
      for (final row in rows)
        {for (var i = 0; i < names.length; i++) names[i]: _jsonCell(row[i])},
    ];
    return const JsonEncoder.withIndent('  ').convert(list);
  }

  /// JSON exibido (cortado no preview) e JSON completo (pro Copy).
  String get _previewJson => _buildJson(
    _capped ? result.rows.take(_previewRows).toList() : result.rows,
  );
  String get _fullJson => _capped ? _buildJson(result.rows) : _previewJson;

  static Object? _jsonCell(Object? v) => switch (v) {
    null || int() || double() || bool() || String() => v,
    DateTime() => v.toIso8601String(),
    Uint8List() => '<blob ${v.length} bytes>',
    _ => v.toString(),
  };

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final json = _previewJson;
    final style = context.typo.mono.copyWith(
      fontSize: 12,
      height: 1.45,
      color: colors.text2,
    );
    // Highlight de JSON via o mesmo highlighter do editor; null (grande
    // demais) cai no texto puro.
    final span = buildCodeSpan(
      context,
      source: json,
      language: 'json',
      baseStyle: style,
    );
    return Stack(
      children: [
        Positioned.fill(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_capped)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  color: colors.panel2,
                  child: Text(
                    'Preview limited to the first $_previewRows of '
                    '${result.rows.length} rows — use Copy for the full JSON.',
                    style: context.typo.label.copyWith(
                      fontSize: 10.5,
                      color: colors.text3,
                    ),
                  ),
                ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: span == null
                      ? SelectableText(json, style: style)
                      : SelectableText.rich(span, style: style),
                ),
              ),
            ],
          ),
        ),
        Positioned(top: 6, right: 14, child: _CopyButton(text: _fullJson)),
      ],
    );
  }
}

class _CopyButton extends StatefulWidget {
  const _CopyButton({required this.text});
  final String text;

  @override
  State<_CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<_CopyButton> {
  bool _copied = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return HoverTap(
      onTap: () async {
        await Clipboard.setData(ClipboardData(text: widget.text));
        if (!mounted) return;
        setState(() => _copied = true);
        Future.delayed(const Duration(milliseconds: 1200), () {
          if (mounted) setState(() => _copied = false);
        });
      },
      color: colors.panel2,
      border: Border.all(color: colors.border),
      borderRadius: const BorderRadius.all(Radius.circular(5)),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _copied ? Icons.check : Icons.copy,
            size: 12,
            color: _copied ? colors.online : colors.text3,
          ),
          const SizedBox(width: 5),
          Text(
            _copied
                ? context.t.orkest.dbQueryView.copied
                : context.t.orkest.dbQueryView.copy,
            style: context.typo.label.copyWith(
              fontSize: 10.5,
              color: colors.text3,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────── grid ──

const double _indexColWidth = 44;

/// Grid responsivo (decisão F): colunas preenchem a largura (sobra distribuída
/// proporcionalmente), gutter de índice sem header, divisor de header
/// arrastável só pra aumentar. Sem ordenação.
class _DbGrid extends StatefulWidget {
  const _DbGrid({
    required this.result,
    required this.baseWidths,
    required this.manualWidths,
    required this.selectedRow,
    required this.onSelectRow,
    this.onEditCell,
    required this.onResizeStart,
    required this.onResize,
  });

  final DbResult result;
  final List<double> baseWidths;

  /// Larguras fixadas pelo usuário (drag 1:1). `null` = responsivo.
  final List<double>? manualWidths;
  final int? selectedRow;
  final ValueChanged<int> onSelectRow;
  final void Function(int rowIndex, int colIndex, Object? currentValue)? onEditCell;

  /// Chamado no início do drag com as larguras VISUAIS atuais (pro parent
  /// congelar).
  final void Function(List<double> effective) onResizeStart;
  final void Function(int col, double delta) onResize;

  @override
  State<_DbGrid> createState() => _DbGridState();
}

class _DbGridState extends State<_DbGrid> {
  /// Controller do eixo horizontal — necessário porque o
  /// `ShadcnScrollBehavior` global NÃO desenha scrollbar em scrollables
  /// horizontais (retorna o child cru); sem uma [Scrollbar] explícita o
  /// usuário de mouse fica sem como alcançar as colunas fora da viewport.
  final ScrollController _hCtrl = ScrollController();

  @override
  void dispose() {
    _hCtrl.dispose();
    super.dispose();
  }

  DbResult get result => widget.result;
  List<double> get baseWidths => widget.baseWidths;
  List<double>? get manualWidths => widget.manualWidths;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final avail = box.maxWidth - _indexColWidth;
        final List<double> widths;
        final double sum;
        final manual = manualWidths;
        if (manual != null) {
          // Modo manual: larguras verbatim; a última coluna absorve a sobra
          // (visual — não escrevemos de volta no estado).
          widths = [...manual];
          final s = widths.fold<double>(0, (a, b) => a + b);
          if (s < avail && widths.isNotEmpty) {
            widths[widths.length - 1] += avail - s;
          }
          sum = widths.fold<double>(0, (a, b) => a + b);
        } else {
          final s = baseWidths.fold<double>(0, (a, b) => a + b);
          widths = s < avail
              ? [for (final w in baseWidths) w * avail / s]
              : [...baseWidths];
          sum = widths.fold<double>(0, (a, b) => a + b);
        }
        final total = _indexColWidth + widths.fold<double>(0, (a, b) => a + b);
        final content = SizedBox(
          width: total,
          child: Column(
            children: [
              _GridHeader(
                columns: result.columns,
                widths: widths,
                onResizeStart: () => widget.onResizeStart(widths),
                onResize: widget.onResize,
              ),
              Expanded(
                child: ListView.builder(
                  // Faixa livre no rodapé pra scrollbar horizontal não cobrir
                  // a última linha (e o clique no thumb não disputar com ela).
                  padding: const EdgeInsets.only(bottom: 14),
                  itemCount: result.rows.length,
                  itemExtent: 26,
                  itemBuilder: (context, i) => _GridRow(
                    number: i + 1,
                    cells: result.rows[i],
                    widths: widths,
                    selected: i == widget.selectedRow,
                    onTap: () => widget.onSelectRow(i),
                    onEditCell: (col, val) => widget.onEditCell?.call(i, col, val),
                  ),
                ),
              ),
            ],
          ),
        );
        if (sum < avail) return content;
        // Scrollbar explícita: o ShadcnScrollBehavior do app não desenha
        // scrollbar em scrollables horizontais, então sem ela o overflow de
        // colunas fica inalcançável com mouse (o wheel vertical pertence ao
        // ListView de linhas). Shift+wheel e pan de trackpad seguem nativos.
        // thickness maior que o default (7): o hit-test do RawScrollbar é só
        // sobre a área pintada do thumb — com 7px na borda de baixo o alvo de
        // clique era quase impossível de acertar.
        return Scrollbar(
          controller: _hCtrl,
          thumbVisibility: true,
          thickness: 12,
          child: SingleChildScrollView(
            controller: _hCtrl,
            scrollDirection: Axis.horizontal,
            child: content,
          ),
        );
      },
    );
  }
}

class _GridHeader extends StatelessWidget {
  const _GridHeader({
    required this.columns,
    required this.widths,
    required this.onResizeStart,
    required this.onResize,
  });

  final List<DbColumn> columns;
  final List<double> widths;
  final VoidCallback onResizeStart;
  final void Function(int col, double delta) onResize;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typo = context.typo;
    return SizedBox(
      height: 34,
      child: Row(
        children: [
          // Canto do gutter de índice: sem header.
          const SizedBox(width: _indexColWidth),
          for (var c = 0; c < columns.length; c++)
            Container(
              width: widths[c],
              decoration: BoxDecoration(
                color: colors.panel2,
                border: Border(bottom: BorderSide(color: colors.border2)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            columns[c].name,
                            overflow: TextOverflow.ellipsis,
                            style: typo.label.copyWith(
                              fontSize: 11,
                              color: colors.text2,
                            ),
                          ),
                          if (columns[c].type.isNotEmpty)
                            Text(
                              columns[c].type,
                              style: typo.mono.copyWith(
                                fontSize: 8.5,
                                color: colors.text4,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  MouseRegion(
                    cursor: SystemMouseCursors.resizeColumn,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onHorizontalDragStart: (_) => onResizeStart(),
                      onHorizontalDragUpdate: (d) => onResize(c, d.delta.dx),
                      child: SizedBox(
                        width: 9,
                        height: double.infinity,
                        child: Center(
                          child: Container(width: 1, color: colors.border2),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _GridRow extends StatelessWidget {
  const _GridRow({
    required this.number,
    required this.cells,
    required this.widths,
    required this.selected,
    required this.onTap,
    this.onEditCell,
  });

  final int number;
  final List<Object?> cells;
  final List<double> widths;
  final bool selected;
  final VoidCallback onTap;
  final void Function(int colIndex, Object? currentValue)? onEditCell;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typo = context.typo;
    return HoverTap(
      onTap: onTap,
      borderRadius: BorderRadius.zero,
      color: selected ? colors.accentSoft : null,
      child: Container(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: colors.border)),
        ),
        child: Row(
          children: [
            Container(
              width: _indexColWidth,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colors.panel2,
                border: Border(right: BorderSide(color: colors.border)),
              ),
              child: Text(
                '$number',
                style: typo.mono.copyWith(fontSize: 10, color: colors.text4),
              ),
            ),
            for (var c = 0; c < cells.length; c++)
              SizedBox(
                width: widths[c],
                child: GestureDetector(
                  onDoubleTap: onEditCell != null ? () => onEditCell!(c, cells[c]) : null,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: _CellValue(value: cells[c]),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CellValue extends StatelessWidget {
  const _CellValue({required this.value});

  final Object? value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final base = context.typo.mono.copyWith(
      fontSize: 11.5,
      color: colors.text2,
    );
    final v = value;
    if (v == null) {
      return Text(
        'NULL',
        style: base.copyWith(color: colors.text4, fontStyle: FontStyle.italic),
      );
    }
    if (v is Uint8List) {
      return Text(
        '⟨blob · ${v.length} B⟩',
        style: base.copyWith(color: colors.text4),
      );
    }
    if (v is num) {
      return Text(
        '$v',
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.right,
        style: base.copyWith(color: colors.text),
      );
    }
    return Text('$v', overflow: TextOverflow.ellipsis, style: base);
  }
}
