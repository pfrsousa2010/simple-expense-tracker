enum StatusPagamento { pago, agendado, debitoAutomatico, aPagar }

enum TipoPagamentoCartao { vista, parcelado, recorrente }

class Despesa {
  final int? id;
  final String descricao;
  final double valor;
  final int categoriaId;
  final int mes;
  final int ano;
  final int? diaVencimento;
  final StatusPagamento status;
  final bool isFixa;
  final DateTime dataCriacao;
  final DateTime? dataCompra; // Data da compra (apenas para despesas não fixas)
  // Campos para despesas de cartão de crédito
  final int? cartaoCreditoId;
  final String? estabelecimento;
  final bool isCompraOnline;
  final TipoPagamentoCartao? tipoPagamento;
  final int? numeroParcela;
  final int? totalParcelas;
  final String? parcelaId; // ID único para agrupar parcelas

  Despesa({
    this.id,
    required this.descricao,
    required this.valor,
    required this.categoriaId,
    required this.mes,
    required this.ano,
    this.diaVencimento,
    required this.status,
    this.isFixa = false,
    DateTime? dataCriacao,
    this.dataCompra,
    this.cartaoCreditoId,
    this.estabelecimento,
    this.isCompraOnline = false,
    this.tipoPagamento,
    this.numeroParcela,
    this.totalParcelas,
    this.parcelaId,
  }) : dataCriacao = dataCriacao ?? DateTime.now();

  bool get isCartaoCredito => cartaoCreditoId != null;

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'descricao': descricao,
      'valor': valor,
      'categoriaId': categoriaId,
      'mes': mes,
      'ano': ano,
      'diaVencimento': diaVencimento,
      'status': status.index,
      'isFixa': isFixa ? 1 : 0,
      'dataCriacao': dataCriacao.toIso8601String(),
      'dataCompra': dataCompra?.toIso8601String(),
      'cartaoCreditoId': cartaoCreditoId,
      'estabelecimento': estabelecimento,
      'isCompraOnline': isCompraOnline ? 1 : 0,
      'tipoPagamento': tipoPagamento?.index,
      'numeroParcela': numeroParcela,
      'totalParcelas': totalParcelas,
      'parcelaId': parcelaId,
    };

    // Só incluir o id se não for null
    if (id != null) {
      map['id'] = id;
    }

    return map;
  }

  factory Despesa.fromMap(Map<String, dynamic> map) {
    return Despesa(
      id: map['id'],
      descricao: map['descricao'],
      valor: map['valor'],
      categoriaId: map['categoriaId'],
      mes: map['mes'],
      ano: map['ano'],
      diaVencimento: map['diaVencimento'],
      status: StatusPagamento.values[map['status']],
      isFixa: map['isFixa'] == 1,
      dataCriacao: DateTime.parse(map['dataCriacao']),
      dataCompra: map['dataCompra'] != null
          ? DateTime.parse(map['dataCompra'])
          : null,
      cartaoCreditoId: map['cartaoCreditoId'],
      estabelecimento: map['estabelecimento'],
      isCompraOnline: (map['isCompraOnline'] ?? 0) == 1,
      tipoPagamento: map['tipoPagamento'] != null
          ? TipoPagamentoCartao.values[map['tipoPagamento']]
          : null,
      numeroParcela: map['numeroParcela'],
      totalParcelas: map['totalParcelas'],
      parcelaId: map['parcelaId'],
    );
  }

  Despesa copyWith({
    int? id,
    String? descricao,
    double? valor,
    int? categoriaId,
    int? mes,
    int? ano,
    int? diaVencimento,
    StatusPagamento? status,
    bool? isFixa,
    DateTime? dataCriacao,
    DateTime? dataCompra,
    bool clearId = false,
    int? cartaoCreditoId,
    String? estabelecimento,
    bool? isCompraOnline,
    TipoPagamentoCartao? tipoPagamento,
    int? numeroParcela,
    int? totalParcelas,
    String? parcelaId,
  }) {
    return Despesa(
      id: clearId ? null : (id ?? this.id),
      descricao: descricao ?? this.descricao,
      valor: valor ?? this.valor,
      categoriaId: categoriaId ?? this.categoriaId,
      mes: mes ?? this.mes,
      ano: ano ?? this.ano,
      diaVencimento: diaVencimento ?? this.diaVencimento,
      status: status ?? this.status,
      isFixa: isFixa ?? this.isFixa,
      dataCriacao: dataCriacao ?? this.dataCriacao,
      dataCompra: dataCompra ?? this.dataCompra,
      cartaoCreditoId: cartaoCreditoId ?? this.cartaoCreditoId,
      estabelecimento: estabelecimento ?? this.estabelecimento,
      isCompraOnline: isCompraOnline ?? this.isCompraOnline,
      tipoPagamento: tipoPagamento ?? this.tipoPagamento,
      numeroParcela: numeroParcela ?? this.numeroParcela,
      totalParcelas: totalParcelas ?? this.totalParcelas,
      parcelaId: parcelaId ?? this.parcelaId,
    );
  }
}
