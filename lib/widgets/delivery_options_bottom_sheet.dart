import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/enums.dart';
import '../providers/ride_request_provider.dart';
import 'section_title.dart'; // Seu widget de título de seção

class DeliveryOptionsBottomSheet extends StatefulWidget {
  const DeliveryOptionsBottomSheet({super.key});

  @override
  State<DeliveryOptionsBottomSheet> createState() =>
      _DeliveryOptionsBottomSheetState();
}

class _DeliveryOptionsBottomSheetState
    extends State<DeliveryOptionsBottomSheet> {
  DeliveryType? _selectedDeliveryType;
  VehicleType? _selectedVehicleType;
  PaymentType? _selectedPaymentType;
  double _calculatedPrice = 0.0; // Preço base ou inicial

  // Valores base para simulação de cálculo de preço
  static const double _basePriceLevvaMoto = 5.0;
  static const double _basePriceLevvaBike = 4.0;
  static const double _basePriceLevvaPlus = 7.0;

  static const double _multiplierLevvaRapido = 1.2;
  // Outros multiplicadores ou lógicas podem ser adicionados

  @override
  void initState() {
    super.initState();
    // Inicializar com valores do provider se já existirem?
    // Ou começar com valores padrão. Por simplicidade, começaremos nulos
    // e o primeiro RadioListTile de cada grupo pode ser o padrão.
    // Se desejar pré-selecionar, você pode buscar do RideRequestProvider aqui.

    // Definindo padrões para visualização inicial e cálculo de preço
    _selectedDeliveryType = DeliveryType.levvaRapido;
    _selectedVehicleType = VehicleType.moto;
    _selectedPaymentType = PaymentType.pix;
    _recalculatePrice();
  }

  void _recalculatePrice() {
    double newPrice = 0.0;
    final rideProvider = Provider.of<RideRequestProvider>(
      context,
      listen: false,
    );

    // Lógica de cálculo de preço SIMULADA.
    // Você deve integrar isso com a lógica de distância/tempo do seu RideRequestProvider
    // ou com um serviço de backend.
    // Este é um exemplo muito básico.
    int? distance = rideProvider.distanceValue; // em metros
    double baseFare = 0;

    if (_selectedVehicleType == VehicleType.moto) {
      baseFare = _basePriceLevvaMoto;
    } else if (_selectedVehicleType == VehicleType.bike) {
      baseFare = _basePriceLevvaBike;
    }
    // Adicione mais tipos de veículo se necessário

    newPrice = baseFare;

    if (_selectedDeliveryType == DeliveryType.levvaPlus) {
      newPrice +=
          _basePriceLevvaPlus; // Exemplo: LevvaPlus tem um adicional fixo
    } else if (_selectedDeliveryType == DeliveryType.levvaRapido) {
      newPrice *= _multiplierLevvaRapido;
    }

    // Adicionar fator distância (exemplo simples)
    if (distance != null) {
      newPrice += (distance / 1000) * 0.5; // R$0.50 por km
    }

    // Simulação de taxa de pagamento
    if (_selectedPaymentType == PaymentType.cartao) {
      newPrice *= 1.03; // Taxa de 3% para cartão (exemplo)
    }

    setState(() {
      _calculatedPrice =
          newPrice < 5.00 ? 5.00 : newPrice; // Preço mínimo de R$5,00
    });

    // Atualiza o preço no provider para que outras partes da UI possam refletir
    // a mudança em tempo real, se necessário, antes da confirmação final.
    Provider.of<RideRequestProvider>(
      context,
      listen: false,
    ).updateCalculatedPrice(_calculatedPrice);
  }

  void _confirmOptions() {
    if (_selectedDeliveryType == null ||
        _selectedVehicleType == null ||
        _selectedPaymentType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecione todas as opções.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Provider.of<RideRequestProvider>(context, listen: false).setDeliveryOptions(
      deliveryType: _selectedDeliveryType!,
      vehicleType: _selectedVehicleType!,
      paymentType: _selectedPaymentType!,
      calculatedPrice: _calculatedPrice,
    );
    Navigator.pop(context); // Fecha o BottomSheet
    // A HomeScreen ou a tela que chamou este bottom sheet
    // deve ouvir as mudanças no RideRequestProvider e,
    // se o status for selectingOptions (ou um novo status de confirmação),
    // pode então chamar rideRequestProvider.searchForDriver()
    // que, por sua vez, deve abrir o SearchingDriverDialog.
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Consumir RideRequestProvider para exibir o preço calculado em tempo real
    final currentPriceFromProvider =
        context.watch<RideRequestProvider>().calculatedPrice;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          color: theme.cardColor, // Usa a cor do card do tema
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20.0),
            topRight: Radius.circular(20.0),
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Opções de Entrega',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              // Seção Tipo de Entrega
              const SectionTitle('Tipo de Entrega'),
              ...DeliveryType.values.map((type) {
                String title;
                switch (type) {
                  case DeliveryType.levvaPlus:
                    title = 'Levva Plus (Mais Rápido e Seguro)';
                    break;
                  case DeliveryType.levvaMoto:
                    title = 'Levva Moto (Padrão)';
                    break;
                  case DeliveryType.levvaRapido:
                    title = 'Levva Rápido (Econômico)';
                    break;
                }
                return RadioListTile<DeliveryType>(
                  title: Text(title),
                  value: type,
                  groupValue: _selectedDeliveryType,
                  onChanged: (DeliveryType? value) {
                    setState(() {
                      _selectedDeliveryType = value;
                      _recalculatePrice();
                    });
                  },
                  activeColor: theme.primaryColor,
                );
              }).toList(),
              const SizedBox(height: 10),

              // Seção Tipo de Veículo
              const SectionTitle('Tipo de Veículo'),
              ...VehicleType.values.map((type) {
                String title;
                switch (type) {
                  case VehicleType.moto:
                    title = 'Moto';
                    break;
                  case VehicleType.bike:
                    title = 'Bike';
                    break;
                }
                return RadioListTile<VehicleType>(
                  title: Text(title),
                  value: type,
                  groupValue: _selectedVehicleType,
                  onChanged: (VehicleType? value) {
                    setState(() {
                      _selectedVehicleType = value;
                      _recalculatePrice();
                    });
                  },
                  activeColor: theme.primaryColor,
                );
              }).toList(),
              const SizedBox(height: 10),

              // Seção Forma de Pagamento
              const SectionTitle('Forma de Pagamento'),
              ...PaymentType.values.map((type) {
                String title;
                switch (type) {
                  case PaymentType.dinheiro:
                    title = 'Dinheiro';
                    break;
                  case PaymentType.cartao:
                    title = 'Cartão (será solicitado na entrega)';
                    break;
                  case PaymentType.pix:
                    title = 'PIX (via app ou na entrega)';
                    break;
                  case PaymentType.cartaoCredito:
                    // TODO: Handle this case.
                    throw UnimplementedError();
                  case PaymentType.cartaoDebito:
                    // TODO: Handle this case.
                    throw UnimplementedError();
                  case PaymentType.carteiraLevva:
                    // TODO: Handle this case.
                    throw UnimplementedError();
                }
                return RadioListTile<PaymentType>(
                  title: Text(title),
                  value: type,
                  groupValue: _selectedPaymentType,
                  onChanged: (PaymentType? value) {
                    setState(() {
                      _selectedPaymentType = value;
                      _recalculatePrice();
                    });
                  },
                  activeColor: theme.primaryColor,
                );
              }).toList(),
              const SizedBox(height: 20),

              // Exibição do Preço Calculado
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Preço Estimado:',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'R\$ ${currentPriceFromProvider.toStringAsFixed(2)}', // Usa o preço do provider
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 25),

              ElevatedButton(
                style:
                    theme
                        .elevatedButtonTheme
                        .style, // Usa o estilo de botão do tema
                onPressed: _confirmOptions,
                child: const Text('Confirmar e Procurar Entregador'),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
