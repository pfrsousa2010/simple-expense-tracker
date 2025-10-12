class FonteRenda {
  final int? id;
  final String nome;
  final double valor;
  final int mes;
  final int ano;

  FonteRenda({
    this.id,
    required this.nome,
    required this.valor,
    required this.mes,
    required this.ano,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'nome': nome,
      'valor': valor,
      'mes': mes,
      'ano': ano,
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
    );
  }

  FonteRenda copyWith({
    int? id,
    String? nome,
    double? valor,
    int? mes,
    int? ano,
  }) {
    return FonteRenda(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      valor: valor ?? this.valor,
      mes: mes ?? this.mes,
      ano: ano ?? this.ano,
    );
  }
}
