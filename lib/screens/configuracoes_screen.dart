import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../utils/app_theme.dart';
import '../services/import_export_service.dart';
import '../providers/expense_provider.dart';

class ConfiguracoesScreen extends StatefulWidget {
  const ConfiguracoesScreen({super.key});

  @override
  State<ConfiguracoesScreen> createState() => _ConfiguracoesScreenState();
}

class _ConfiguracoesScreenState extends State<ConfiguracoesScreen> {
  final ImportExportService _importExportService = ImportExportService.instance;
  bool _isExporting = false;
  bool _isImporting = false;
  String _appVersion = '1.0.0';

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _appVersion = packageInfo.version;
        });
      }
    } catch (e) {
      // Se falhar, mantém a versão padrão
    }
  }

  Future<void> _abrirSiteMicroFocus() async {
    final url = Uri.parse('https://microfocus.dev.br/');
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Não foi possível abrir o link: $e'),
            backgroundColor: AppTheme.secondaryColor,
          ),
        );
      }
    }
  }

  Future<void> _exportarDados() async {
    setState(() {
      _isExporting = true;
    });

    try {
      final filePath = await _importExportService.salvarDados();
      if (mounted) {
        if (filePath != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Dados exportados com sucesso!\nSalvo em: $filePath',
              ),
              backgroundColor: AppTheme.primaryColor,
              duration: const Duration(seconds: 3),
            ),
          );
        } else {
          // Usuário cancelou
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Exportação cancelada'),
              backgroundColor: AppTheme.textSecondary,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao exportar dados: $e'),
            backgroundColor: AppTheme.secondaryColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  Future<void> _importarDados() async {
    // Confirmar importação
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Importar Dados'),
        content: const Text(
          'Esta ação irá adicionar os dados do arquivo ao banco de dados atual. '
          'Dados duplicados podem ser criados. Deseja continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.secondaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Importar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    setState(() {
      _isImporting = true;
    });

    try {
      final filePath = await _importExportService.selecionarArquivo();
      if (filePath == null) {
        if (mounted) {
          setState(() {
            _isImporting = false;
          });
        }
        return;
      }

      final resultado = await _importExportService.importarDados(filePath);

      // Recarregar dados no provider
      final provider = context.read<ExpenseProvider>();
      await provider.carregarDados();

      if (mounted) {
        final cartoes = resultado['cartoesCredito'] ?? 0;
        final faturas = resultado['faturasCartao'] ?? 0;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Dados importados com sucesso!\n'
              'Categorias: ${resultado['categorias']}, '
              'Receitas: ${resultado['fontesRenda']}, '
              'Despesas: ${resultado['despesas']}'
              '${cartoes > 0 ? ', Cartões: $cartoes' : ''}'
              '${faturas > 0 ? ', Faturas: $faturas' : ''}',
            ),
            backgroundColor: AppTheme.primaryColor,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao importar dados: $e'),
            backgroundColor: AppTheme.secondaryColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isImporting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Backup de Dados',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Exporte seus dados para fazer backup ou importe dados de outro dispositivo.',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 24),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(
                        Icons.upload,
                        color: AppTheme.primaryColor,
                      ),
                      title: const Text('Exportar Dados'),
                      subtitle: const Text('Salve seus dados em um arquivo'),
                      trailing: _isExporting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.chevron_right),
                      onTap: _isExporting ? null : _exportarDados,
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(
                        Icons.download,
                        color: AppTheme.secondaryColor,
                      ),
                      title: const Text('Importar Dados'),
                      subtitle: const Text(
                        'Carregue seus dados a partir de um arquivo',
                      ),
                      trailing: _isImporting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.chevron_right),
                      onTap: _isImporting ? null : _importarDados,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Informações discretas no final
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: InkWell(
            onTap: _abrirSiteMicroFocus,
            child: Column(
              children: [
                Text(
                  'Micro Focus',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textTertiary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Versão $_appVersion',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textTertiary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
