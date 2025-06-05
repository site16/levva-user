// lib/screens/levva_pay/levva_pay_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart'; // Para formatação de moeda
import 'package:provider/provider.dart';
import '../../providers/levva_pay_provider.dart'; // Seu provider
import '../../models/transaction_model.dart'; // Seu modelo de transação

// NOTA: As definições de TransactionModel e TransactionType abaixo são exemplos.
// Utilize as definições do seu próprio projeto em 'lib/models/transaction_model.dart'.
// Se já as tiver lá, pode remover estas definições daqui.
/*
enum TransactionType { gastoCorrida, deposito, saque, bonus, ajuste, outros }

class TransactionModel {
  final String id;
  final String description;
  final Timestamp date; // Supondo que você use Timestamp do Firestore
  final double amount;
  final TransactionType type;
  final String? rideId; // Opcional, para vincular a uma corrida

  TransactionModel({
    required this.id,
    required this.description,
    required this.date,
    required this.amount,
    required this.type,
    this.rideId,
  });
}
*/
// Fim da nota sobre TransactionModel e TransactionType

class LevvaPayScreen extends StatefulWidget {
  static const routeName = '/levva-pay';
  const LevvaPayScreen({super.key});

  @override
  State<LevvaPayScreen> createState() => _LevvaPayScreenState();
}

class _LevvaPayScreenState extends State<LevvaPayScreen> {
  bool _isBalanceVisible = true;

  void _toggleBalanceVisibility() {
    setState(() {
      _isBalanceVisible = !_isBalanceVisible;
    });
  }

