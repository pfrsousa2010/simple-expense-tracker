class Categoria {
  final int? id;
  final String nome;
  final String icone;
  final double? limiteGasto;
  final bool isPadrao;

  Categoria({
    this.id,
    required this.nome,
    required this.icone,
    this.limiteGasto,
    this.isPadrao = false,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'nome': nome,
      'icone': icone,
      'limiteGasto': limiteGasto,
      'isPadrao': isPadrao ? 1 : 0,
    };

    // Só incluir o id se não for null
    if (id != null) {
      map['id'] = id;
    }

    return map;
  }

  factory Categoria.fromMap(Map<String, dynamic> map) {
    return Categoria(
      id: map['id'],
      nome: map['nome'],
      icone: map['icone'],
      limiteGasto: map['limiteGasto'],
      isPadrao: map['isPadrao'] == 1,
    );
  }

  Categoria copyWith({
    int? id,
    String? nome,
    String? icone,
    double? limiteGasto,
    bool? isPadrao,
  }) {
    return Categoria(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      icone: icone ?? this.icone,
      limiteGasto: limiteGasto ?? this.limiteGasto,
      isPadrao: isPadrao ?? this.isPadrao,
    );
  }
}
