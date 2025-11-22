import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import '../models/categoria.dart';
import '../models/fonte_renda.dart';
import '../models/despesa.dart';
import 'database_service.dart';

class ImportExportService {
  static final ImportExportService instance = ImportExportService._init();
  final DatabaseService _db = DatabaseService.instance;

  ImportExportService._init();

  // Estrutura do JSON de exportação
  Map<String, dynamic> _createExportData({
    required List<Categoria> categorias,
    required List<FonteRenda> fontesRenda,
    required List<Despesa> despesas,
  }) {
    return {
      'version': '1.0',
      'exportDate': DateTime.now().toIso8601String(),
      'categorias': categorias.map((c) => c.toMap()).toList(),
      'fontesRenda': fontesRenda.map((f) => f.toMap()).toList(),
      'despesas': despesas.map((d) => d.toMap()).toList(),
    };
  }

  // Exportar dados para JSON
  Future<String> exportarDados() async {
    try {
      // Buscar todos os dados
      final categorias = await _db.buscarTodasCategorias();
      final fontesRenda = await _db.buscarTodasFontesRenda();
      final despesas = await _db.buscarTodasDespesas();

      // Criar estrutura de dados
      final exportData = _createExportData(
        categorias: categorias,
        fontesRenda: fontesRenda,
        despesas: despesas,
      );

      // Converter para JSON
      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);

      // Salvar em arquivo temporário
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${directory.path}/expense_tracker_backup_$timestamp.json');
      await file.writeAsString(jsonString);

      return file.path;
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao exportar dados: $e');
      }
      rethrow;
    }
  }

  // Salvar arquivo exportado (permite usuário escolher onde salvar)
  Future<String?> salvarDados() async {
    try {
      // Buscar todos os dados
      final categorias = await _db.buscarTodasCategorias();
      final fontesRenda = await _db.buscarTodasFontesRenda();
      final despesas = await _db.buscarTodasDespesas();

      // Criar estrutura de dados
      final exportData = _createExportData(
        categorias: categorias,
        fontesRenda: fontesRenda,
        despesas: despesas,
      );

      // Converter para JSON
      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);
      final jsonBytes = utf8.encode(jsonString);

      // Criar nome do arquivo com data
      final timestamp = DateTime.now();
      final fileName = 'expense_tracker_backup_${timestamp.year}${timestamp.month.toString().padLeft(2, '0')}${timestamp.day.toString().padLeft(2, '0')}_${timestamp.hour}${timestamp.minute}${timestamp.second}.json';

      // Usar file_picker para salvar arquivo
      final String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Salvar Backup',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['json'],
        bytes: jsonBytes,
      );

      return outputFile;
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao salvar dados: $e');
      }
      rethrow;
    }
  }

  // Importar dados de arquivo JSON
  Future<Map<String, int>> importarDados(String filePath) async {
    try {
      final file = File(filePath);
      final jsonString = await file.readAsString();
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;

      // Validar versão (para compatibilidade futura)
      final version = jsonData['version'] as String?;
      if (version == null) {
        throw Exception('Arquivo inválido: versão não encontrada');
      }

      int categoriasImportadas = 0;
      int fontesRendaImportadas = 0;
      int despesasImportadas = 0;

      // Importar categorias (apenas não padrão para evitar duplicatas)
      if (jsonData['categorias'] != null) {
        final categoriasData = jsonData['categorias'] as List;
        for (var catData in categoriasData) {
          final categoria = Categoria.fromMap(catData as Map<String, dynamic>);
          // Só importar se não for padrão ou se não existir
          if (!categoria.isPadrao) {
            try {
              await _db.createCategoria(categoria.copyWith(id: null));
              categoriasImportadas++;
            } catch (e) {
              // Ignorar erros de duplicata
              if (kDebugMode) {
                print('Erro ao importar categoria: $e');
              }
            }
          }
        }
      }

      // Importar fontes de renda
      if (jsonData['fontesRenda'] != null) {
        final fontesRendaData = jsonData['fontesRenda'] as List;
        for (var fonteData in fontesRendaData) {
          final fonte = FonteRenda.fromMap(fonteData as Map<String, dynamic>);
          try {
            await _db.createFonteRenda(fonte.copyWith(id: null));
            fontesRendaImportadas++;
          } catch (e) {
            if (kDebugMode) {
              print('Erro ao importar fonte de renda: $e');
            }
          }
        }
      }

      // Importar despesas
      if (jsonData['despesas'] != null) {
        final despesasData = jsonData['despesas'] as List;
        for (var despesaData in despesasData) {
          final despesa = Despesa.fromMap(despesaData as Map<String, dynamic>);
          try {
            await _db.createDespesa(despesa.copyWith(id: null));
            despesasImportadas++;
          } catch (e) {
            if (kDebugMode) {
              print('Erro ao importar despesa: $e');
            }
          }
        }
      }

      return {
        'categorias': categoriasImportadas,
        'fontesRenda': fontesRendaImportadas,
        'despesas': despesasImportadas,
      };
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao importar dados: $e');
      }
      rethrow;
    }
  }

  // Selecionar arquivo para importar
  Future<String?> selecionarArquivo() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        return result.files.single.path;
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao selecionar arquivo: $e');
      }
      return null;
    }
  }
}

