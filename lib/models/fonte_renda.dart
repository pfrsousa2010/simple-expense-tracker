class FonteRenda {
  final int? id;
  final String nome;
  final double valor;
  final int mes;
  final int ano;
  final int? diaRecebimento;

  FonteRenda({
    this.id,
    required this.nome,
    required this.valor,
    required this.mes,
    required this.ano,
    this.diaRecebimento,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'nome': nome,
      'valor': valor,
      'mes': mes,
      'ano': ano,
      'diaRecebimento': diaRecebimento,
    };

    // Só incluir o id se não for null
    if (id != null) {
      map['id'] = id;
    }

    return map;
  }

  factory FonteRenda.fromMap(Map<String, dynamic> map) {
    return FonteRenda(
      id: map['id'],
      nome: map['nome'],
      valor: map['valor'],
      mes: map['mes'],
      ano: map['ano'],
      diaRecebimento: map['diaRecebimento'],
    );
  }

  FonteRenda copyWith({
    int? id,
    String? nome,
    double? valor,
    int? mes,
    int? ano,
    int? diaRecebimento,
  }) {
    return FonteRenda(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      valor: valor ?? this.valor,
      mes: mes ?? this.mes,
      ano: ano ?? this.ano,
      diaRecebimento: diaRecebimento ?? this.diaRecebimento,
    );
  }
}
