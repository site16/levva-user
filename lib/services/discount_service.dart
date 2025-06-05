// lib/services/discount_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart'; // Color não é mais usado diretamente aqui para cardColor
import '../models/discount_model.dart';
import 'package:uuid/uuid.dart';

class DiscountService {
  final Uuid _uuid = const Uuid();
  // Se você fosse usar Firestore:
  // final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<DiscountModel>> getDiscountsForUser(String userId) async {
    // Simula uma chamada de API com delay
    await Future.delayed(const Duration(milliseconds: 700));

    // TODO: Substituir esta lógica por uma busca real no Firestore
    // Exemplo de como seria com Firestore (descomente e adapte):
    /*
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('discounts')
          // .where('validUntil', isGreaterThanOrEqualTo: Timestamp.now()) // Para buscar apenas válidos, por exemplo
          .orderBy('validUntil', descending: true)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return []; // Retorna lista vazia se não houver descontos
      }

      return querySnapshot.docs
          .map((doc) => DiscountModel.fromFirestore(doc)) // Assumindo que você tem fromFirestore no seu modelo
          .toList();
    } catch (e) {
      print("Erro ao buscar descontos no Firestore: $e");
      // Você pode querer lançar o erro ou retornar uma lista vazia com uma mensagem de erro
      // throw Exception('Falha ao carregar descontos.');
      return []; // Retorna lista vazia em caso de erro por enquanto
    }
    */

    // Dados simulados ATUALIZADOS com partnerName e cardTheme
    return [
      DiscountModel(
        id: _uuid.v4(),
        title: 'Sua Primeira Levva com 20% OFF!',
        description: 'Use o cupom na sua primeira corrida e economize 20%. Aproveite!',
        code: 'LEVVA20PRIMEIRA',
        type: DiscountType.percentage,
        value: 20,
        validFrom: Timestamp.fromDate(DateTime(2025, 5, 1)),
        validUntil: Timestamp.fromDate(DateTime(2025, 6, 30)), // Válido
        termsAndConditions: 'Válido apenas para novos usuários. Não acumulativo. Aplicável a corridas de até R\$50.',
        origin: DiscountOrigin.campaign,
        partnerName: 'Levva', // Adicionado
        imageUrl: 'https://images.unsplash.com/photo-1579547945413-497518922706?ixlib=rb-1.2.1&q=80&fm=jpg&crop=entropy&cs=tinysrgb&w=800&h=400&fit=crop',
        cardTheme: DiscountCardTheme.theme1, // Substituído cardColor por cardTheme
        isUsed: false,
      ),
      DiscountModel(
        id: _uuid.v4(),
        title: 'R\$ 10 para sua próxima corrida',
        description: 'Presente da Levva para você continuar explorando a cidade conosco.',
        code: 'GANHEI10LEVVA',
        type: DiscountType.fixedValue,
        value: 10.00,
        validFrom: Timestamp.fromDate(DateTime(2025, 5, 15)),
        validUntil: Timestamp.fromDate(DateTime(2025, 6, 15)), // Válido
        termsAndConditions: 'Válido para uma única corrida. O valor da corrida deve ser superior a R\$10.',
        origin: DiscountOrigin.loyalty,
        partnerName: 'Levva Club', // Adicionado
        imageUrl: 'https://images.unsplash.com/photo-1529333166437-775054dd585b?ixlib=rb-1.2.1&q=80&fm=jpg&crop=entropy&cs=tinysrgb&w=800&h=400&fit=crop',
        cardTheme: DiscountCardTheme.theme2, // Substituído cardColor por cardTheme
        isUsed: false,
      ),
      DiscountModel(
        id: _uuid.v4(),
        title: 'Corrida Grátis (Compensação)',
        description: 'Pedimos desculpas por qualquer inconveniente. Use este voucher para uma corrida gratuita.',
        type: DiscountType.freeRide,
        value: 15.00, // Valor máximo da corrida grátis
        validFrom: Timestamp.fromDate(DateTime(2025, 5, 10)),
        validUntil: Timestamp.fromDate(DateTime(2025, 6, 10)), // Válido
        termsAndConditions: 'Corrida gratuita até R\$15. Não reembolsável.',
        origin: DiscountOrigin.compensation,
        partnerName: 'Suporte Levva', // Adicionado
        isUsed: true, // Marcado como usado (para a aba "Histórico")
        imageUrl: 'https://images.unsplash.com/photo-1517673400267-0251440c45dc?ixlib=rb-1.2.1&q=80&fm=jpg&crop=entropy&cs=tinysrgb&w=800&h=400&fit=crop',
        cardTheme: DiscountCardTheme.theme3, // Substituído cardColor por cardTheme
      ),
      DiscountModel(
        id: _uuid.v4(),
        title: '10% OFF - Especial Dia dos Pais',
        description: 'Desconto especial em todas as corridas para celebrar!',
        code: 'PAILEVVA10',
        type: DiscountType.percentage,
        value: 10,
        validFrom: Timestamp.fromDate(DateTime(2024, 8, 1)), // Expirado (ano passado)
        validUntil: Timestamp.fromDate(DateTime(2024, 8, 15)), // Expirado
        termsAndConditions: 'Válido para todas as corridas durante o período da promoção.',
        origin: DiscountOrigin.campaign,
        partnerName: 'Promoções Levva', // Adicionado
        isUsed: false, // Pode não ter sido usado, mas expirou
        imageUrl: 'https://images.unsplash.com/photo-1589051063493-t30ba1e04538?ixlib=rb-1.2.1&q=80&fm=jpg&crop=entropy&cs=tinysrgb&w=800&h=400&fit=crop',
        cardTheme: DiscountCardTheme.theme4, // Substituído cardColor por cardTheme
      ),
       DiscountModel(
        id: _uuid.v4(),
        title: 'R\$ 5 para indicar um amigo',
        description: 'Indique um amigo e ganhe R\$5 quando ele completar a primeira corrida.',
        code: 'INDICOUGANHOU5',
        type: DiscountType.fixedValue,
        value: 5.00,
        validFrom: Timestamp.fromDate(DateTime(2025, 1, 1)),
        validUntil: Timestamp.fromDate(DateTime(2025, 12, 31)), // Válido o ano todo
        termsAndConditions: 'Crédito aplicado após a primeira corrida do amigo indicado.',
        origin: DiscountOrigin.referral,
        partnerName: 'Levva Indica', // Adicionado
        imageUrl: 'https://images.unsplash.com/photo-1600880292210-859310078799?ixlib=rb-1.2.1&q=80&fm=jpg&crop=entropy&cs=tinysrgb&w=800&h=400&fit=crop',
        cardTheme: DiscountCardTheme.theme5, // Usando outro tema
        isUsed: false,
      ),
    ];
  }

  // TODO: Adicionar métodos para marcar um cupom como usado, se necessário.
  // Ex: Future<void> markDiscountAsUsed(String userId, String discountId) async { ... }
}