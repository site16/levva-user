// lib/screens/home/levva_eats/checkout_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:levva/globals/cart_data.dart';
import 'package:levva/models/eats_cart_item_model.dart';
import 'package:provider/provider.dart'; // Importar Provider
import '../../../providers/auth_provider.dart'; // Importar AuthProvider
import '../../../models/user_model.dart'; // Importar AppUser
import '../../profile/profile_screen.dart'; // Importar ProfileScreen para navegação
import './order_confirmation_screen.dart';

enum PaymentType { app, delivery }

enum DeliveryPaymentMethod { cash, card_machine }

class CheckoutScreen extends StatefulWidget {
  static const routeName = '/levva-eats-checkout';
  final double totalAmount;

  const CheckoutScreen({super.key, required this.totalAmount});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _observationController = TextEditingController();
  final TextEditingController _changeForController = TextEditingController();

  // Não vamos mais usar variáveis de estado separadas para o endereço aqui.
  // Leremos diretamente do AuthProvider.
  // bool _isAddressFilled = true; // Esta lógica será refeita

  PaymentType? _selectedPaymentType;
  DeliveryPaymentMethod? _selectedDeliveryPaymentMethod;

  @override
  void initState() {
    super.initState();
    // Preenche o campo de observação
    String? initialObservation;
    // Acessa AuthProvider de forma segura em initState (listen: false)
    // para pré-popular observações, se necessário, mas o endereço será lido no build.
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _loadInitialObservations();
    // Não precisa carregar endereço aqui, será lido dinamicamente no build.
  }

  void _loadInitialObservations() {
    String? initialObservation;
    for (var item in globalCartItems) {
      if (item.observation != null && item.observation!.isNotEmpty) {
        initialObservation = item.observation;
        break;
      }
    }
    _observationController.text = initialObservation ?? '';
  }

  // Getter para nome da loja (inalterado)
  String get _currentStoreName {
    if (globalCartItems.isNotEmpty) {
      final String? storeNameFromProduct =
          globalCartItems.first.product.storeName;
      if (storeNameFromProduct != null && storeNameFromProduct.isNotEmpty) {
        return storeNameFromProduct;
      }
    }
    return "Loja";
  }

