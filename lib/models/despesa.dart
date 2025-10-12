enum StatusPagamento { pago, agendado, debitoAutomatico, aPagar }

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
  }) : dataCriacao = dataCriacao ?? DateTime.now();

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
  }) {
    return Despesa(
      id: id ?? this.id,
      descricao: descricao ?? this.descricao,
      valor: valor ?? this.valor,
      categoriaId: categoriaId ?? this.categoriaId,
      mes: mes ?? this.mes,
      ano: ano ?? this.ano,
      diaVencimento: diaVencimento ?? this.diaVencimento,
      status: status ?? this.status,
      isFixa: isFixa ?? this.isFixa,
      dataCriacao: dataCriacao ?? this.dataCriacao,
    );
  }
}
