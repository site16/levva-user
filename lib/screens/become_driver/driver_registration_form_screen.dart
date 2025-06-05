// lib/screens/become_driver/driver_registration_form_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Para SystemUiOverlayStyle
import 'package:image_picker/image_picker.dart';
import 'package:levva/models/enums.dart';
import 'package:levva/providers/driver_registration_provider.dart';
import 'package:levva/screens/home/home_screen.dart'; // Para navegação
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:provider/provider.dart';

class DriverRegistrationFormScreen extends StatefulWidget {
  static const routeName = '/driver-registration-form';
  final VehicleType vehicleType;

  const DriverRegistrationFormScreen({super.key, required this.vehicleType});

  @override
  State<DriverRegistrationFormScreen> createState() =>
      _DriverRegistrationFormScreenState();
}

class _DriverRegistrationFormScreenState
    extends State<DriverRegistrationFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _cpfController = TextEditingController();
  final _dobController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _emailController = TextEditingController();
  final _cnhController = TextEditingController();
  final _plateController = TextEditingController();
  final _renavamController = TextEditingController();

  final _cpfFormatter = MaskTextInputFormatter(mask: '###.###.###-##', filter: {"#": RegExp(r'[0-9]')});
  final _dobFormatter = MaskTextInputFormatter(mask: '##/##/####', filter: {"#": RegExp(r'[0-9]')});
  final _whatsappFormatter = MaskTextInputFormatter(mask: '(##) #####-####', filter: {"#": RegExp(r'[0-9]')});

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final registrationProvider = Provider.of<DriverRegistrationProvider>(context, listen: false);
      registrationProvider.initializeApplication(widget.vehicleType);
    });
  }

  @override
  void dispose() {
    _fullNameController.dispose(); _cpfController.dispose(); _dobController.dispose();
    _whatsappController.dispose(); _emailController.dispose(); _cnhController.dispose();
    _plateController.dispose(); _renavamController.dispose();
    super.dispose();
  }

  Future<void> _pickImageFromSheet(
    DriverRegistrationProvider provider,
    DocumentType docType
  ) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.photo_library_outlined, color: Theme.of(context).colorScheme.primary),
                title: Text('Galeria', style: TextStyle(color: Theme.of(context).colorScheme.onBackground)),
                onTap: () {
                  if (docType == DocumentType.profile) {
                    provider.pickImage(ImageSource.gallery);
                  } else {
                    provider.pickDocumentImage(ImageSource.gallery, docType);
                  }
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_camera_outlined, color: Theme.of(context).colorScheme.primary),
                title: Text('Câmera', style: TextStyle(color: Theme.of(context).colorScheme.onBackground)),
                onTap: () {
                  if (docType == DocumentType.profile) {
                     provider.pickImage(ImageSource.camera);
                  } else {
                    provider.pickDocumentImage(ImageSource.camera, docType);
                  }
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _submitForm(DriverRegistrationProvider provider) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    if (!_formKey.currentState!.validate()) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Por favor, corrija os erros no formulário.'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    String? missingImageError;
    if (provider.pickedImageFile == null) {
      missingImageError = "Por favor, envie sua foto de perfil.";
    } else if (widget.vehicleType == VehicleType.moto) {
      if (provider.cnhImageFile == null) {
        missingImageError = "Por favor, envie a foto da sua CNH.";
      } else if (provider.vehicleDocumentImageFile == null) {
        missingImageError = "Por favor, envie a foto do documento da moto.";
      }
    } else if (widget.vehicleType == VehicleType.bike) {
      if (provider.personalDocumentImageFile == null) {
        missingImageError = "Por favor, envie a foto do seu documento pessoal (RG/CNH).";
      }
    }

    if (missingImageError != null) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(missingImageError),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    _formKey.currentState!.save();

    provider.updateApplicationData(
      fullName: _fullNameController.text.trim(),
      cpf: _cpfFormatter.getUnmaskedText(),
      dateOfBirth: _dobController.text.trim(),
      whatsappNumber: _whatsappFormatter.getUnmaskedText(),
      email: _emailController.text.trim(),
      cnhNumber: widget.vehicleType == VehicleType.moto ? _cnhController.text.trim() : null,
      motorcyclePlate: widget.vehicleType == VehicleType.moto ? _plateController.text.trim().toUpperCase() : null,
      renavam: widget.vehicleType == VehicleType.moto ? _renavamController.text.trim() : null,
    );

    bool success = await provider.submitApplication();
    if (context.mounted) {
      if (success) {
        _showConfirmationDialog();
      } else if (provider.errorMessage != null) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
      } else {
         scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Falha ao enviar solicitação. Tente novamente.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showConfirmationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
          title: Row(children: [
            Icon(Icons.check_circle_outline_rounded, color: Colors.green.shade600, size: 28), // Ícone ajustado
            const SizedBox(width: 12),
            const Text('Solicitação Enviada!'),
          ]),
          titleTextStyle: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          content: const SingleChildScrollView(
            child: Text(
              'Sua solicitação para se tornar um entregador Levva foi enviada para análise. Aguarde nosso contato em até 5 dias úteis para a confirmação e próximos passos.',
              style: TextStyle(fontSize: 15, height: 1.4),
            ),
          ),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary, // Preto
                textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              child: const Text('ENTENDIDO'),
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).popUntil(
                  (route) => route.settings.name == HomeScreen.routeName || route.isFirst,
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    List<MaskTextInputFormatter>? formatters, // Alterado para List<MaskTextInputFormatter>?
    String? Function(String?)? validator,
    bool enabled = true,
    int? maxLength,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0), // Aumentado padding vertical
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration( // Usará o InputDecorationTheme global
          labelText: labelText,
          prefixIcon: Icon(icon, size: 22), // Tamanho do ícone ajustado
          // Não precisa definir fillColor, border, etc., aqui, pois virão do tema
        ),
        keyboardType: keyboardType,
        inputFormatters: formatters, // Passando a lista de formatters
        validator: validator,
        enabled: enabled,
        maxLength: maxLength,
        textCapitalization: textCapitalization,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        style: const TextStyle(fontSize: 16), // Estilo do texto de entrada
      ),
    );
  }

  Widget _buildDocumentPicker({
    required BuildContext context,
    required DriverRegistrationProvider provider,
    required String label,
    required File? currentFile,
    required DocumentType docType,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0), // Aumentado padding vertical
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.onBackground.withOpacity(0.9), // Ajustado para melhor leitura
            fontWeight: FontWeight.w500,
            fontSize: 14,
          )),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => _pickImageFromSheet(provider, docType),
            child: Container(
              height: 160, // Altura aumentada
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(color: Colors.grey.shade800, width: 1), // Borda sutil
              ),
              child: currentFile != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(11.0), // Levemente menor que o container para a borda aparecer
                      child: Image.file(currentFile, fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(child: Icon(Icons.broken_image_outlined, color: Colors.white70, size: 40));
                        },
                      ))
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt_outlined, size: 44, color: Colors.white70),
                        const SizedBox(height: 10),
                        Text('Toque para enviar foto', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    final registrationProvider = Provider.of<DriverRegistrationProvider>(context);
    final String vehicleTypeName = widget.vehicleType == VehicleType.moto ? "Motociclista" : "Ciclista";

    return Scaffold(
      backgroundColor: Colors.grey[100], // Fundo cinza claro para a tela
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 22),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Voltar',
        ),
        title: Text(
          'Novo Cadastro ($vehicleTypeName)',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white, // AppBar branca
        elevation: 0.8,
        scrolledUnderElevation: 1.0,
        systemOverlayStyle: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20.0, 24.0, 20.0, 30.0), // Padding geral ajustado
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () => _pickImageFromSheet(registrationProvider, DocumentType.profile),
                      child: CircleAvatar(
                        radius: 56, // Raio um pouco menor para alinhar melhor
                        backgroundColor: Colors.black,
                        backgroundImage: registrationProvider.pickedImageFile != null
                            ? FileImage(registrationProvider.pickedImageFile!)
                            : null,
                        child: registrationProvider.pickedImageFile == null
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.camera_alt_outlined, size: 36, color: Colors.white70),
                                  SizedBox(height: 4),
                                  Text("Sua Foto", style: TextStyle(fontSize: 10, color: Colors.white70)),
                                ],
                              )
                            : null,
                      ),
                    ),
                    if (registrationProvider.status == RegistrationStatus.error &&
                        registrationProvider.errorMessage != null &&
                        registrationProvider.errorMessage!.contains("foto de perfil"))
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(registrationProvider.errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red, fontSize: 12)),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 28), // Espaçamento aumentado
              const FormSectionTitle("Informações Pessoais"),
              _buildTextField(controller: _fullNameController, labelText: 'Nome Completo', icon: Icons.person_outline_rounded, validator: (value) => (value == null || value.trim().isEmpty) ? 'Nome é obrigatório' : null, textCapitalization: TextCapitalization.words),
              _buildTextField(controller: _cpfController, labelText: 'CPF', icon: Icons.badge_outlined, keyboardType: TextInputType.number, formatters: [_cpfFormatter], validator: (value) { if (value == null || value.trim().isEmpty) return 'CPF é obrigatório'; if (!_cpfFormatter.isFill()) return 'CPF inválido'; return null; }),
              _buildTextField(controller: _dobController, labelText: 'Data de Nascimento (DD/MM/AAAA)', icon: Icons.calendar_today_outlined, keyboardType: TextInputType.datetime, formatters: [_dobFormatter], validator: (value) { if (value == null || value.trim().isEmpty) return 'Data de nascimento é obrigatória'; if (!_dobFormatter.isFill()) return 'Data inválida'; return null; }),
              _buildTextField(controller: _whatsappController, labelText: 'Nº WhatsApp (com DDD)', icon: Icons.phone_android_outlined, keyboardType: TextInputType.phone, formatters: [_whatsappFormatter], validator: (value) { if (value == null || value.trim().isEmpty) return 'WhatsApp é obrigatório'; if (!_whatsappFormatter.isFill()) return 'Número de WhatsApp inválido'; return null; }),
              _buildTextField(controller: _emailController, labelText: 'E-mail', icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress, validator: (value) { if (value == null || value.trim().isEmpty) return 'E-mail é obrigatório'; if (!RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(value)) return 'Insira um e-mail válido'; return null; }),
              
              if (widget.vehicleType == VehicleType.moto) ...[
                const SizedBox(height: 20), // Espaçamento entre seções
                const FormSectionTitle("Documentos da Moto"),
                _buildDocumentPicker(context: context, provider: registrationProvider, label: "Foto da CNH (Frente e Verso)", currentFile: registrationProvider.cnhImageFile, docType: DocumentType.cnh),
                _buildDocumentPicker(context: context, provider: registrationProvider, label: "Documento da Moto (CRLV)", currentFile: registrationProvider.vehicleDocumentImageFile, docType: DocumentType.vehicle),
                const SizedBox(height: 16), // Espaçamento ajustado
                const FormSectionTitle("Dados da Moto"),
                _buildTextField(controller: _cnhController, labelText: 'Número da CNH', icon: Icons.card_membership_outlined, validator: (value) => (value == null || value.trim().isEmpty) ? 'CNH é obrigatória' : null),
                _buildTextField(controller: _plateController, labelText: 'Placa da Moto (Ex: ABC1D23)', icon: Icons.pin_outlined, textCapitalization: TextCapitalization.characters, validator: (value) => (value == null || value.trim().isEmpty) ? 'Placa é obrigatória' : null, maxLength: 7),
                _buildTextField(controller: _renavamController, labelText: 'Renavam', icon: Icons.article_outlined, keyboardType: TextInputType.number, validator: (value) => (value == null || value.trim().isEmpty) ? 'Renavam é obrigatório' : null, maxLength: 11),
              ] else if (widget.vehicleType == VehicleType.bike) ...[
                const SizedBox(height: 20),
                const FormSectionTitle("Documento Pessoal"),
                _buildDocumentPicker(context: context, provider: registrationProvider, label: "Foto do Documento (RG ou CNH)", currentFile: registrationProvider.personalDocumentImageFile, docType: DocumentType.personalId),
              ],

              const SizedBox(height: 32), // Espaço antes do botão
              ElevatedButton(
                // O estilo já vem do ElevatedButtonThemeData em main.dart
                // (fundo preto, texto branco, cantos arredondados, altura 52)
                onPressed: registrationProvider.status == RegistrationStatus.loading ? null : () => _submitForm(registrationProvider),
                child: registrationProvider.status == RegistrationStatus.loading
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                    : const Text('ENVIAR SOLICITAÇÃO', style: TextStyle(fontSize: 15, letterSpacing: 0.5)), // Fonte um pouco menor
              ),
              const SizedBox(height: 24), // Espaço no final
            ],
          ),
        ),
      ),
    );
  }
}

// Widget para título de seção no formulário
class FormSectionTitle extends StatelessWidget {
  final String title;
  const FormSectionTitle(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 20.0, bottom: 10.0), // Padding ajustado
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onBackground.withOpacity(0.9), // Cor ajustada
          fontSize: 17, // Tamanho de fonte ajustado
        ),
      ),
    );
  }
}