// lib/screens/legal/terms_of_use_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Para SystemUiOverlayStyle

class TermsOfUseScreen extends StatelessWidget {
  static const routeName = '/terms-of-use';
  const TermsOfUseScreen({super.key});

  // Placeholder para o conteúdo dos Termos de Uso
  // IMPORTANTE: Substitua este conteúdo pelos seus Termos de Uso reais.
  static const String _lastUpdated = "Última atualização: 18 de Maio de 2025";

  static const List<Map<String, String>> _termsSections = [
    {
      "title": "1. Bem-vindo(a) ao Levva!",
      "content":
          "Estes Termos de Uso ('Termos') regem seu acesso e uso do aplicativo móvel Levva e de quaisquer serviços relacionados (coletivamente, o 'Serviço') fornecidos pela Levva Tecnologias Ltda ('Levva', 'nós', 'nosso'). Ao baixar, acessar ou usar o Serviço, você concorda em ficar vinculado por estes Termos. Se você não concordar com qualquer parte destes Termos, você não deve usar o Serviço.\n\n"
          "POR FAVOR, LEIA ESTES TERMOS COM ATENÇÃO, POIS ELES CONTÊM INFORMAÇÕES IMPORTANTES SOBRE SEUS DIREITOS LEGAIS, RECURSOS E OBRIGAÇÕES.",
    },
    {
      "title": "2. O Serviço Levva",
      "content":
          "O Serviço Levva é uma plataforma tecnológica que permite aos usuários de nossos aplicativos móveis organizar e agendar serviços de transporte e/ou logística com terceiros independentes provedores desses serviços, incluindo motoristas e entregadores parceiros ('Prestadores Terceirizados').\n\n"
          "VOCÊ RECONHECE QUE A LEVVA NÃO FORNECE SERVIÇOS DE TRANSPORTE OU LOGÍSTICA NEM FUNCIONA COMO UMA TRANSPORTADORA E QUE TODOS ESSES SERVIÇOS DE TRANSPORTE OU LOGÍSTICA SÃO FORNECIDOS POR PRESTADORES TERCEIRIZADOS INDEPENDENTES QUE NÃO SÃO EMPREGADOS PELA LEVVA NEM POR QUALQUER DE SUAS AFILIADAS.",
    },
    {
      "title": "3. Elegibilidade e Contas de Usuário",
      "content":
          "Para usar a maioria dos aspectos dos Serviços, você deve se registrar e manter uma conta de usuário ativa dos Serviços ('Conta'). Você deve ter pelo menos 18 anos de idade, ou a idade da maioridade legal em sua jurisdição (se diferente de 18 anos), para obter uma Conta. O registro da Conta exige que você envie à Levva certas informações pessoais, como seu nome, endereço, número de telefone celular e idade, bem como pelo menos um método de pagamento válido (seja um cartão de crédito ou parceiro de pagamento aceito).\n\n"
          "Você concorda em manter informações precisas, completas e atualizadas em sua Conta. Sua falha em manter informações precisas, completas e atualizadas da Conta, incluindo ter um método de pagamento inválido ou expirado arquivado, pode resultar na sua incapacidade de acessar e usar os Serviços ou na rescisão destes Termos pela Levva com você.",
    },
    {
      "title": "4. Conduta e Obrigações do Usuário",
      "content":
          "Você não pode autorizar terceiros a usar sua Conta. Você não pode ceder ou de outra forma transferir sua Conta para qualquer outra pessoa ou entidade. Você concorda em cumprir todas as leis aplicáveis ao usar os Serviços e só pode usar os Serviços para fins lícitos.\n\n"
          "Em certos casos, você pode ser solicitado a fornecer prova de identidade para acessar ou usar os Serviços, e você concorda que pode ser negado o acesso ou uso dos Serviços se você se recusar a fornecer prova de identidade.",
    },
    {
      "title": "5. Pagamento",
      "content":
          "Você entende que o uso dos Serviços pode resultar em cobranças para você pelos serviços ou bens que você recebe de um Prestador Terceirizado ('Cobranças'). Após você ter recebido serviços ou bens obtidos através do seu uso do Serviço, a Levva facilitará seu pagamento das Cobranças aplicáveis em nome do Prestador Terceirizado como agente de cobrança limitado do Prestador Terceirizado.\n\n"
          "Todas as Cobranças são devidas imediatamente e o pagamento será facilitado pela Levva usando o método de pagamento preferido designado em sua Conta, após o qual a Levva enviará um recibo por e-mail.",
    },
    {
      "title": "15. Alterações aos Termos",
      "content":
          "A Levva reserva-se o direito, a seu exclusivo critério, de modificar ou substituir estes Termos a qualquer momento. Se uma revisão for material, tentaremos fornecer um aviso prévio de pelo menos 30 dias antes de quaisquer novos termos entrarem em vigor. O que constitui uma alteração material será determinado a nosso exclusivo critério.",
    },
    {
      "title": "16. Contato",
      "content":
          "Se você tiver alguma dúvida sobre estes Termos, entre em contato conosco em: suporte@levva.com.br\n\n"
          "Levva Tecnologias Ltda.\n"
          "Avenida Goiás, 123 - Centro\n"
          "Goianésia - GO, CEP 76380-000\n"
          "CNPJ: 00.000.000/0001-00",
    },
  ];

  Widget _buildSectionTitle(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 10.0),
      child: Text(
        title,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onBackground, // Preto
          fontSize: 18,
        ),
      ),
    );
  }

  Widget _buildSectionContent(BuildContext context, String content) {
    final theme = Theme.of(context);
    return Text(
      content,
      textAlign: TextAlign.justify,
      style: theme.textTheme.bodyMedium?.copyWith(
        height: 1.55,
        fontSize: 14.5,
        color: theme.colorScheme.onBackground.withOpacity(0.8), // Cinza escuro
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white, // Fundo branco para a tela
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 22),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Voltar',
        ),
        title: Text(
          'Termos de Uso',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white, // Fundo branco da AppBar
        elevation: 0.8, // Sombra sutil para destacar a AppBar
        scrolledUnderElevation: 1.0, // Sombra quando há scroll sob ela
        systemOverlayStyle: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent, // Para a barra de status se mesclar
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0), // Padding geral
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Termos e Condições de Uso - Levva',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onBackground,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _lastUpdated,
              style: theme.textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 16),
            Divider(color: Colors.grey.shade300), // Divisor sutil
            ..._termsSections.map((section) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle(context, section['title']!),
                  _buildSectionContent(context, section['content']!),
                ],
              );
            }).toList(),
            const SizedBox(height: 30),
            Center(
              child: Text(
                "© ${DateTime.now().year} Levva Tecnologias Ltda. Todos os direitos reservados.",
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            ),
            const SizedBox(height: 20), // Espaço no final da página
          ],
        ),
      ),
    );
  }
}