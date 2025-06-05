// TODO Implement this library.
import 'package:cloud_firestore/cloud_firestore.dart'; // Necessário para o tipo Timestamp

// Enum para definir os tipos de transação possíveis
enum TransactionType {
  gastoCorrida, // Débito referente a uma corrida/entrega
  deposito, // Crédito na carteira LevvaPay
  saque, // Retirada de fundos da carteira LevvaPay
  bonus, // Crédito de bônus promocional
  ajuste, // Ajuste de saldo (positivo ou negativo) feito por um administrador
  outros, // Outros tipos de transação não especificados
}

class TransactionModel {
  final String
  id; // ID único da transação (geralmente o ID do documento no Firestore)
  final String
  description; // Descrição da transação (ex: "Corrida para Av. Brasil", "Bônus de indicação")
  final double
  amount; // Valor da transação (positivo para créditos, negativo para débitos)
  final Timestamp date; // Data e hora em que a transação ocorreu
  final TransactionType type; // O tipo da transação, usando o enum acima
  final String?
  rideId; // ID da corrida associada, se esta transação for um gasto de corrida

  TransactionModel({
    required this.id,
    required this.description,
    required this.amount,
    required this.date,
    required this.type,
    this.rideId, // Opcional
  });

  /// Factory constructor para criar uma instância de TransactionModel a partir de um DocumentSnapshot do Firestore.
  factory TransactionModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data();

    // Validação para garantir que os dados não são nulos
    if (data == null) {
      throw FirebaseException(
        plugin: 'Firestore',
        code: 'data-null',
        message: "Dados da transação não encontrados para o ID: ${snapshot.id}",
      );
    }

    return TransactionModel(
      id: snapshot.id,
      description: data['description'] as String? ?? 'Transação sem descrição',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      date:
          data['date'] as Timestamp? ??
          Timestamp.now(), // Fallback para data atual se não existir
      type: TransactionType.values.firstWhere(
        (e) =>
            e.name ==
            (data['type']
                as String?), // Compara pelo nome do enum (ex: 'gastoCorrida')
        orElse:
            () =>
                TransactionType
                    .outros, // Fallback para 'outros' se o tipo não for reconhecido
      ),
      rideId: data['rideId'] as String?,
    );
  }

  /// Converte a instância de TransactionModel para um Map<String, dynamic> para ser salvo no Firestore.
  Map<String, dynamic> toFirestore() {
    return {
      'description': description,
      'amount': amount,
      'date': date,
      'type':
          type.name, // Salva o nome do enum como uma string (ex: "gastoCorrida")
      if (rideId != null) 'rideId': rideId,
      // O 'id' geralmente não é salvo dentro do documento, pois ele é o ID do próprio documento.
    };
  }
}
