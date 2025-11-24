import 'package:flutter/material.dart';

class CartaoCredito {
  final int? id;
  final String nome;
  final String banco;
  final String numero; // Últimos 4 dígitos ou número completo
  final int cor; // Valor da cor em formato int

  CartaoCredito({
    this.id,
    required this.nome,
    required this.banco,
    required this.numero,
    this.cor = 0xFF2196F3, // Azul padrão
  });

  Color get color => Color(cor);

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'nome': nome,
      'banco': banco,
      'numero': numero,
      'cor': cor,
    };

    if (id != null) {
      map['id'] = id;
    }

    return map;
  }

  factory CartaoCredito.fromMap(Map<String, dynamic> map) {
    return CartaoCredito(
      id: map['id'],
      nome: map['nome'],
      banco: map['banco'],
      numero: map['numero'],
      cor: map['cor'] ?? 0xFF2196F3,
    );
  }

  CartaoCredito copyWith({
    int? id,
    String? nome,
    String? banco,
    String? numero,
    int? cor,
  }) {
    return CartaoCredito(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      banco: banco ?? this.banco,
      numero: numero ?? this.numero,
      cor: cor ?? this.cor,
    );
  }

  // Retorna os últimos 4 dígitos do número
  String get ultimosDigitos {
    if (numero.length <= 4) return numero;
    return numero.substring(numero.length - 4);
  }

  // Retorna o número formatado (**** **** **** 1234)
  String get numeroFormatado {
    final ultimos = ultimosDigitos;
    return '**** **** **** $ultimos';
  }
}

