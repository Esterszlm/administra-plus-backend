import 'dart:convert';
import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';

import '../core/app_colors.dart';

/// Tabela reutilizável: pesquisa livre nas colunas visíveis e exportação CSV.
///
/// As telas existentes não precisam mudar. Se a tela precisar pesquisar também
/// campos não exibidos, passe [searchRecords] na mesma ordem de [rows].
/// A exportação usa APENAS as colunas visíveis, nunca os dados brutos extras.
class AdminTablePage extends StatefulWidget {
  final String title;
  final String subtitle;
  final bool loading;
  final String message;
  final String emptyMessage;
  final Future<void> Function() onRefresh;
  final VoidCallback? onNew;
  final List<DataColumn> columns;
  final List<DataRow> rows;
  final List<Map<String, dynamic>>? searchRecords;

  const AdminTablePage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.loading,
    required this.message,
    required this.emptyMessage,
    required this.onRefresh,
    required this.columns,
    required this.rows,
    this.onNew,
    this.searchRecords,
  });

  @override
  State<AdminTablePage> createState() => _AdminTablePageState();
}

class _AdminTablePageState extends State<AdminTablePage> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  bool _exporting = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Extrai somente o texto que aparece nos componentes da tabela.
  /// Botões de ação representados por ícones não são exportados.
  String _widgetText(Widget? widget) {
    if (widget == null) return '';
    if (widget is Text) {
      return widget.data ?? widget.textSpan?.toPlainText() ?? '';
    }
    if (widget is RichText) return widget.text.toPlainText();
    if (widget is Chip) return _widgetText(widget.label);
    if (widget is InputChip) return _widgetText(widget.label);
    if (widget is Tooltip) return _widgetText(widget.child);
    if (widget is Row) return widget.children.map(_widgetText).join(' ');
    if (widget is Column) return widget.children.map(_widgetText).join(' ');
    if (widget is Wrap) return widget.children.map(_widgetText).join(' ');
    if (widget is Padding) return _widgetText(widget.child);
    if (widget is Center) return _widgetText(widget.child);
    if (widget is Align) return _widgetText(widget.child);
    if (widget is Container) return _widgetText(widget.child);
    if (widget is SizedBox) return _widgetText(widget.child);
    if (widget is Flexible) return _widgetText(widget.child);
    if (widget is InkWell) return _widgetText(widget.child);
    if (widget is GestureDetector) return _widgetText(widget.child);
    if (widget is SingleChildScrollView) return _widgetText(widget.child);
    if (widget is ClipRRect) return _widgetText(widget.child);
    if (widget is ListTile) {
      return '${_widgetText(widget.title)} ${_widgetText(widget.subtitle)}';
    }
    if (widget is ButtonStyleButton) return _widgetText(widget.child);
    return '';
  }

  String _normalize(String value) {
    var text = value.toLowerCase();
    const source = 'áàâãäéèêëíìîïóòôõöúùûüçñ';
    const target = 'aaaaaeeeeiiiiooooouuuucn';
    for (var i = 0; i < source.length; i++) {
      text = text.replaceAll(source[i], target[i]);
    }
    return text;
  }

  String _indexText(int index) {
    final cells = widget.rows[index].cells;
    final visible = cells.map((cell) => _widgetText(cell.child)).join(' ');
    final extras = widget.searchRecords;
    if (extras == null || extras.length != widget.rows.length) {
      return _normalize(visible);
    }
    // Extras auxiliam a pesquisa, mas NÃO vão para o arquivo exportado.
    // Exclui chaves que podem conter informações sigilosas.
    const hiddenKeys = {
      'password', 'hashed_password', 'secret', 'secret_key',
      'token', 'access_token', 'refresh_token',
    };
    final searchable = extras[index].entries
        .where((e) => !hiddenKeys.contains(e.key.toLowerCase()))
        .map((e) => e.value?.toString() ?? '')
        .join(' ');
    return _normalize('$visible $searchable');
  }

  bool _matches(String haystack, String term) {
    // Impede que a busca por "ativo" retorne também "desativado".
    if (term == 'ativo' || term == 'desativado' || term == 'inativo') {
      return RegExp('(^|[^a-z])${RegExp.escape(term)}([^a-z]|\$)')
          .hasMatch(haystack);
    }
    return haystack.contains(term);
  }

  List<int> get _matchingIndices {
    final terms = _normalize(_query.trim())
        .split(RegExp(r'\s+'))
        .where((value) => value.isNotEmpty)
        .toList();

    if (terms.isEmpty) {
      return List<int>.generate(widget.rows.length, (index) => index);
    }
    return List<int>.generate(widget.rows.length, (index) => index)
        .where((index) {
          final text = _indexText(index);
          return terms.every((term) => _matches(text, term));
        })
        .toList();
  }

  String _csvCell(String value) {
    var safe = value;
    // Evita execução de fórmulas se texto cadastrado começar com =,+,-,@.
    if (RegExp(r'^[\s]*[=+\-@]').hasMatch(safe)) {
      safe = "'$safe";
    }
    return '"${safe.replaceAll('"', '""')}"';
  }

  Future<void> _exportCsv() async {
    if (_exporting || widget.loading || widget.message.isNotEmpty) return;
    final indices = _matchingIndices;
    if (indices.isEmpty) return;

    setState(() => _exporting = true);
    try {
      // A coluna "Ações" nunca deve ser exportada.
      final keepColumns = <int>[];
      final headerLabels = <String>[];
      for (var i = 0; i < widget.columns.length; i++) {
        final title = _widgetText(widget.columns[i].label).trim();
        if (_normalize(title) == 'acoes') continue;
        keepColumns.add(i);
        headerLabels.add(title.isEmpty ? 'Coluna ${i + 1}' : title);
      }

      final lines = <String>[
        headerLabels.map(_csvCell).join(';'),
      ];
      for (final rowIndex in indices) {
        final cells = widget.rows[rowIndex].cells;
        lines.add(keepColumns.map((i) {
          if (i >= cells.length) return _csvCell('');
          return _csvCell(_widgetText(cells[i].child));
        }).join(';'));
      }
      // Excel em PT-BR: UTF-8 BOM, ponto e vírgula e CRLF.
      final content = lines.join('\r\n');
      final bytes = Uint8List.fromList([
        0xEF, 0xBB, 0xBF,
        ...utf8.encode(content),
      ]);
      final now = DateTime.now();
      final date = '${now.year}${now.month.toString().padLeft(2, '0')}'
          '${now.day.toString().padLeft(2, '0')}';
      final section = _normalize(widget.title)
          .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
          .replaceAll(RegExp(r'^_|_$'), '');
      await FileSaver.instance.saveFile(
        name: 'administra_${section}_$date',
        bytes: bytes,
        fileExtension: 'csv',
        mimeType: MimeType.csv,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${indices.length} registro(s) exportado(s).')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível exportar: $e')),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final indices = _matchingIndices;
    final filteredRows = indices.map((index) => widget.rows[index]).toList();
    final hasResults = !widget.loading && widget.message.isEmpty &&
        filteredRows.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Mantém a posição original dos botões.
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            OutlinedButton.icon(
              onPressed: widget.loading ? null : widget.onRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Atualizar'),
            ),
            if (widget.onNew != null) ...[
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: widget.loading ? null : widget.onNew,
                icon: const Icon(Icons.add),
                label: const Text('Novo cadastro'),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _query = value),
                decoration: InputDecoration(
                  hintText: 'Pesquisar qualquer informação da tabela...',
                  prefixIcon: const Icon(Icons.search),
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          tooltip: 'Limpar pesquisa',
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: hasResults && !_exporting ? _exportCsv : null,
              icon: _exporting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download_outlined),
              label: const Text('Exportar CSV'),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 10),
          child: Text(
            '${indices.length} de ${widget.rows.length} registro(s) exibido(s)',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ),
        if (widget.loading)
          const Expanded(
            child: Center(child: CircularProgressIndicator()),
          )
        else if (widget.message.isNotEmpty)
          Expanded(
            child: Center(
              child: Text(
                widget.message,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                ),
              ),
            ),
          )
        else if (filteredRows.isEmpty)
          Expanded(
            child: Center(
              child: Text(
                widget.rows.isEmpty
                    ? widget.emptyMessage
                    : 'Nenhum resultado encontrado para esta pesquisa.',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                ),
              ),
            ),
          )
        else
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(
                        AppColors.primaryLight,
                      ),
                      columnSpacing: 28,
                      horizontalMargin: 22,
                      columns: widget.columns,
                      rows: filteredRows,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
