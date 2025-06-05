import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart'; // Importa o pacote Google Sign-In

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  AuthService(FirebaseAuth instance); // Instancia o GoogleSignIn

  // Stream para ouvir mudanças no estado de autenticação do Firebase
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // Getter para o usuário atual do Firebase
  User? get currentUser => _firebaseAuth.currentUser;

  // Método para fazer login com Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // 1. Inicia o fluxo de login do Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      // Se o usuário cancelar o fluxo, googleUser será nulo
      if (googleUser == null) {
        print('Login com Google cancelado pelo usuário.');
        return null; // Retorna nulo para indicar cancelamento ou falha inicial
      }

      // 2. Obtém os detalhes de autenticação da conta Google
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // 3. Cria uma Credencial do Firebase usando o idToken e accessToken do Google
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Faz login no Firebase usando a credencial do Google
      return await _firebaseAuth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      // Trata erros específicos do Firebase Auth durante o signInWithCredential
      print("Erro FirebaseAuth no login com Google: ${e.code} - ${e.message}");
      rethrow; // Re-lança a exceção para ser tratada no AuthProvider/UI
    } catch (e) {
      // Trata outros erros (problemas de rede, erros no pacote google_sign_in)
      print("Erro geral no login com Google: ${e.toString()}");
      rethrow; // Re-lança a exceção
    }
  }

  // Método para fazer logout
  Future<void> signOut() async {
    try {
      // Tenta deslogar do Google Sign-In primeiro
      await _googleSignIn.signOut();
      print("Deslogado do Google Sign-In.");
    } catch (e) {
      print("Erro ao deslogar do Google Sign-In: ${e.toString()}");
      // Continua mesmo se houver erro no signOut do Google
    }
    try {
      // Desloga do Firebase Auth
      await _firebaseAuth.signOut();
      print("Deslogado do Firebase Auth.");
    } catch (e) {
      print("Erro ao deslogar do Firebase Auth: ${e.toString()}");
      // Considerar o que fazer em caso de erro aqui
    }
  }

  // Métodos relacionados ao login por telefone foram removidos:
  // - _verificationId
  // - _resendToken
  // - verifyPhoneNumber
  // - signInWithSmsCode
  // - resendSmsCode
}
