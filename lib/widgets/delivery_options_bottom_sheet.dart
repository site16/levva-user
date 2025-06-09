import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../models/enums.dart';
import '../providers/ride_request_provider.dart';
import '../providers/auth_provider.dart';
import 'section_title.dart';
import 'searching_driver_dialog.dart';

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
  double _calculatedPrice = 0.0;

  // Passageiro - quem vai?
  String _whoIsGoing = "eu"; // "eu" ou "outra"
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _cpfController = TextEditingController();
  final TextEditingController _cellController = TextEditingController();

  final TextEditingController _otherNameController = TextEditingController();
  final TextEditingController _otherSurnameController = TextEditingController();
  final TextEditingController _otherCpfController = TextEditingController();
  final TextEditingController _otherCellController = TextEditingController();

  final TextEditingController _changeForController = TextEditingController();

  // Produto
  String _productDescription = '';
  double _productWeight = 0.0;

  // --- Enviar: Campos do destinatário e item (pegos do código original do "enviar")
  final TextEditingController _receiverNameController = TextEditingController();
  final TextEditingController _receiverCellController = TextEditingController();
  String? _selectedItemType;
  final List<String> _itemTypes = [
    'Alimentação',
    'Eletrônicos',
    'Vestuário',
    'Livros/Documentos',
    'Itens pessoais',
    'Outros'
  ];
  final TextEditingController _otherItemObservationController = TextEditingController();

  final _cpfFormatter = MaskTextInputFormatter(
    mask: '###.###.###-##',
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  final _cellFormatter = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  @override
  void initState() {
    super.initState();
    _selectedDeliveryType = DeliveryType.levvaRapido;
    _selectedVehicleType = VehicleType.moto;
    _selectedPaymentType = PaymentType.dinheiro;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _recalculatePrice();
      _loadProfileDataIfEu();
    });
  }

  void _loadProfileDataIfEu() {
    if (_whoIsGoing == "eu") {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.currentUser;
      _nameController.text = user?.name ?? "";
      _surnameController.text = user?.lastName ?? "";
      _cellController.text = user?.phoneNumber ?? "";
      _cpfController.text = _maskCpfPartial(user?.cpf ?? "");
    }
  }

  void _recalculatePrice() {
    double newPrice = 5.0;
    final rideProvider = Provider.of<RideRequestProvider>(
      context,
      listen: false,
    );
    int? distance = rideProvider.distanceValue;
    // Moto mais cara, igual ao seu código de "enviar"
    if (_selectedVehicleType == VehicleType.moto) {
      newPrice += 2.0;
    }
    if (_selectedPaymentType == PaymentType.cartao) {
      newPrice *= 1.03;
    }
    if (distance != null) {
      newPrice += (distance / 1000) * 0.5;
    }
    setState(() {
      _calculatedPrice = newPrice < 5.00 ? 5.00 : newPrice;
    });
    rideProvider.updateCalculatedPrice(_calculatedPrice);
  }

  String _maskCpfPartial(String cpf) {
    final digits = cpf.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length != 11) return cpf;
    return '${digits.substring(0, 3)}.***.***-${digits.substring(9)}';
  }

  double _getChangeNeeded() {
    if (_selectedPaymentType == PaymentType.dinheiro) {
      final value = double.tryParse(_changeForController.text.replaceAll(',', '.')) ?? 0.0;
      return value > _calculatedPrice ? value - _calculatedPrice : 0.0;
    }
    return 0.0;
  }

  void _showSearchingDialog(
      BuildContext context, RideRequestProvider rideProvider) async {
    await Future.delayed(const Duration(milliseconds: 250));
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return SearchingDriverDialog(
          logoPath: 'assets/images/levva_icon_transp_branco.png',
          onCancelDialog: () {
            rideProvider.cancelSearchForDriver();
            Navigator.of(dialogContext).pop(false);
          },
          onRetrySearch: () {
            rideProvider.requestRideAndFindDriver();
          },
        );
      },
    );
  }

  void _confirmOptions() async {
    final rideProvider = Provider.of<RideRequestProvider>(context, listen: false);

    if (rideProvider.serviceType == ServiceType.passenger) {
      if (_whoIsGoing == "eu") {
        if (_nameController.text.trim().isEmpty ||
            _surnameController.text.trim().isEmpty ||
            _cpfController.text.trim().isEmpty ||
            _cellController.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Preencha todos os dados obrigatórios.'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      } else {
        if (_otherNameController.text.trim().isEmpty ||
            _otherSurnameController.text.trim().isEmpty ||
            _otherCpfController.text.trim().isEmpty ||
            _otherCellController.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Preencha todos os dados obrigatórios da outra pessoa.'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }

      rideProvider.setDeliveryOptions(
        deliveryType: DeliveryType.levvaMoto,
        vehicleType: VehicleType.moto,
        paymentType: _selectedPaymentType ?? PaymentType.dinheiro,
        calculatedPrice: _calculatedPrice,
        changeFor: _selectedPaymentType == PaymentType.dinheiro
            ? _changeForController.text
            : null,
      );

      rideProvider.requestRideAndFindDriver();
      Navigator.pop(context);
      _showSearchingDialog(context, rideProvider);
      return;
    }

    // --- ENVIAR: Validação dos campos obrigatórios de entrega ---
    if (_receiverNameController.text.trim().isEmpty ||
        _receiverCellController.text.trim().isEmpty ||
        _selectedItemType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preencha todos os dados obrigatórios.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (_selectedItemType == 'Outros' &&
        _otherItemObservationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Descreva o item em "Outros".'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    rideProvider.setDeliveryOptions(
      deliveryType: DeliveryType.levvaRapido,
      vehicleType: _selectedVehicleType ?? VehicleType.moto,
      paymentType: _selectedPaymentType ?? PaymentType.dinheiro,
      calculatedPrice: _calculatedPrice,
      receiverName: _receiverNameController.text.trim(),
      receiverCell: _receiverCellController.text.trim(),
      itemType: _selectedItemType!,
      itemObservation: _selectedItemType == 'Outros'
          ? _otherItemObservationController.text.trim()
          : null,
      changeFor: _selectedPaymentType == PaymentType.dinheiro
          ? _changeForController.text
          : null,
    );

    rideProvider.requestRideAndFindDriver();
    Navigator.pop(context);
    _showSearchingDialog(context, rideProvider);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentPriceFromProvider =
        context.watch<RideRequestProvider>().calculatedPrice;
    final rideProvider = Provider.of<RideRequestProvider>(context);
    bool isDinheiro = _selectedPaymentType == PaymentType.dinheiro;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          color: theme.cardColor,
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
              const SizedBox(height: 18),
              Text(
                rideProvider.serviceType == ServiceType.passenger
                    ? 'Corrida Passageiro'
                    : 'Opções de Entrega',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 18),

              if (rideProvider.serviceType == ServiceType.passenger) ...[
                // --------- FORM PASSAGEIRO ---------
                const SectionTitle('Quem vai?'),
                Row(
                  children: [
                    ChoiceChip(
                      label: const Text("Eu"),
                      selected: _whoIsGoing == "eu",
                      onSelected: (v) {
                        setState(() {
                          _whoIsGoing = "eu";
                          _loadProfileDataIfEu();
                        });
                      },
                    ),
                    const SizedBox(width: 12),
                    ChoiceChip(
                      label: const Text("Outra pessoa"),
                      selected: _whoIsGoing == "outra",
                      onSelected: (v) {
                        setState(() {
                          _whoIsGoing = "outra";
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_whoIsGoing == "eu") ...[
                  TextField(
                    controller: _nameController,
                    enabled: false,
                    decoration: const InputDecoration(
                      labelText: "Nome",
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _surnameController,
                    enabled: false,
                    decoration: const InputDecoration(
                      labelText: "Sobrenome",
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _cpfController,
                    enabled: false,
                    decoration: const InputDecoration(
                      labelText: "CPF (parcial)",
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _cellController,
                    enabled: false,
                    decoration: const InputDecoration(
                      labelText: "Celular",
                    ),
                  ),
                ] else ...[
                  TextField(
                    controller: _otherNameController,
                    decoration: const InputDecoration(
                      labelText: "Nome *",
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _otherSurnameController,
                    decoration: const InputDecoration(
                      labelText: "Sobrenome *",
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _otherCpfController,
                    inputFormatters: [_cpfFormatter],
                    keyboardType: TextInputType.number,
                    maxLength: 14,
                    decoration: const InputDecoration(
                      labelText: "CPF *",
                      counterText: "",
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _otherCellController,
                    inputFormatters: [_cellFormatter],
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: "Celular *",
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                const SectionTitle('Forma de Pagamento'),
                Wrap(
                  spacing: 10,
                  children: [
                    ChoiceChip(
                      label: const Text("Dinheiro"),
                      selected: _selectedPaymentType == PaymentType.dinheiro,
                      onSelected: (_) {
                        setState(() => _selectedPaymentType = PaymentType.dinheiro);
                      },
                    ),
                    ChoiceChip(
                      label: const Text("Cartão"),
                      selected: _selectedPaymentType == PaymentType.cartao,
                      onSelected: (_) {
                        setState(() => _selectedPaymentType = PaymentType.cartao);
                      },
                    ),
                    ChoiceChip(
                      label: const Text("Levvapay"),
                      selected: _selectedPaymentType == PaymentType.carteiraLevva,
                      onSelected: (_) {
                        setState(() => _selectedPaymentType = PaymentType.carteiraLevva);
                      },
                    ),
                  ],
                ),
                if (isDinheiro) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _changeForController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "Troco para quanto?",
                      prefixText: "R\$ ",
                    ),
                    onChanged: (_) {
                      setState(() {});
                    },
                  ),
                  if (_getChangeNeeded() > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        "Troco necessário: R\$ ${_getChangeNeeded().toStringAsFixed(2)}",
                        style: TextStyle(
                            color: Colors.green.shade800,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                ],
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Valor da viagem:',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'R\$ ${currentPriceFromProvider.toStringAsFixed(2)}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                ElevatedButton(
                  style: theme.elevatedButtonTheme.style,
                  onPressed: _confirmOptions,
                  child: Text('Chamar motoca - R\$ ${currentPriceFromProvider.toStringAsFixed(2)}'),
                ),
                const SizedBox(height: 10),
              ] else ...[
                // ----------- ENVIAR: FORMULARIO DE ENTREGA COMPLETO -----------
                const SectionTitle('Tipo de Veículo'),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _vehicleTypeButton(
                      icon: Icons.motorcycle,
                      label: 'Moto',
                      selected: _selectedVehicleType == VehicleType.moto,
                      onTap: () {
                        setState(() {
                          _selectedVehicleType = VehicleType.moto;
                          _recalculatePrice();
                        });
                      },
                    ),
                    _vehicleTypeButton(
                      icon: Icons.directions_bike,
                      label: 'Bike',
                      selected: _selectedVehicleType == VehicleType.bike,
                      onTap: () {
                        setState(() {
                          _selectedVehicleType = VehicleType.bike;
                          _recalculatePrice();
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    'Valor calculado: R\$ ${currentPriceFromProvider.toStringAsFixed(2)}',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const SectionTitle('Quem vai receber?'),
                TextField(
                  controller: _receiverNameController,
                  decoration: const InputDecoration(
                    labelText: "Nome do destinatário *",
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _receiverCellController,
                  inputFormatters: [_cellFormatter],
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: "Celular do destinatário *",
                  ),
                ),
                const SizedBox(height: 18),
                const SectionTitle('Tipo do Item'),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _itemTypes.map((type) {
                      final isSelected = _selectedItemType == type;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(type),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedItemType = type;
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                if (_selectedItemType == 'Outros') ...[
                  const SizedBox(height: 10),
                  TextField(
                    controller: _otherItemObservationController,
                    decoration: const InputDecoration(
                      labelText: "Descreva o item",
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                const SectionTitle('Forma de Pagamento'),
                Wrap(
                  spacing: 10,
                  children: [
                    ChoiceChip(
                      label: const Text("Dinheiro"),
                      selected: _selectedPaymentType == PaymentType.dinheiro,
                      onSelected: (_) {
                        setState(() {
                          _selectedPaymentType = PaymentType.dinheiro;
                          _recalculatePrice();
                        });
                      },
                    ),
                    ChoiceChip(
                      label: const Text("Cartão"),
                      selected: _selectedPaymentType == PaymentType.cartao,
                      onSelected: (_) {
                        setState(() {
                          _selectedPaymentType = PaymentType.cartao;
                          _recalculatePrice();
                        });
                      },
                    ),
                    ChoiceChip(
                      label: const Text("Levvapay"),
                      selected: _selectedPaymentType == PaymentType.carteiraLevva,
                      onSelected: (_) {
                        setState(() {
                          _selectedPaymentType = PaymentType.carteiraLevva;
                          _recalculatePrice();
                        });
                      },
                    ),
                  ],
                ),
                if (isDinheiro) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _changeForController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "Troco para quanto?",
                      prefixText: "R\$ ",
                    ),
                    onChanged: (_) {
                      setState(() {});
                    },
                  ),
                  if (_getChangeNeeded() > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        "Troco necessário: R\$ ${_getChangeNeeded().toStringAsFixed(2)}",
                        style: TextStyle(
                            color: Colors.green.shade800,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                ],
                const SizedBox(height: 22),
                ElevatedButton(
                  style: theme.elevatedButtonTheme.style,
                  onPressed: _confirmOptions,
                  child: Text(
                    'Chamar motoca - R\$ ${currentPriceFromProvider.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _vehicleTypeButton({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: selected ? Colors.black87 : Colors.grey[200],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
              color: selected ? Colors.black : Colors.grey.shade300, width: 2),
        ),
        elevation: selected ? 3 : 0,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          child: Column(
            children: [
              Icon(icon, size: 32, color: selected ? Colors.white : Colors.black87),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _cpfController.dispose();
    _cellController.dispose();
    _otherNameController.dispose();
    _otherSurnameController.dispose();
    _otherCpfController.dispose();
    _otherCellController.dispose();
    _changeForController.dispose();

    _receiverNameController.dispose();
    _receiverCellController.dispose();
    _otherItemObservationController.dispose();
    super.dispose();
  }
}