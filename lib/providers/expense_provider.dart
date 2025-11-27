import 'package:flutter/foundation.dart';
import '../models/categoria.dart';
import '../models/fonte_renda.dart';
import '../models/despesa.dart';
import '../models/cartao_credito.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';

class ExpenseProvider with ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;
  final NotificationService _notification = NotificationService.instance;

  DateTime _mesAtual = DateTime.now();
  List<Categoria> _categorias = [];
  List<FonteRenda> _fontesRenda = [];
  List<Despesa> _despesas = [];
  List<CartaoCredito> _cartoesCredito = [];
  bool _isLoading = false;

  DateTime get mesAtual => _mesAtual;
  List<Categoria> get categorias => _categorias;
  List<FonteRenda> get fontesRenda => _fontesRenda;
  List<Despesa> get despesas => _despesas;
  List<CartaoCredito> get cartoesCredito => _cartoesCredito;
  bool get isLoading => _isLoading;

  double get totalReceitas {
    return _fontesRenda.fold(0.0, (sum, fonte) => sum + fonte.valor);
  }

  double get totalDespesas {
    return _despesas.fold(0.0, (sum, despesa) => sum + despesa.valor);
  }

  double get saldo {
    return totalReceitas - totalDespesas;
  }

  // Inicialização
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Tentar inicializar notificações (não crítico)
      try {
        await _notification.initialize();
        await _notification.requestPermissions();
      } catch (e) {
        if (kDebugMode) {
          print('Erro ao inicializar notificações no provider: $e');
        }
        // Continua mesmo se notificações falharem
      }

      // Carregar dados do banco (crítico)
      await carregarDados();
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao inicializar provider: $e');
      }
      // Em caso de erro, inicializar com dados vazios
      _categorias = [];
      _fontesRenda = [];
      _despesas = [];
      _cartoesCredito = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  // Carregar dados do mês atual
  Future<void> carregarDados() async {
    try {
      _categorias = await _db.getCategorias();
      _fontesRenda = await _db.getFontesRenda(_mesAtual.month, _mesAtual.year);
      _despesas = await _db.getDespesas(_mesAtual.month, _mesAtual.year);
      _cartoesCredito = await _db.getCartoesCredito();
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao carregar dados: $e');
      }
      // Em caso de erro, usar listas vazias
      _categorias = [];
      _fontesRenda = [];
      _despesas = [];
      _cartoesCredito = [];
    }
    notifyListeners();
  }

  // Mudar mês
  void mudarMes(int mes, int ano) {
    _mesAtual = DateTime(ano, mes);
    carregarDados();
  }

  void proximoMes() {
    final novoMes = DateTime(_mesAtual.year, _mesAtual.month + 1);
    mudarMes(novoMes.month, novoMes.year);
  }

  void mesAnterior() {
    final novoMes = DateTime(_mesAtual.year, _mesAtual.month - 1);
    mudarMes(novoMes.month, novoMes.year);
  }

  // Categorias
  Future<void> adicionarCategoria(Categoria categoria) async {
    await _db.createCategoria(categoria);
    await carregarDados();
  }

  Future<void> atualizarCategoria(Categoria categoria) async {
    await _db.updateCategoria(categoria);
    await carregarDados();
  }

  Future<void> deletarCategoria(int id) async {
    // Buscar despesas associadas para cancelar notificações
    final despesas = await _db.getDespesasPorCategoriaId(id);

    // Cancelar notificações de todas as despesas
    for (var despesa in despesas) {
      if (despesa.id != null) {
        try {
          await _notification.cancelarNotificacao(despesa.id!);
        } catch (e) {
          // Ignora erros ao cancelar notificações
          if (kDebugMode) {
            print('Erro ao cancelar notificação: $e');
          }
        }
      }
    }

    // Deletar categoria (que também deleta as despesas)
    await _db.deleteCategoria(id);
    await carregarDados();
  }

  double getGastosPorCategoria(int categoriaId) {
    return _despesas
        .where((d) => d.categoriaId == categoriaId)
        .fold(0.0, (sum, despesa) => sum + despesa.valor);
  }

  // Fontes de Renda
  Future<void> adicionarFonteRenda(FonteRenda fonte) async {
    await _db.createFonteRenda(fonte);
    await carregarDados();
  }

  Future<void> atualizarFonteRenda(FonteRenda fonte) async {
    await _db.updateFonteRenda(fonte);
    await carregarDados();
  }

  Future<void> deletarFonteRenda(int id) async {
    await _db.deleteFonteRenda(id);
    await carregarDados();
  }

  Future<List<String>> getNomesFontesRenda() async {
    return await _db.getNomesFontesRenda();
  }

  Future<List<FonteRenda>> getFontesRendaMes(int mes, int ano) async {
    return await _db.getFontesRenda(mes, ano);
  }

  Future<List<Despesa>> getDespesasMes(int mes, int ano) async {
    return await _db.getDespesas(mes, ano);
  }

  // Despesas
  Future<void> adicionarDespesa(Despesa despesa) async {
    final novaDespesa = await _db.createDespesa(despesa);

    // Agendar notificação se tiver data de vencimento
    if (novaDespesa.diaVencimento != null) {
      try {
        await _notification.agendarNotificacaoVencimento(novaDespesa);
      } catch (e) {
        print('Erro ao agendar notificação: $e');
        // Continua mesmo se a notificação falhar
      }
    }

    await carregarDados();
  }

  Future<void> atualizarDespesa(Despesa despesa) async {
    await _db.updateDespesa(despesa);

    // Reagendar notificação (apenas se tiver permissões)
    if (despesa.id != null) {
      try {
        await _notification.cancelarNotificacao(despesa.id!);
        if (despesa.diaVencimento != null) {
          await _notification.agendarNotificacaoVencimento(despesa);
        }
      } catch (e) {
        // Silenciosamente ignora erros de notificação para não interromper o fluxo
        if (kDebugMode) {
          print(
            'Notificação não foi reagendada (pode ser falta de permissão): $e',
          );
        }
      }
    }

    await carregarDados();
  }

  Future<void> deletarDespesa(int id) async {
    // Tentar cancelar notificação, mas não interromper se falhar
    try {
      await _notification.cancelarNotificacao(id);
    } catch (e) {
      // Ignora erros ao cancelar notificação para garantir que a deleção aconteça
      if (kDebugMode) {
        print('Erro ao cancelar notificação na deleção: $e');
      }
    }

    // Sempre deletar do banco, mesmo se o cancelamento de notificação falhar
    await _db.deleteDespesa(id);
    await carregarDados();
  }

  Future<void> deletarDespesas(List<int> ids) async {
    // Tentar cancelar notificações, mas não interromper se falhar
    for (var id in ids) {
      try {
        await _notification.cancelarNotificacao(id);
      } catch (e) {
        // Ignora erros ao cancelar notificação para garantir que a deleção aconteça
        if (kDebugMode) {
          print('Erro ao cancelar notificação na deleção: $e');
        }
      }
    }

    // Sempre deletar do banco, mesmo se o cancelamento de notificação falhar
    await _db.deleteDespesas(ids);
    await carregarDados();
  }

  Future<List<Despesa>> getDespesasPorParcelaId(String parcelaId) async {
    return await _db.getDespesasPorParcelaId(parcelaId);
  }

  Future<List<Despesa>> getDespesasNaoPagasPorParcelaId(
    String parcelaId,
  ) async {
    return await _db.getDespesasNaoPagasPorParcelaId(parcelaId);
  }

  Future<List<Despesa>> getDespesasRecorrentesPorParcelaId(
    String parcelaId,
  ) async {
    return await _db.getDespesasRecorrentesPorParcelaId(parcelaId);
  }

  Future<List<Despesa>> getDespesasRecorrentesNaoPagasPorParcelaId(
    String parcelaId,
  ) async {
    return await _db.getDespesasRecorrentesNaoPagasPorParcelaId(parcelaId);
  }

  Future<List<Despesa>> getDespesasParceladasFuturasNaoPagas(
    String parcelaId,
    int numeroParcelaAtual,
  ) async {
    return await _db.getDespesasParceladasFuturasNaoPagas(
      parcelaId,
      numeroParcelaAtual,
    );
  }

  Future<List<Despesa>> getDespesasRecorrentesFuturasNaoPagas(
    String parcelaId,
    int mesAtual,
    int anoAtual,
  ) async {
    return await _db.getDespesasRecorrentesFuturasNaoPagas(
      parcelaId,
      mesAtual,
      anoAtual,
    );
  }

  Future<void> atualizarTodasParcelas(
    String parcelaId,
    Despesa despesaAtualizada,
  ) async {
    final todasParcelas = await _db.getDespesasPorParcelaId(parcelaId);

    for (var parcela in todasParcelas) {
      if (parcela.id != null) {
        // Cancelar notificação antiga
        try {
          await _notification.cancelarNotificacao(parcela.id!);
        } catch (e) {
          // Ignora erros
        }

        // Atualizar parcela mantendo número da parcela e data
        // Ajustar data de compra para o mês/ano da parcela, mantendo o dia
        DateTime? dataCompraParcela;
        if (despesaAtualizada.dataCompra != null) {
          final diaCompra = despesaAtualizada.dataCompra!.day;
          try {
            dataCompraParcela = DateTime(parcela.ano, parcela.mes, diaCompra);
          } catch (e) {
            // Se o dia não for válido para o mês, usar o último dia válido
            final ultimoDia = DateTime(parcela.ano, parcela.mes + 1, 0).day;
            dataCompraParcela = DateTime(
              parcela.ano,
              parcela.mes,
              diaCompra > ultimoDia ? ultimoDia : diaCompra,
            );
          }
        }

        final parcelaAtualizada = parcela.copyWith(
          descricao: despesaAtualizada.descricao,
          valor: despesaAtualizada.valor,
          categoriaId: despesaAtualizada.categoriaId,
          cartaoCreditoId: despesaAtualizada.cartaoCreditoId,
          estabelecimento: despesaAtualizada.estabelecimento,
          isCompraOnline: despesaAtualizada.isCompraOnline,
          tipoPagamento: despesaAtualizada.tipoPagamento,
          dataCompra: dataCompraParcela,
        );

        await _db.updateDespesa(parcelaAtualizada);

        // Reagendar notificação se necessário
        if (parcelaAtualizada.diaVencimento != null) {
          try {
            await _notification.agendarNotificacaoVencimento(parcelaAtualizada);
          } catch (e) {
            // Ignora erros
          }
        }
      }
    }

    await carregarDados();
  }

  Future<void> atualizarParcelasFuturas(
    String parcelaId,
    Despesa despesaAtualizada,
    bool isParcelado,
    int? numeroParcelaAtual,
    int? mesAtual,
    int? anoAtual,
  ) async {
    List<Despesa> parcelasFuturas;

    if (isParcelado && numeroParcelaAtual != null) {
      parcelasFuturas = await _db.getDespesasParceladasFuturasNaoPagas(
        parcelaId,
        numeroParcelaAtual,
      );
    } else if (!isParcelado && mesAtual != null && anoAtual != null) {
      parcelasFuturas = await _db.getDespesasRecorrentesFuturasNaoPagas(
        parcelaId,
        mesAtual,
        anoAtual,
      );
    } else {
      return; // Não há despesas futuras para atualizar
    }

    for (var parcela in parcelasFuturas) {
      if (parcela.id != null) {
        // Cancelar notificação antiga
        try {
          await _notification.cancelarNotificacao(parcela.id!);
        } catch (e) {
          // Ignora erros
        }

        // Atualizar parcela mantendo número da parcela e data
        // Ajustar data de compra para o mês/ano da parcela, mantendo o dia
        DateTime? dataCompraParcela;
        if (despesaAtualizada.dataCompra != null) {
          final diaCompra = despesaAtualizada.dataCompra!.day;
          try {
            dataCompraParcela = DateTime(parcela.ano, parcela.mes, diaCompra);
          } catch (e) {
            // Se o dia não for válido para o mês, usar o último dia válido
            final ultimoDia = DateTime(parcela.ano, parcela.mes + 1, 0).day;
            dataCompraParcela = DateTime(
              parcela.ano,
              parcela.mes,
              diaCompra > ultimoDia ? ultimoDia : diaCompra,
            );
          }
        }

        final parcelaAtualizada = parcela.copyWith(
          descricao: despesaAtualizada.descricao,
          valor: despesaAtualizada.valor,
          categoriaId: despesaAtualizada.categoriaId,
          cartaoCreditoId: despesaAtualizada.cartaoCreditoId,
          estabelecimento: despesaAtualizada.estabelecimento,
          isCompraOnline: despesaAtualizada.isCompraOnline,
          tipoPagamento: despesaAtualizada.tipoPagamento,
          dataCompra: dataCompraParcela,
        );

        await _db.updateDespesa(parcelaAtualizada);

        // Reagendar notificação se necessário
        if (parcelaAtualizada.diaVencimento != null) {
          try {
            await _notification.agendarNotificacaoVencimento(parcelaAtualizada);
          } catch (e) {
            // Ignora erros
          }
        }
      }
    }

    await carregarDados();
  }

  Future<void> copiarDespesasFixas(int mesDestino, int anoDestino) async {
    await _db.copiarDespesasFixasParaMes(
      _mesAtual.month,
      _mesAtual.year,
      mesDestino,
      anoDestino,
    );

    // Reagendar notificações para as novas despesas
    final novasDespesas = await _db.getDespesas(mesDestino, anoDestino);
    for (var despesa in novasDespesas) {
      if (despesa.diaVencimento != null) {
        await _notification.agendarNotificacaoVencimento(despesa);
      }
    }

    if (mesDestino == _mesAtual.month && anoDestino == _mesAtual.year) {
      await carregarDados();
    }
  }

  Future<void> copiarDespesasSelecionadas(
    List<Despesa> despesas,
    int mesDestino,
    int anoDestino,
  ) async {
    print(
      'DEBUG: Copiando ${despesas.length} despesas para $mesDestino/$anoDestino',
    );
    print('DEBUG: Mês atual do provider: ${_mesAtual.month}/${_mesAtual.year}');
    print(
      'DEBUG: Despesas a copiar: ${despesas.map((d) => d.descricao).join(", ")}',
    );

    for (var despesa in despesas) {
      final novaDespesa = despesa.copyWith(
        mes: mesDestino,
        ano: anoDestino,
        status: StatusPagamento.aPagar,
        dataCriacao: DateTime.now(),
        clearId: true,
      );

      print(
        'DEBUG: Criando despesa: ${novaDespesa.descricao} - Mês: ${novaDespesa.mes}/${novaDespesa.ano}',
      );
      final despesaCriada = await _db.createDespesa(novaDespesa);

      // Agendar notificação se tiver vencimento
      if (despesaCriada.diaVencimento != null) {
        try {
          await _notification.agendarNotificacaoVencimento(despesaCriada);
        } catch (e) {
          print('Erro ao agendar notificação: $e');
          // Continua mesmo se a notificação falhar
        }
      }
    }

    if (mesDestino == _mesAtual.month && anoDestino == _mesAtual.year) {
      await carregarDados();
    }
  }

  // Obter despesas agrupadas por categoria
  Map<Categoria, List<Despesa>> getDespesasPorCategoria() {
    final Map<Categoria, List<Despesa>> mapa = {};

    for (var categoria in _categorias) {
      final despesasCategoria = _despesas
          .where((d) => d.categoriaId == categoria.id)
          .toList();

      if (despesasCategoria.isNotEmpty) {
        mapa[categoria] = despesasCategoria;
      }
    }

    return mapa;
  }

  // Cartões de Crédito
  Future<void> adicionarCartaoCredito(CartaoCredito cartao) async {
    await _db.createCartaoCredito(cartao);
    await carregarDados();
  }

  Future<void> atualizarCartaoCredito(CartaoCredito cartao) async {
    await _db.updateCartaoCredito(cartao);
    await carregarDados();
  }

  Future<void> atualizarStatusFatura(
    int cartaoId,
    int mes,
    int ano,
    StatusPagamento status,
  ) async {
    await _db.atualizarStatusFatura(cartaoId, mes, ano, status);
    await carregarDados();
  }

  Future<StatusPagamento?> getStatusFatura(
    int cartaoId,
    int mes,
    int ano,
  ) async {
    return await _db.getStatusFatura(cartaoId, mes, ano);
  }

  Future<int> contarDespesasPorCartao(int cartaoId) async {
    return await _db.contarDespesasPorCartao(cartaoId);
  }

  Future<void> deletarCartaoCredito(int id) async {
    await _db.deleteCartaoCredito(id);
    await carregarDados();
  }
}
