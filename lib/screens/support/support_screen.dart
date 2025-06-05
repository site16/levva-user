// lib/screens/support/support_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Para SystemUiOverlayStyle
import 'package:url_launcher/url_launcher.dart';

// Modelo simples para item de FAQ
class FAQItem {
  final String id;
  final String question;
  final String answer;

  FAQItem({required this.id, required this.question, required this.answer});
}

class SupportScreen extends StatefulWidget {
  static const routeName = '/support';
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final List<FAQItem> _faqs = [
    FAQItem(
      id: 'faq1',
      question: 'Como solicito uma Levva?',
      answer:
          'No app, defina seu local de partida e destino. Escolha o tipo de veículo, a modalidade de entrega e a forma de pagamento. Depois, é só confirmar e aguardar seu entregador!',
    ),
    FAQItem(
      id: 'faq2',
      question: 'Quais são as formas de pagamento aceitas?',
      answer:
          'Atualmente, aceitamos Dinheiro, PIX e Cartão (o entregador levará a maquininha). Você também pode usar seu saldo Levva Pay para pagar suas corridas.',
    ),
    FAQItem(
      id: 'faq3',
      question: 'Posso cancelar uma Levva após solicitar?',
      answer:
          'Sim, você pode cancelar uma Levva. Se um entregador já tiver sido designado e estiver a caminho, uma pequena taxa de cancelamento pode ser aplicada. Consulte nossos Termos de Uso para mais detalhes.',
    ),
    FAQItem(
      id: 'faq4',
      question: 'Como me torno um entregador Levva?',
      answer:
          'Que ótimo! No menu principal do app, procure pela opção "Seja um Entregador" e siga as instruções para realizar seu cadastro. Nossa equipe analisará sua solicitação.',
    ),
    FAQItem(
      id: 'faq5',
      question: 'Meu cupom de desconto não funcionou, o que fazer?',
      answer:
          'Verifique a data de validade e os termos de uso do cupom na tela "Meus Descontos". Certifique-se de que o código foi digitado corretamente. Se o problema persistir, entre em contato com nosso suporte.',
    ),
  ];


  final String _supportEmail = 'suporte@levva.com.br';
  final String _supportPhone = '+5562912345678'; // Exemplo de número
  final String _faqUrl = 'https://www.levva.com.br/ajuda';

  Future<void> _launchUniversal(String url) async {
    final Uri uri = Uri.parse(url);
    if (mounted) {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível abrir o link: $url')),
        );
      }
    }
  }

  Future<void> _launchEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: _supportEmail,
      queryParameters: {'subject': Uri.encodeComponent('Suporte App Levva - Dúvida')},
    );
     if (mounted) {
      if (!await launchUrl(emailLaunchUri)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível abrir o app de e-mail.')),
        );
      }
    }
  }

  Future<void> _launchPhone() async {
    final Uri phoneLaunchUri = Uri(scheme: 'tel', path: _supportPhone);
    if (mounted) {
      if (!await launchUrl(phoneLaunchUri)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível realizar a ligação.')),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Seu tema (preto e branco)

    return Scaffold(
      backgroundColor: Colors.grey[100], // Fundo cinza claro consistente
      appBar: AppBar(
        leading: IconButton( // Botão de voltar padrão
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 22),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Voltar',
        ),
        title: Text(
          'Ajuda e Suporte',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white, // Fundo branco
        elevation: 0.8, // Sombra sutil
        scrolledUnderElevation: 1.0,
        systemOverlayStyle: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent,
        ),
      ),
      body: SingleChildScrollView( // SafeArea não é mais necessária aqui com AppBar sólida
        // padding: const EdgeInsets.only(top: kToolbarHeight * 0.5), // Removido
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.support_agent_rounded,
                    size: 64, // Tamanho um pouco menor
                    color: theme.colorScheme.primary, // Preto
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Como podemos te ajudar?',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onBackground, // Preto
                    ),
                  ),
                  const SizedBox(height: 12), // Aumentado um pouco
                  Text(
                    'Encontre respostas rápidas para suas dúvidas mais comuns ou entre em contato conosco se precisar de mais assistência.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontSize: 15,
                      color: theme.colorScheme.onBackground.withOpacity(0.75), // Cinza escuro
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Seção de Perguntas Frequentes
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0), // Padding lateral
              child: Text(
                "Perguntas Frequentes",
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onBackground,
                  fontSize: 18, // Tamanho de título de seção
                ),
              ),
            ),
            const SizedBox(height: 10.0),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0), // Padding para os painéis
              child: ExpansionPanelList.radio(
                elevation: 1, // Sombra sutil para os painéis
                expandedHeaderPadding: const EdgeInsets.symmetric(vertical: 8.0), // Padding interno ajustado
                dividerColor: Colors.grey.shade200, // Divisor mais sutil
                initialOpenPanelValue: null,
                expansionCallback: (int index, bool isExpanded) {
                  setState(() {
                    // Lógica para abrir apenas um painel por vez (modo rádio)
                  });
                },
                children: _faqs.map<ExpansionPanelRadio>((FAQItem item) {
                  return ExpansionPanelRadio(
                    value: item.id,
                    canTapOnHeader: true,
                    backgroundColor: Colors.white, // Fundo branco para o painel
                    headerBuilder: (BuildContext context, bool isExpanded) {
                      return Padding( // Padding adicionado ao ListTile
                        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                        child: Text(
                          item.question,
                          style: TextStyle(
                            fontWeight: isExpanded ? FontWeight.w600 : FontWeight.w500,
                            color: isExpanded ? theme.colorScheme.primary : theme.colorScheme.onSurface, // Preto
                            fontSize: 15,
                          ),
                        ),
                      );
                    },
                    body: Padding(
                      padding: const EdgeInsets.fromLTRB(24.0, 0, 24.0, 16.0), // Padding ajustado
                      child: Text(
                        item.answer,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.45, // Espaçamento entre linhas
                          color: theme.colorScheme.onSurface.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 30.0),

            // Seção de Contato
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                'Ainda precisa de Ajuda?',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onBackground,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(height: 12.0),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              elevation: 1.5, // Sombra sutil
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.email_outlined, color: theme.colorScheme.primary),
                    title: Text('Enviar E-mail', style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w500)),
                    subtitle: Text(_supportEmail, style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7))),
                    trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                    onTap: _launchEmail,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  ),
                  if (_supportPhone.isNotEmpty) ...[
                    Divider(height: 0.5, indent: 16, endIndent: 16, color: Colors.grey.shade200),
                    ListTile(
                      leading: Icon(Icons.phone_outlined, color: theme.colorScheme.primary),
                      title: Text('Ligar para Suporte', style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w500)),
                      subtitle: Text('Disponível em horário comercial', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7))),
                      trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                      onTap: _launchPhone,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                    ),
                  ],
                  if (_faqUrl.isNotEmpty) ...[
                    Divider(height: 0.5, indent: 16, endIndent: 16, color: Colors.grey.shade200),
                    ListTile(
                      leading: Icon(Icons.public_outlined, color: theme.colorScheme.primary),
                      title: Text('Central de Ajuda Online', style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w500)),
                      subtitle: Text('Veja mais FAQs e tutoriais', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7))),
                      trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                      onTap: () => _launchUniversal(_faqUrl), // Usando _launchUniversal
                      contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 30.0), // Espaço no final da tela
          ],
        ),
      ),
    );
  }
}