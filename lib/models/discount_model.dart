// lib/models/discount_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Para IconData
// intl não é usado diretamente neste arquivo de modelo, mas pode ser em widgets que o consomem.

enum DiscountType { percentage, fixedValue, freeRide }

enum DiscountOrigin { campaign, referral, compensation, loyalty, other }

enum DiscountCardTheme { theme1, theme2, theme3, theme4, theme5, defaultTheme /* Adicionado defaultTheme se não existir */ }

class DiscountModel {
  final String id;
  final String title; // Ex: "25% OFF" ou "Até R$10 de Desconto"
  final String description; // Ex: "Desconto em Pacotes" ou "Na sua primeira corrida"
  final String? code; // O código do cupom em si
  final DiscountType type;
  final double value; // Ex: 15 para 15%, 5.00 para R$5,00
  final Timestamp validFrom;
  final Timestamp validUntil;
  final String? termsAndConditions;
  final DiscountOrigin origin;
  bool isUsed;
  final String? imageUrl; // URL para uma imagem/banner opcional no card
  final String partnerName; // Ex: "Levva" ou nome do parceiro
  final DiscountCardTheme cardTheme; // Para ajudar a estilizar o card (se ainda usado para algo)

  // --- NOVO CAMPO ADICIONADO ---
  final IconData? iconData; // Ícone específico para este tipo de desconto

  DiscountModel({
    required this.id,
    required this.title,
    required this.description,
    this.code,
    required this.type,
    required this.value,
    required this.validFrom,
    required this.validUntil,
    this.termsAndConditions,
    this.origin = DiscountOrigin.campaign,
    this.isUsed = false,
    this.imageUrl,
    required this.partnerName,
    this.cardTheme = DiscountCardTheme.defaultTheme, // Padrão ajustado
    this.iconData, // --- Adicionado ao construtor ---
  });

  String get displayValue {
    final currencyFormatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    switch (type) {
      case DiscountType.percentage:
        return '${value.toInt()}% OFF';
      case DiscountType.fixedValue:
        return '${currencyFormatter.format(value)} OFF';
      case DiscountType.freeRide:
        return 'Corrida Grátis'; // Ou o valor da corrida se aplicável
      // default: // Removido pois todos os casos do enum são cobertos
      //   return '';
    }
  }

  String get validityPeriod {
    final DateFormat dateFormatter = DateFormat('dd/MM/yy', 'pt_BR');
    return 'Válido de ${dateFormatter.format(validFrom.toDate())} até ${dateFormatter.format(validUntil.toDate())}';
  }

  bool get isValidNow {
// ou DateTime.now() se comparar com DateTime
    return !isUsed &&
        validFrom.toDate().isBefore(DateTime.now().add(const Duration(days: 1))) && // Garante que o dia de início já chegou ou é hoje
        validUntil.toDate().isAfter(DateTime.now().subtract(const Duration(days: 1))); // Garante que o dia de fim ainda não passou completamente
  }

  factory DiscountModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;

    // Lógica para determinar o iconData com base no tipo de desconto
    IconData? determinedIcon;
    DiscountType discountType = DiscountType.values.firstWhere(
        (e) => e.toString() == data['type'],
        orElse: () => DiscountType.fixedValue);

    switch (discountType) {
      case DiscountType.percentage:
        determinedIcon = Icons.percent_outlined;
        break;
      case DiscountType.fixedValue:
        determinedIcon = Icons.local_offer_outlined; // Ícone genérico de oferta
        break;
      case DiscountType.freeRide:
        determinedIcon = Icons.two_wheeler; // Exemplo para corrida grátis (moto)
        break;
      // Adicione mais casos aqui se tiver mais DiscountType
      // e queira ícones diferentes para eles.
      // A imagem de design mostrava ícones como:
      // Icons.receipt_long_outlined (documento/recibo)
      // Icons.scale_outlined (balança)
      // Icons.card_giftcard_outlined (presente)
      // Icons.groups_outlined (grupo/indicação)
      // Você pode usar um campo 'iconName' (String) no Firestore e mapear aqui.
    }

    return DiscountModel(
      id: doc.id,
      title: data['title'] as String? ?? 'Desconto Especial',
      description: data['description'] as String? ?? 'Aproveite esta oferta!',
      code: data['code'] as String?,
      type: discountType,
      value: (data['value'] as num?)?.toDouble() ?? 0.0,
      validFrom: data['validFrom'] as Timestamp? ?? Timestamp.now(),
      validUntil: data['validUntil'] as Timestamp? ?? Timestamp.now(),
      termsAndConditions: data['termsAndConditions'] as String?,
      origin: DiscountOrigin.values.firstWhere(
          (e) => e.toString() == data['origin'],
          orElse: () => DiscountOrigin.campaign),
      isUsed: data['isUsed'] as bool? ?? false,
      imageUrl: data['imageUrl'] as String?,
      partnerName: data['partnerName'] as String? ?? 'Levva',
      cardTheme: DiscountCardTheme.values.firstWhere(
          (e) => e.toString().split('.').last == (data['cardTheme'] as String? ?? 'defaultTheme'), // Ajuste para pegar o nome do enum
          orElse: () => DiscountCardTheme.defaultTheme),
      iconData: determinedIcon, // --- Atribuindo o ícone determinado ---
    );
  }

  // Se você tiver um método toJson, lembre-se que IconData não é diretamente
  // serializável para JSON. Você normalmente armazenaria um identificador (string/enum)
  // no Firestore/JSON que você usaria para escolher o ícone na UI (como feito no fromFirestore).
  /*
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      // ... outros campos
      // 'iconIdentifier': _getIconIdentifierFromData(iconData), // Exemplo
    };
  }
  */
}