import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/pulsing_logo_loader.dart';

class ProfileScreen extends StatefulWidget {
  static const routeName = '/profile';
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _cpfController = TextEditingController();
  final _phoneController = TextEditingController();
  final _zipCodeController = TextEditingController();
  final _streetController = TextEditingController();
  final _numberController = TextEditingController();
  final _neighborhoodController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();

  bool _isInitialized = false;
  File? _selectedImageFile;
  bool _isSaving = false;

  final _cpfFormatter = MaskTextInputFormatter(
    mask: '###.###.###-##',
    filter: {"#": RegExp(r'[0-9]')},
  );
  final _phoneFormatter = MaskTextInputFormatter(
    mask: '(##) # ####-####',
    filter: {"#": RegExp(r'[0-9]')},
  );
  final _zipCodeFormatter = MaskTextInputFormatter(
    mask: '#####-###',
    filter: {"#": RegExp(r'[0-9]')},
  );

  static const Color levvaPrimaryColor = Color.fromARGB(255, 0, 0, 0);
  static const Color levvaSecondaryColor = Color(0xFF7E57C2);
  static const Color levvaAccentColor = Color(0xFFEDE7F6);

  @override
  void didChangeDependencies() {
    if (!_isInitialized) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.currentUser;
      if (user != null) {
        _nameController.text = user.name;
        _lastNameController.text = user.lastName;
        _cpfController.text = _cpfFormatter.maskText(user.cpf);
        String pNum = user.phoneNumber;
        if (pNum.startsWith('+55')) pNum = pNum.substring(3);
        if (pNum.length == 10 || pNum.length == 11) {
          _phoneController.text = _phoneFormatter.maskText(pNum);
        } else {
          _phoneController.text = pNum;
        }
        _zipCodeController.text = _zipCodeFormatter.maskText(user.zipCode);
        _streetController.text = user.street;
        _numberController.text = user.number;
        _neighborhoodController.text = user.neighborhood;
        _cityController.text = user.city;
        _stateController.text = user.state;
      }
      _isInitialized = true;
    }
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _lastNameController.dispose();
    _cpfController.dispose();
    _phoneController.dispose();
    _zipCodeController.dispose();
    _streetController.dispose();
    _numberController.dispose();
    _neighborhoodController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 800,
      );
      if (pickedFile != null) {
        setState(() {
          _selectedImageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao selecionar imagem.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveProfile() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    if (!_formKey.currentState!.validate()) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Por favor, corrija os erros no formulário.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isSaving = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;

    if (currentUser == null) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Usuário não autenticado. Tente novamente.'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isSaving = false;
        });
      }
      return;
    }

    bool anyChangeMade = false;
    bool overallSuccess = true;

    try {
      final String newName = _nameController.text.trim();
      final String newLastName = _lastNameController.text.trim();
      final String newCpf = _cpfFormatter.getUnmaskedText();
      final String newRawPhone = _phoneFormatter.getUnmaskedText();
      final String newPhone = newRawPhone.isNotEmpty ? '+55$newRawPhone' : '';
      final String newZipCode = _zipCodeFormatter.getUnmaskedText();
      final String newStreet = _streetController.text.trim();
      final String newNumber = _numberController.text.trim();
      final String newNeighborhood = _neighborhoodController.text.trim();
      final String newCity = _cityController.text.trim();
      final String newState = _stateController.text.trim();

      bool textDataChanged =
          newName != currentUser.name ||
          newLastName != currentUser.lastName ||
          newCpf != currentUser.cpf ||
          newPhone != currentUser.phoneNumber ||
          newZipCode != currentUser.zipCode ||
          newStreet != currentUser.street ||
          newNumber != currentUser.number ||
          newNeighborhood != currentUser.neighborhood ||
          newCity != currentUser.city ||
          newState != currentUser.state;

      if (textDataChanged) {
        anyChangeMade = true;
        print("ProfileScreen: Atualizando dados textuais do perfil...");
        Map<String, dynamic> updatedData = {
          'name': newName,
          'lastName': newLastName,
          'cpf': newCpf,
          'phoneNumber': newPhone,
          'zipCode': newZipCode,
          'street': newStreet,
          'number': newNumber,
          'neighborhood': newNeighborhood,
          'city': newCity,
          'state': newState,
        };
        bool profileDataSaved = await authProvider.updateUserProfileData(
          updatedData,
          context,
        );
        if (!profileDataSaved) overallSuccess = false;
        print(
          "ProfileScreen: authProvider.updateUserProfileData retornou $profileDataSaved",
        );
      }

      if (_selectedImageFile != null) {
        anyChangeMade = true;
        print("ProfileScreen: Atualizando imagem do perfil...");
        bool imageUploadSuccess = await authProvider.updateUserProfileImage(
          _selectedImageFile!,
          context,
        );
        if (imageUploadSuccess && mounted) {
          setState(() {
            _selectedImageFile = null;
          });
        } else if (!imageUploadSuccess) {
          overallSuccess = false;
        }
        print(
          "ProfileScreen: authProvider.updateUserProfileImage retornou $imageUploadSuccess",
        );
      }

      if (!mounted) return;

      if (!anyChangeMade) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Nenhuma alteração detectada.')),
        );
      } else if (overallSuccess) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Perfil atualizado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Falha ao atualizar algumas informações do perfil.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print("ProfileScreen: Erro em _saveProfile: $e");
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Ocorreu um erro inesperado: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _handleSignOut() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final navigator = Navigator.of(context);
    await authProvider.signOut(context);
    if (mounted) navigator.popUntil((route) => route.isFirst);
  }

  String? _validateRequired(String? value, String fieldName) =>
      (value == null || value.trim().isEmpty)
          ? '$fieldName é obrigatório.'
          : null;

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    const String logoPathForLightBg = 'assets/images/levva_icon_transp.png';

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Consumer<AuthProvider>(
        builder: (ctx, authProvider, _) {
          final user = authProvider.currentUser;
          // CORREÇÃO 1: Removido !authProvider.isUserFetched
          final isLoadingInitialData = authProvider.isLoading && user == null;

          if (isLoadingInitialData) {
            return Center(
              child: PulsingLogoLoader(
                imagePath: logoPathForLightBg,
                size: 80.0,
              ),
            );
          }
          if (user == null && !authProvider.isLoading) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  authProvider.errorMessage ??
                      'Não foi possível carregar o perfil. Faça login novamente.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          if (user == null)
            return const Center(child: Text("Usuário não disponível."));

          return CustomScrollView(
            slivers: <Widget>[
              SliverPersistentHeader(
                delegate: _ProfileHeaderDelegate(
                  user: user,
                  selectedImageFile: _selectedImageFile,
                  onPickImage: _pickImage,
                  isUploadingImage:
                      authProvider.isLoading && _selectedImageFile != null,
                  primaryColor: levvaPrimaryColor,
                  secondaryColor: levvaSecondaryColor,
                  accentColor: levvaAccentColor,
                  logoPath: logoPathForLightBg,
                ),
                pinned: false,
                floating: true,
              ),
              SliverToBoxAdapter(
                child: Container(
                  transform: Matrix4.translationValues(0.0, -20.0, 0.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(25.0),
                        topRight: Radius.circular(25.0),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 10,
                          offset: const Offset(0, -3),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        20.0,
                        30.0,
                        20.0,
                        20.0,
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            _buildFormField(
                              context: context,
                              controller: _nameController,
                              label: 'Nome',
                              validator: (v) => _validateRequired(v, 'Nome'),
                            ),
                            _buildFormField(
                              context: context,
                              controller: _lastNameController,
                              label: 'Sobrenome',
                              validator:
                                  (v) => _validateRequired(v, 'Sobrenome'),
                            ),
                            _buildReadOnlyField(
                              label: 'Email',
                              value: user.email ?? 'Não informado',
                            ),
                            const SizedBox(height: 20),
                            const FormSectionTitle("Informações Adicionais"),
                            _buildFormField(
                              context: context,
                              controller: _cpfController,
                              label: 'CPF',
                              keyboardType: TextInputType.number,
                              formatter: _cpfFormatter,
                              validator: (v) {
                                if (_validateRequired(v, 'CPF') != null)
                                  return 'CPF é obrigatório.';
                                if (!_cpfFormatter.isFill())
                                  return 'CPF incompleto.';
                                return null;
                              },
                            ),
                            _buildFormField(
                              context: context,
                              controller: _phoneController,
                              label: 'Telefone',
                              keyboardType: TextInputType.phone,
                              formatter: _phoneFormatter,
                              validator: (v) {
                                if (_validateRequired(v, 'Telefone') != null)
                                  return 'Telefone é obrigatório.';
                                if (!_phoneFormatter.isFill())
                                  return 'Telefone incompleto.';
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            const FormSectionTitle("Endereço"),
                            _buildFormField(
                              context: context,
                              controller: _streetController,
                              label: 'Rua/Avenida',
                              validator:
                                  (v) => _validateRequired(v, 'Rua/Avenida'),
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildFormField(
                                    context: context,
                                    controller: _numberController,
                                    label: 'Número',
                                    keyboardType: TextInputType.number,
                                    validator:
                                        (v) => _validateRequired(v, 'Número'),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildFormField(
                                    context: context,
                                    controller: _zipCodeController,
                                    label: 'CEP',
                                    keyboardType: TextInputType.number,
                                    formatter: _zipCodeFormatter,
                                    validator: (v) {
                                      if (_validateRequired(v, 'CEP') != null)
                                        return 'CEP é obrigatório.';
                                      if (!_zipCodeFormatter.isFill())
                                        return 'CEP incompleto.';
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            _buildFormField(
                              context: context,
                              controller: _neighborhoodController,
                              label: 'Bairro',
                              validator: (v) => _validateRequired(v, 'Bairro'),
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildFormField(
                                    context: context,
                                    controller: _cityController,
                                    label: 'Cidade',
                                    validator:
                                        (v) => _validateRequired(v, 'Cidade'),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildFormField(
                                    context: context,
                                    controller: _stateController,
                                    label: 'UF',
                                    validator:
                                        (v) => _validateRequired(v, 'UF'),
                                    inputFormatters: [
                                      LengthLimitingTextInputFormatter(2),
                                      UpperCaseTextFormatter(),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 30),
                            if (_isSaving)
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16.0),
                                  child: CircularProgressIndicator(
                                    color: levvaPrimaryColor,
                                  ),
                                ),
                              )
                            else
                              ElevatedButton(
                                onPressed: _saveProfile,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color.fromARGB(
                                    255,
                                    0,
                                    0,
                                    0,
                                  ),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  textStyle: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text('Salvar Alterações'),
                              ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              icon: const Icon(Icons.logout_outlined, size: 20),
                              label: const Text('Sair da Conta'),
                              onPressed: _isSaving ? null : _handleSignOut,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red.shade700,
                                side: BorderSide(
                                  color: Colors.red.shade400,
                                  width: 1.5,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFormField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    MaskTextInputFormatter? formatter,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade800,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6.0),
          TextFormField(
            controller: controller,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
                borderSide: BorderSide(color: Colors.grey.shade300, width: 1.0),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
                borderSide: BorderSide(color: Colors.grey.shade300, width: 1.0),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
                borderSide: BorderSide(color: levvaPrimaryColor, width: 1.5),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 14,
                horizontal: 16,
              ),
              errorStyle: const TextStyle(fontSize: 11),
            ),
            keyboardType: keyboardType,
            inputFormatters: [
              if (formatter != null) formatter,
              if (inputFormatters != null) ...inputFormatters,
            ],
            validator: validator,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            style: const TextStyle(fontSize: 15, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyField({required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade800,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6.0),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10.0),
              border: Border.all(color: Colors.grey.shade300, width: 1.0),
            ),
            child: Text(
              value.isEmpty ? 'Não informado' : value,
              style: TextStyle(
                fontSize: 15,
                color: value.isEmpty ? Colors.grey.shade600 : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeaderDelegate extends SliverPersistentHeaderDelegate {
  final AppUser user;
  final File? selectedImageFile;
  final VoidCallback onPickImage;
  final bool isUploadingImage;
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;
  final String logoPath;

  _ProfileHeaderDelegate({
    required this.user,
    this.selectedImageFile,
    required this.onPickImage,
    required this.isUploadingImage,
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
    required this.logoPath,
  });

  @override
  double get minExtent => 220.0;
  @override
  double get maxExtent => 260.0;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    ImageProvider? avatarBackgroundImage;
    if (selectedImageFile != null) {
      avatarBackgroundImage = FileImage(selectedImageFile!);
    } else if (user.profileImageUrl != null &&
        user.profileImageUrl!.isNotEmpty) {
      avatarBackgroundImage = NetworkImage(user.profileImageUrl!);
    }

    final double avatarRadius =
        60 - (shrinkOffset / maxExtent * 15).clamp(0, 15);
    final double topPositionForAvatar =
        maxExtent * 0.75 -
        avatarRadius -
        (shrinkOffset * 0.4).clamp(
          0,
          maxExtent * 0.75 -
              avatarRadius -
              (MediaQuery.of(context).padding.top + kToolbarHeight - 40),
        );

    return Container(
      color: Colors.grey[100],
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CustomPaint(
            size: Size(MediaQuery.of(context).size.width, maxExtent * 0.85),
            painter: _ProfileHeaderBackgroundPainter(
              colorMain: primaryColor,
              colorSecondary: secondaryColor,
              colorAccent: accentColor,
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 12,
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 22,
              ),
              onPressed: () => Navigator.of(context).pop(),
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFFB388FF).withOpacity(0.05),
                padding: const EdgeInsets.all(8),
              ),
            ),
          ),
          Positioned(
            top: topPositionForAvatar,
            left: 0,
            right: 0,
            child: Center(
              child: SizedBox(
                width: (avatarRadius * 2) + 8,
                height: (avatarRadius * 2) + 8,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(4),
                      child: CircleAvatar(
                        radius: avatarRadius,
                        backgroundColor: Colors.grey.shade300,
                        backgroundImage: avatarBackgroundImage,
                        child:
                            (avatarBackgroundImage == null && !isUploadingImage)
                                ? Icon(
                                  Icons.person_rounded,
                                  size: avatarRadius * 0.9,
                                  color: Colors.grey.shade500,
                                )
                                : null,
                      ),
                    ),
                    Positioned(
                      bottom: avatarRadius * 0.05,
                      right: avatarRadius * 0.05,
                      child: Material(
                        color: primaryColor,
                        shape: const CircleBorder(),
                        clipBehavior: Clip.antiAlias,
                        elevation: 2,
                        child: InkWell(
                          onTap: isUploadingImage ? null : onPickImage,
                          child: Padding(
                            padding: EdgeInsets.all(avatarRadius * 0.15),
                            child: Icon(
                              Icons.edit_rounded,
                              color: Colors.white,
                              size: avatarRadius * 0.3,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (isUploadingImage)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFB388FF).withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: PulsingLogoLoader(
                              imagePath: logoPath,
                              size: avatarRadius * 0.4,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _ProfileHeaderDelegate oldDelegate) {
    return user != oldDelegate.user ||
        selectedImageFile != oldDelegate.selectedImageFile ||
        onPickImage != oldDelegate.onPickImage ||
        isUploadingImage != oldDelegate.isUploadingImage ||
        primaryColor != oldDelegate.primaryColor ||
        secondaryColor != oldDelegate.secondaryColor ||
        accentColor != oldDelegate.accentColor;
  }
}

class _ProfileHeaderBackgroundPainter extends CustomPainter {
  final Color colorMain;
  final Color colorSecondary;
  final Color colorAccent;

  _ProfileHeaderBackgroundPainter({
    required this.colorMain,
    required this.colorSecondary,
    required this.colorAccent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paintMain = Paint()..color = colorMain;
    // final paintSecondary = Paint()..color = colorSecondary; // Descomente se usar uma segunda cor distinta para formas

    // CORREÇÃO 2: Aplicar opacidade à cor antes de passá-la para o Paint
    final paintAccentWithOpacity =
        Paint()..color = colorAccent.withOpacity(0.3);

    Path pathMain = Path();
    pathMain.moveTo(0, 0);
    pathMain.lineTo(0, size.height * 0.7);
    pathMain.quadraticBezierTo(
      size.width * 0.15,
      size.height * 0.95,
      size.width * 0.5,
      size.height * 0.85,
    );
    pathMain.quadraticBezierTo(
      size.width * 0.85,
      size.height * 0.75,
      size.width,
      size.height * 0.4,
    );
    pathMain.lineTo(size.width, 0);
    pathMain.close();
    canvas.drawPath(pathMain, paintMain);

    Path pathAccent = Path();
    pathAccent.moveTo(size.width, size.height * 0.6);
    pathAccent.quadraticBezierTo(
      size.width * 0.7,
      size.height * 0.9,
      size.width * 0.4,
      size.height,
    );
    pathAccent.lineTo(size.width, size.height);
    pathAccent.close();
    canvas.drawPath(
      pathAccent,
      paintAccentWithOpacity,
    ); // Usando o paint com opacidade
  }

  @override
  bool shouldRepaint(covariant _ProfileHeaderBackgroundPainter oldDelegate) {
    return oldDelegate.colorMain != colorMain ||
        oldDelegate.colorSecondary != colorSecondary ||
        oldDelegate.colorAccent != colorAccent;
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

class FormSectionTitle extends StatelessWidget {
  final String title;
  const FormSectionTitle(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
