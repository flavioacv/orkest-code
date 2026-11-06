import 'package:orkest_code/app/core/domain/entities/lsp_symbol.dart';
import 'package:orkest_code/app/core/ui/themes/themes.dart';
import 'package:orkest_code/app/core/ui/widgets/hover_tap.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

/// Painel da ferramenta **Outline / Estrutura** no Workbench (plano estrutural 73, FE-E5).
///
/// Exibe a árvore semântica de símbolos do documento atualmente ativo (classes,
/// métodos, campos, funções e constantes), com filtro textual instantâneo
/// e navegação por clique.
class OutlinePanel extends StatefulWidget {
  const OutlinePanel({
    super.key,
    required this.symbols,
    this.currentFilePath,
    required this.onNavigateToSource,
  });

  final List<LspDocumentSymbol> symbols;
  final String? currentFilePath;
  final void Function(int line, int character) onNavigateToSource;

  @override
  State<OutlinePanel> createState() => _OutlinePanelState();
}

class _OutlinePanelState extends State<OutlinePanel> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _filterQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<LspDocumentSymbol> _filterSymbols(List<LspDocumentSymbol> items) {
    if (_filterQuery.isEmpty) return items;
    final result = <LspDocumentSymbol>[];
    for (final s in items) {
      final nameMatches = s.name.toLowerCase().contains(_filterQuery);
      final detailMatches = s.detail?.toLowerCase().contains(_filterQuery) ?? false;
      final childFiltered = _filterSymbols(s.children);

      if (nameMatches || detailMatches || childFiltered.isNotEmpty) {
        result.add(
          LspDocumentSymbol(
            name: s.name,
            kind: s.kind,
            range: s.range,
            selectionRange: s.selectionRange,
            detail: s.detail,
            containerName: s.containerName,
            children: childFiltered.isNotEmpty ? childFiltered : s.children,
            location: s.location,
          ),
        );
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typo = context.typo;
    final filtered = _filterSymbols(widget.symbols);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Barra de busca / filtro do outline
        Container(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          decoration: BoxDecoration(
            color: colors.panel2,
            border: Border(bottom: BorderSide(color: colors.border)),
          ),
          child: Container(
            height: 26,
            decoration: BoxDecoration(
              color: colors.panel3,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: colors.border),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              children: [
                Icon(Icons.search, size: 13, color: colors.text4),
                const SizedBox(width: 4),
                Expanded(
                  child: TextField(
                    key: const ValueKey('outline-filter-input'),
                    controller: _searchCtrl,
                    style: typo.mono.copyWith(fontSize: 11),
                    placeholder: Text(
                      'Filtrar símbolos...',
                      style: typo.mono.copyWith(fontSize: 11, color: colors.text4),
                    ),
                    padding: EdgeInsets.zero,
                    onChanged: (val) => setState(() => _filterQuery = val.trim().toLowerCase()),
                  ),
                ),
                if (_filterQuery.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _searchCtrl.clear();
                      setState(() => _filterQuery = '');
                    },
                    child: Icon(Icons.close, size: 12, color: colors.text3),
                  ),
              ],
            ),
          ),
        ),

        // Lista de símbolos
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      widget.symbols.isEmpty
                          ? 'Nenhum símbolo disponível para o arquivo aberto.'
                          : 'Nenhum símbolo encontrado para "$_filterQuery".',
                      textAlign: TextAlign.center,
                      style: typo.label.copyWith(fontSize: 11.5, color: colors.text4),
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                  children: [
                    for (final s in filtered)
                      _OutlineSymbolNode(
                        symbol: s,
                        depth: 0,
                        onNavigate: widget.onNavigateToSource,
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _OutlineSymbolNode extends StatefulWidget {
  const _OutlineSymbolNode({
    required this.symbol,
    required this.depth,
    required this.onNavigate,
  });

  final LspDocumentSymbol symbol;
  final int depth;
  final void Function(int line, int character) onNavigate;

  @override
  State<_OutlineSymbolNode> createState() => _OutlineSymbolNodeState();
}

class _OutlineSymbolNodeState extends State<_OutlineSymbolNode> {
  bool _expanded = true;

  IconData _iconForKind(LspSymbolKind kind) {
    switch (kind) {
      case LspSymbolKind.classType:
      case LspSymbolKind.interfaceType:
      case LspSymbolKind.struct:
        return Icons.category_outlined;
      case LspSymbolKind.method:
      case LspSymbolKind.function:
      case LspSymbolKind.constructor:
        return Icons.functions;
      case LspSymbolKind.property:
      case LspSymbolKind.field:
        return Icons.data_object;
      case LspSymbolKind.variable:
      case LspSymbolKind.constant:
        return Icons.numbers;
      case LspSymbolKind.enumType:
      case LspSymbolKind.enumMember:
        return Icons.list_alt;
      case LspSymbolKind.package:
      case LspSymbolKind.module:
      case LspSymbolKind.namespace:
        return Icons.folder_outlined;
      default:
        return Icons.code;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typo = context.typo;
    final s = widget.symbol;
    final hasChildren = s.children.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HoverTap(
          onTap: () {
            widget.onNavigate(
              s.selectionRange.start.line + 1, // 1-based editor
              s.selectionRange.start.character + 1,
            );
          },
          padding: EdgeInsets.fromLTRB((widget.depth * 14.0) + 4, 3, 6, 3),
          borderRadius: BorderRadius.circular(4),
          child: Row(
            children: [
              if (hasChildren)
                GestureDetector(
                  onTap: () => setState(() => _expanded = !_expanded),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 2),
                    child: Icon(
                      _expanded ? Icons.expand_more : Icons.chevron_right,
                      size: 13,
                      color: colors.text4,
                    ),
                  ),
                )
              else
                const SizedBox(width: 15),
              Icon(
                _iconForKind(s.kind),
                size: 13,
                color: colors.accent,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  s.name,
                  overflow: TextOverflow.ellipsis,
                  style: typo.mono.copyWith(fontSize: 11.5, color: colors.text),
                ),
              ),
              if (s.detail != null && s.detail!.isNotEmpty) ...[
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    s.detail!,
                    overflow: TextOverflow.ellipsis,
                    style: typo.mono.copyWith(fontSize: 10, color: colors.text4),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (hasChildren && _expanded)
          for (final child in s.children)
            _OutlineSymbolNode(
              symbol: child,
              depth: widget.depth + 1,
              onNavigate: widget.onNavigate,
            ),
      ],
    );
  }
}
