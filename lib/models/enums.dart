// Enums para o app Levva

// --- TIPOS DE SERVIÇO (Transporte de Passageiro ou Entrega de Produto) ---
enum ServiceType {
  passenger, // Transporte de Passageiro
  delivery,  // Envio de Produto
}

// --- DELIVERY/VEÍCULO/PAGAMENTO ---
enum DeliveryType {
  levvaPlus,   // Serviço premium/benefícios
  levvaMoto,   // Padrão por moto
  levvaRapido, // Entrega expressa
}

enum VehicleType {
  moto,
  bike,
  // carro, // Adicione outros se necessário
}

// TIPOS DE PAGAMENTO
enum PaymentType {
  dinheiro,
  cartaoCredito,
  cartaoDebito,
  pix,
  carteiraLevva,
  cartao, // Pagamento via saldo Levva ou cartão
}

// --- AUTENTICAÇÃO E CADASTRO ---
enum AuthStatus {
  uninitialized,
  authenticated,
  authenticating,
  unauthenticated,
  error,
}

enum DocumentType {
  profile,
  cnh,
  vehicle,
  personalId,
}

enum RegistrationStatus {
  initial,
  loading,
  success,
  error,
  idle,
}

// --- DESCONTOS ---
enum DiscountType {
  percentage,
  fixedValue,
  freeRide,
}

enum DiscountOrigin {
  campaign,
  referral,
  compensation,
  loyalty,
  firstRide,
  other,
}

enum DiscountStatus {
  available,
  used,
  expired,
}

enum DiscountCardTheme {
  theme1,
  theme2,
  theme3,
  theme4,
  theme5,
  defaultTheme,
}

// --- STATUS DE CORRIDA (detalhado, igual provider) ---
enum RideRequestStatus {
  none,
  originSelected,
  destinationSelected,
  calculatingRoute,
  routeCalculated,
  selectingOptions,
  searchingDriver,
  driverFound,
  driverAssigned,
  rideAccepted,
  driverEnRouteToPickup,
  driverArrivedAtPickup,
  rideInProgressToDestination,
  rideCompleted,
  rideCancelledByUser,
  rideCancelledByDriver,
  rideFailed,
  error,
  notFound,
  unknown,
}

// --- Outros exemplos úteis ---
// enum RideStatus { requested, accepted, ongoing, completed, cancelled }
// enum UserType { passenger, driver }

// Mantenha este arquivo como repositório central de enums do app Levva!
// Adicione ou ajuste conforme crescer o app.