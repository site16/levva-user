// lib/models/enums.dart
// Necessário para Color, se usado em algum enum visual

// Enums fornecidos por você:
enum DeliveryType {
  levvaPlus, // Exemplo: um serviço premium ou com mais benefícios
  levvaMoto, // Entrega/transporte padrão por moto
  levvaRapido, // Exemplo: um serviço de entrega expressa
}

enum VehicleType {
  moto,
  bike,
  // carro, // Exemplo: Adicione outros tipos se necessário no futuro
  // caminhaoPequeno,
}

enum PaymentType {
  dinheiro,
  cartaoCredito, // Mais específico
  cartaoDebito,  // Mais específico
  pix,
  carteiraLevva, cartao, // Pagamento com saldo da carteira do app
}

// Outros Enums que podem ser úteis ou já foram discutidos:

// Para o status da autenticação (usado no AuthProvider)
enum AuthStatus {
  uninitialized,    // Estado inicial, antes de verificar
  authenticated,    // Usuário logado e perfil carregado
  authenticating,   // Processo de login/registro em andamento
  unauthenticated,  // Usuário não logado ou deslogado
  error,            // Ocorreu um erro na autenticação
}

// Para o formulário de cadastro de entregador
enum DocumentType {
  profile,          // Foto de perfil do entregador
  cnh,              // Carteira Nacional de Habilitação
  vehicle,          // Documento do Veículo (ex: CRLV para moto)
  personalId,       // Documento Pessoal (ex: RG para ciclista)
  // Adicione outros tipos de documento conforme necessário
}

enum RegistrationStatus {
  initial,          // Estado inicial do formulário
  loading,          // Submissão em andamento
  success,          // Submissão bem-sucedida
  error, idle,            // Erro na submissão
}

// Para o modelo de descontos (DiscountModel)
enum DiscountType {
  percentage,       // Desconto percentual (ex: 10% OFF)
  fixedValue,       // Desconto de valor fixo (ex: R$5 OFF)
  freeRide,         // Corrida grátis (pode ter um valor máximo)
  // Adicione outros tipos se necessário
}

enum DiscountOrigin {
  campaign,         // Campanhas promocionais gerais
  referral,         // Programa de indicação
  compensation,     // Compensação por algum problema
  loyalty,          // Programa de fidelidade
  firstRide,        // Desconto de primeira corrida
  other,            // Outras origens
}

enum DiscountStatus {
  available,        // Disponível para uso
  used,             // Já utilizado
  expired,          // Prazo de validade expirou
  // Adicione outros status se necessário
}

// Para ajudar a variar o visual dos cards de desconto
enum DiscountCardTheme {
  theme1, // Ex: Laranja/Vermelho
  theme2, // Ex: Verde Escuro
  theme3, // Ex: Azul
  theme4, // Ex: Verde Claro
  theme5, // Ex: Roxo
  defaultTheme,
}

// Adicione quaisquer outros enums que seu aplicativo possa precisar.
// Exemplo:
// enum RideStatus { requested, accepted, ongoing, completed, cancelled }
// enum UserType { passenger, driver }