  void _showDevelopmentSnackbar(BuildContext context, String featureName) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$featureName: Em desenvolvimento.'),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.blueGrey.shade700,
      ),
    );
  }


  IconData _getTransactionIcon(TransactionType type) {
    // Adapte os ícones conforme os tipos no seu enum TransactionType
    switch (type) {
      case TransactionType.gastoCorrida:
        return Icons.two_wheeler_outlined;
      case TransactionType.deposito:
        return Icons.input_rounded; // Ícone para entrada/depósito
      case TransactionType.saque:
        return Icons.output_rounded; // Ícone para saída/saque
      case TransactionType.bonus:
        return Icons.star_outline_rounded;
      case TransactionType.ajuste:
        return Icons.tune_outlined;
      default:
        return Icons.receipt_long_outlined;
    }
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    Color? backgroundColor,
    Gradient? gradient, // Adicionado para permitir gradiente
    required Color contentColor,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 8.0),
          decoration: BoxDecoration(
            gradient: gradient, // Usa gradiente se fornecido
            color: gradient == null ? backgroundColor : null, // Usa cor sólida se gradiente for nulo
            borderRadius: BorderRadius.circular(12.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 6,
                offset: const Offset(0, 3),
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 28, color: contentColor),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11.5,
                  color: contentColor,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionItem(BuildContext context, TransactionModel transaction, NumberFormat formatter) {
    final bool isCredit = transaction.amount >= 0;
    final Color amountColor = isCredit ? Colors.greenAccent.shade400 : Colors.redAccent.shade400; // Ajustado para melhor visibilidade no tema escuro
    final String amountPrefix = transaction.amount == 0 ? '' : (isCredit ? '+' : '');

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5.0),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2E), // Cinza escuro para os itens da transação
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: (isCredit ? Colors.greenAccent.shade700 : Colors.redAccent.shade700).withOpacity(0.15),
            child: Icon(_getTransactionIcon(transaction.type), color: (isCredit ? Colors.greenAccent.shade400 : Colors.redAccent.shade400) , size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description,
                  style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w500, color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                   DateFormat('dd/MM/yy \'às\' HH:mm', 'pt_BR').format(transaction.date.toDate()), // Supondo que transaction.date é Timestamp
                  style: TextStyle(fontSize: 11.5, color: Colors.grey[400]),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$amountPrefix${formatter.format(transaction.amount)}',
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.bold,
              color: amountColor,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final levvaPayProvider = Provider.of<LevvaPayProvider>(context);
    final NumberFormat currencyFormatter = NumberFormat.simpleCurrency(locale: 'pt_BR');

    // Cores do tema escuro
    const Color screenBackgroundColor = Color(0xFF1E1E1E); // Cinza bem escuro quase preto

    // Cores para o gradiente VERMELHO do card de saldo e botão Adicionar Dinheiro
    const Color primaryRedGradient = Color(0xFFE53935); // Vermelho vibrante (ex: Red 600)
    const Color secondaryRedGradient = Color(0xFFC62828); // Vermelho mais profundo (ex: Red 800)

    // Gradiente para o card de saldo
    const LinearGradient balanceCardRedGradient = LinearGradient(
      colors: [primaryRedGradient, secondaryRedGradient],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      stops: [0.0, 0.9],
    );

    // Gradiente para o botão Adicionar Dinheiro
    const LinearGradient addMoneyButtonRedGradient = LinearGradient(
      colors: [primaryRedGradient, secondaryRedGradient], // Pode usar as mesmas cores ou variar
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );

    // Cores para outros botões de ação
    const Color actionButtonBackgroundColor = Color(0xFF2C2C2E); // Cinza escuro
    const Color actionButtonContentColor = Colors.white70;


    return Scaffold(
      backgroundColor: screenBackgroundColor,
      appBar: AppBar(
        leading: IconButton( // Botão de voltar padrão
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 22),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Voltar',
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/levva_icon_transp_branco.png', // Sua logo branca
              height: 22,
            ),
            const SizedBox(width: 8),
            const Text(
              'LevvaPay',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: screenBackgroundColor, // Cor da AppBar igual ao fundo da tela
        elevation: 0, // Sem sombra
        systemOverlayStyle: SystemUiOverlayStyle.light, // Ícones da barra de status (hora, bateria) brancos
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Atualiza as transações e o saldo (se o provider tiver essa lógica separada)
          await levvaPayProvider.refreshTransactions();
          // Se o saldo não for atualizado com refreshTransactions, chame um método específico:
          // await levvaPayProvider.fetchBalance();
        },
        color: Colors.white, // Cor do spinner do refresh
        backgroundColor: actionButtonBackgroundColor, // Fundo do spinner do refresh
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
          children: [
            // Card de Saldo
            Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16.0),
                gradient: balanceCardRedGradient, // Aplicando o gradiente vermelho
                boxShadow: [
                  BoxShadow(
                    color: secondaryRedGradient.withOpacity(0.3), // Sombra sutil baseada no gradiente
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start, // Alinha logo e texto ao topo
                    children: [
                      const Text(
                        'Saldo em Carteira',
                        style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w500),
                      ),
                      // Logo Levva no canto superior direito
                      Image.asset(
                        'assets/images/levva_icon_transp_branco.png',
                        height: 28, // Ajuste o tamanho da logo
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     crossAxisAlignment: CrossAxisAlignment.end, // Alinha o botão de visibilidade com a base do saldo
                     children: [
                        Flexible(
                          child: Text(
                            _isBalanceVisible
                                ? currencyFormatter.format(levvaPayProvider.currentBalance)
                                : 'R\$ ••••••',
                            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5),
                            overflow: TextOverflow.ellipsis, // Caso o saldo seja muito grande
                          ),
                        ),
                        Padding( // Adiciona um padding para o botão de visibilidade não ficar colado
                          padding: const EdgeInsets.only(left: 8.0),
                          child: IconButton(
                            icon: Icon(
                              _isBalanceVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: Colors.white.withOpacity(0.9),
                              size: 22,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            tooltip: _isBalanceVisible ? "Ocultar Saldo" : "Mostrar Saldo",
                            onPressed: _toggleBalanceVisibility,
                          ),
                        ),
                     ],
                  ),
                  // Ícones decorativos foram removidos
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Botões de Ação
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildActionButton(
                  icon: Icons.add_card_outlined, // Ícone para adicionar dinheiro
                  label: 'Adicionar Dinheiro',
                  onPressed: () => _showDevelopmentSnackbar(context, 'Adicionar Dinheiro'),
                  gradient: addMoneyButtonRedGradient, // Aplicando gradiente vermelho
                  backgroundColor: null, // Cor sólida não será usada devido ao gradiente
                  contentColor: Colors.white, // Texto e ícone brancos
                ),
                const SizedBox(width: 12),
                _buildActionButton(
                  icon: Icons.receipt_long_outlined,
                  label: 'Extrato',
                  onPressed: () => _showDevelopmentSnackbar(context, 'Extrato'),
                  backgroundColor: actionButtonBackgroundColor, // Cinza escuro
                  gradient: null, // Sem gradiente
                  contentColor: actionButtonContentColor,
                ),
                const SizedBox(width: 12),
                _buildActionButton(
                  icon: Icons.upload_rounded, // Ícone para "Sacar"
                  label: 'Sacar', // Texto conforme solicitado
                  onPressed: () => _showDevelopmentSnackbar(context, 'Sacar'),
                  backgroundColor: actionButtonBackgroundColor, // Cinza escuro
                  gradient: null, // Sem gradiente
                  contentColor: actionButtonContentColor,
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Título "Últimas Movimentações"
            Text(
              'Últimas Movimentações',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white.withOpacity(0.9)),
            ),
            const SizedBox(height: 12),

            // Lista de Transações
            if (levvaPayProvider.isLoading && levvaPayProvider.transactions.isEmpty)
              const Center(child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(color: Colors.white),
              ))
            else if (levvaPayProvider.transactions.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 30.0),
                  child: Column(
                    children: [
                      Icon(Icons.history_toggle_off_rounded, size: 60, color: Colors.grey.shade600),
                      const SizedBox(height: 16),
                      Text(
                        'Nenhuma movimentação recente.',
                        style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: levvaPayProvider.transactions.length > 5 ? 5 : levvaPayProvider.transactions.length, // Mostra até 5 transações
                itemBuilder: (ctx, index) {
                  final transaction = levvaPayProvider.transactions[index];
                  return _buildTransactionItem(context, transaction, currencyFormatter);
                },
              ),
          ],
        ),
      ),
    );
  }
}