  Widget _buildSectionTitle(String title, {double topPadding = 20.0}) {
    return Padding(
      padding: EdgeInsets.only(top: topPadding, bottom: 10.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    bool isBold = false,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: TextStyle(fontSize: 15, color: Colors.grey.shade700),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? 'Não informado' : value, // Trata strings vazias
              style: TextStyle(
                fontSize: 15,
                color: value.isEmpty ? Colors.grey.shade600 : Colors.black87,
                fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
                fontStyle: value.isEmpty ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  // Verifica se o endereço do usuário está preenchido
  bool _isUserAddressComplete(AppUser? user) {
    if (user == null) return false;
    return user.street.isNotEmpty &&
        user.number.isNotEmpty &&
        user.neighborhood.isNotEmpty &&
        user.city.isNotEmpty &&
        user.state.isNotEmpty &&
        user.zipCode.isNotEmpty;
  }

  Widget _buildDeliveryAddressSection(AppUser? user) {
    final bool isAddressComplete = _isUserAddressComplete(user);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Endereço de Entrega *', topPadding: 0),
        Card(
          elevation: 0.8,
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            // A borda vermelha será controlada pela validação no _placeOrder
            side: BorderSide(color: Colors.grey.shade300),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (user != null) ...[
                  _buildInfoRow('Rua', user.street, isBold: true),
                  _buildInfoRow('Número', user.number),
                  _buildInfoRow('Bairro', user.neighborhood),
                  _buildInfoRow('Cidade', '${user.city} - ${user.state}'),
                  _buildInfoRow('CEP', user.zipCode),
                  if (user.complement != null &&
                      user
                          .complement!
                          .isNotEmpty) // Assumindo que AppUser pode ter 'complement'
                    _buildInfoRow('Complemento', user.complement!),
                ] else ...[
                  const Text(
                    'Nenhum endereço cadastrado.',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.red,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    icon: Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: Theme.of(context).primaryColorDark,
                    ),
                    label: Text(
                      user != null && isAddressComplete
                          ? 'Alterar Endereço'
                          : 'Cadastrar/Completar Endereço',
                      style: TextStyle(
                        color: Theme.of(context).primaryColorDark,
                      ),
                    ),
                    onPressed: () async {
                      await Navigator.of(
                        context,
                      ).pushNamed(ProfileScreen.routeName);
                      // Ao voltar da ProfileScreen, o AuthProvider (se notificar)
                      // ou o setState fará o build ler os novos dados.
                      if (mounted) {
                        setState(() {
                          // Apenas para forçar o rebuild e re-ler o user do AuthProvider
                        });
                      }
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 0,
                        vertical: 4,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderSummarySection() {
    // ... (Inalterado - já usa _currentStoreName)
    if (globalCartItems.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20.0),
          child: Text('Seu ticket está vazio para esta loja.'),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Meu Ticket ($_currentStoreName)'),
        Card(
          elevation: 0.8,
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: Colors.grey.shade300),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: globalCartItems.length,
            itemBuilder: (context, index) {
              final item = globalCartItems[index];
              String addonsText = item.selectedAddons
                  .map((a) => a.name)
                  .join(', ');
              return ListTile(
                title: Text(
                  '${item.quantity}x ${item.product.name}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (addonsText.isNotEmpty)
                      Text(
                        'Adicionais: $addonsText',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    if (item.observation != null &&
                        item.observation!.isNotEmpty)
                      Text(
                        'Obs: ${item.observation}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blueGrey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
                trailing: Text(
                  'R\$ ${(item.totalPrice).toStringAsFixed(2).replaceAll('.', ',')}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            },
            separatorBuilder:
                (context, index) =>
                    const Divider(height: 1, indent: 16, endIndent: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodsSection() {
    // ... (Inalterado - já com o design de botões pretos)
    final bool isAppPaymentSelected = _selectedPaymentType == PaymentType.app;
    final bool isDeliveryPaymentSelected =
        _selectedPaymentType == PaymentType.delivery;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Forma de Pagamento *'),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: Icon(
                  Icons.phone_android_outlined,
                  color: isAppPaymentSelected ? Colors.white : Colors.black87,
                ),
                label: Text(
                  'Pelo App',
                  style: TextStyle(
                    color: isAppPaymentSelected ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  backgroundColor:
                      isAppPaymentSelected ? Colors.black : Colors.white,
                  side: BorderSide(
                    color:
                        isAppPaymentSelected
                            ? Colors.black
                            : Colors.grey.shade400,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                onPressed:
                    () => setState(() {
                      _selectedPaymentType = PaymentType.app;
                      _selectedDeliveryPaymentMethod = null;
                    }),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                icon: Icon(
                  Icons.delivery_dining,
                  color:
                      isDeliveryPaymentSelected ? Colors.white : Colors.black87,
                ),
                label: Text(
                  'Na Entrega',
                  style: TextStyle(
                    color:
                        isDeliveryPaymentSelected
                            ? Colors.white
                            : Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  backgroundColor:
                      isDeliveryPaymentSelected ? Colors.black : Colors.white,
                  side: BorderSide(
                    color:
                        isDeliveryPaymentSelected
                            ? Colors.black
                            : Colors.grey.shade400,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                onPressed:
                    () => setState(
                      () => _selectedPaymentType = PaymentType.delivery,
                    ),
              ),
            ),
          ],
        ),
        if (isAppPaymentSelected)
          Card(
            elevation: 0.8,
            margin: const EdgeInsets.only(top: 12.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: Colors.grey.shade300),
            ),
            child: ListTile(
              leading: Image.asset(
                'assets/images/levva_icon_transp.png',
                width: 30,
                height: 30,
              ),
              title: const Text(
                'LevvaPay',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        if (isDeliveryPaymentSelected)
          Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: Column(
              children: [
                RadioListTile<DeliveryPaymentMethod>(
                  title: const Text('Dinheiro', style: TextStyle(fontSize: 15)),
                  value: DeliveryPaymentMethod.cash,
                  groupValue: _selectedDeliveryPaymentMethod,
                  onChanged:
                      (DeliveryPaymentMethod? value) => setState(
                        () => _selectedDeliveryPaymentMethod = value,
                      ),
                  activeColor: Colors.black,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
                if (_selectedDeliveryPaymentMethod ==
                    DeliveryPaymentMethod.cash)
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 16.0,
                      top: 0.0,
                      bottom: 8.0,
                    ),
                    child: TextFormField(
                      controller: _changeForController,
                      decoration: InputDecoration(
                        labelText: 'Precisa de troco para quanto? (Opcional)',
                        hintText: 'Ex: 50 ou 100',
                        prefixText: 'R\$ ',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d{0,2}'),
                        ),
                      ],
                    ),
                  ),
                RadioListTile<DeliveryPaymentMethod>(
                  title: const Text(
                    'Máquina de Cartão (Crédito/Débito)',
                    style: TextStyle(fontSize: 15),
                  ),
                  value: DeliveryPaymentMethod.card_machine,
                  groupValue: _selectedDeliveryPaymentMethod,
                  onChanged:
                      (DeliveryPaymentMethod? value) => setState(
                        () => _selectedDeliveryPaymentMethod = value,
                      ),
                  activeColor: Colors.black,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildObservationsSection() {
    // ... (Inalterado)
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Observações (Opcional)'),
        TextFormField(
          controller: _observationController,
          decoration: InputDecoration(
            hintText: 'Ex: Sem cebola, ponto da carne, etc.',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            filled: true,
            fillColor: Colors.grey.shade50.withOpacity(0.7),
          ),
          maxLines: 3,
          textInputAction: TextInputAction.done,
        ),
      ],
    );
  }

  void _placeOrder(AppUser? currentUser) {
    // Recebe currentUser para validação
    final isAddressComplete = _isUserAddressComplete(currentUser);

    bool isPaymentMethodSelected = _selectedPaymentType != null;
    if (_selectedPaymentType == PaymentType.delivery) {
      isPaymentMethodSelected = _selectedDeliveryPaymentMethod != null;
      if (_selectedDeliveryPaymentMethod == DeliveryPaymentMethod.cash &&
          _changeForController.text.isNotEmpty) {
        double? changeNeeded = double.tryParse(
          _changeForController.text.replaceAll(',', '.'),
        );
        if (changeNeeded != null && changeNeeded < widget.totalAmount) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'O valor para troco deve ser maior ou igual ao total do pedido.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }
      }
    }

    if (!isAddressComplete) {
      // Verifica se o endereço do perfil está completo
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Por favor, cadastre ou complete seu endereço de entrega no perfil.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (!isPaymentMethodSelected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecione uma forma de pagamento.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      String fullDeliveryAddress = "Endereço não disponível";
      if (currentUser != null && isAddressComplete) {
        fullDeliveryAddress =
            '${currentUser.street}, ${currentUser.number} - ${currentUser.neighborhood}, ${currentUser.city} - ${currentUser.state}, CEP: ${currentUser.zipCode}';
        if (currentUser.complement != null &&
            currentUser.complement!.isNotEmpty) {
          fullDeliveryAddress += ' (${currentUser.complement})';
        }
      }

      Navigator.of(context).pushNamedAndRemoveUntil(
        OrderConfirmationScreen.routeName,
        (route) => route.isFirst,
        arguments: {
          'totalAmount': widget.totalAmount,
          'paymentMethod':
              _selectedPaymentType.toString() +
              (_selectedPaymentType == PaymentType.delivery
                  ? ' - ${_selectedDeliveryPaymentMethod.toString()}'
                  : ''),
          'storeName': _currentStoreName,
          'deliveryAddress': fullDeliveryAddress,
          'observation': _observationController.text,
          if (_selectedPaymentType == PaymentType.delivery &&
              _selectedDeliveryPaymentMethod == DeliveryPaymentMethod.cash &&
              _changeForController.text.isNotEmpty)
            'changeFor': _changeForController.text,
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Usa Consumer para ouvir mudanças no AuthProvider e reconstruir quando currentUser mudar
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final AppUser? currentUser = authProvider.currentUser;

        return Scaffold(
          backgroundColor: Colors.grey.shade100,
          appBar: AppBar(
            leading: BackButton(color: Colors.black87),
            title: const Text(
              'Finalizar Pedido',
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
            centerTitle: true,
            backgroundColor: Colors.white,
            elevation: 1.0,
            systemOverlayStyle: const SystemUiOverlayStyle(
              statusBarColor: Colors.white,
              statusBarIconBrightness: Brightness.dark,
              statusBarBrightness: Brightness.light,
            ),
            actions: const [],
          ),
          body:
              currentUser == null &&
                      authProvider
                          .isLoading // Se estiver carregando e não tiver usuário ainda
                  ? const Center(
                    child: CircularProgressIndicator(color: Colors.black),
                  )
                  : currentUser ==
                      null // Se não estiver carregando mas mesmo assim não tiver usuário
                  ? const Center(
                    child: Text(
                      "Não foi possível carregar os dados do usuário.",
                    ),
                  )
                  : SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDeliveryAddressSection(
                            currentUser,
                          ), // Passa currentUser
                          _buildOrderSummarySection(),
                          _buildPaymentMethodsSection(),
                          _buildObservationsSection(),
                          _buildSectionTitle('Total do Pedido'),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12.0),
                            child: Text(
                              'R\$ ${widget.totalAmount.toStringAsFixed(2).replaceAll('.', ',')}',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          bottomNavigationBar:
              currentUser == null
                  ? null
                  : Container(
                    // Oculta o botão se não houver usuário
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          spreadRadius: 0,
                          blurRadius: 10,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed:
                          () => _placeOrder(currentUser), // Passa currentUser
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 52),
                        textStyle: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                      child: const Text('Fazer Pedido'),
                    ),
                  ),
        );
      },
    );
  }
}
