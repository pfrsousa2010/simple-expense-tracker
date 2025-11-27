import 'package:flutter/material.dart';
import 'despesa.dart';

class CartaoCredito {
  final int? id;
  final String nome;
  final String banco;
  final String numero; // Últimos 4 dígitos ou número completo
  final int cor; // Valor da cor em formato int
  final int? diaVencimento; // Dia do mês de vencimento da fatura
  final int? diaFechamento; // Dia do mês de fechamento da fatura
  final StatusPagamento status; // Status do pagamento da fatura

  CartaoCredito({
    this.id,
    required this.nome,
    required this.banco,
    required this.numero,
    this.cor = 0xFF2196F3, // Azul padrão
    this.diaVencimento,
    this.diaFechamento,
    this.status = StatusPagamento.aPagar, // Padrão: A Pagar
  });

  Color get color => Color(cor);

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'nome': nome,
      'banco': banco,
      'numero': numero,
      'cor': cor,
      'diaVencimento': diaVencimento,
      'diaFechamento': diaFechamento,
      'status': status.index,
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
      diaVencimento: map['diaVencimento'],
      diaFechamento: map['diaFechamento'],
      status: map['status'] != null
          ? StatusPagamento.values[map['status']]
          : StatusPagamento.aPagar,
    );
  }

  CartaoCredito copyWith({
    int? id,
    String? nome,
    String? banco,
    String? numero,
    int? cor,
    int? diaVencimento,
    int? diaFechamento,
    StatusPagamento? status,
  }) {
    return CartaoCredito(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      banco: banco ?? this.banco,
      numero: numero ?? this.numero,
      cor: cor ?? this.cor,
      diaVencimento: diaVencimento ?? this.diaVencimento,
      diaFechamento: diaFechamento ?? this.diaFechamento,
      status: status ?? this.status,
    );
  }

  // Retorna os últimos 4 dígitos do número
  String get ultimosDigitos {
    if (numero.isEmpty) return '';
    if (numero.length <= 4) return numero;
    return numero.substring(numero.length - 4);
  }

  // Retorna o número formatado (**** **** **** 1234)
  String get numeroFormatado {
    if (numero.isEmpty) return '**** **** **** ****';
    final ultimos = ultimosDigitos;
    return '**** **** **** $ultimos';
  }
}

