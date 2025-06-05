// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Importa o arquivo main.dart onde LevvaApp está definido
import 'package:levva/main.dart'; // Certifique-se que 'levva' é o nome do seu pacote/pasta lib

void main() {
  // O teste padrão do contador não se aplica mais diretamente à estrutura do seu app,
  // pois a tela inicial agora é um AuthWrapper que leva a LoginScreen ou HomeScreen,
  // e não mais a uma tela com um contador.
  //
  // Você precisará adaptar este teste para verificar elementos da sua LoginScreen
  // ou HomeScreen, ou criar novos testes específicos para suas funcionalidades.
  //
  // Por enquanto, vamos apenas corrigir o nome do widget principal para que o teste
  // possa pelo menos tentar construir o app sem o erro de 'MyApp'.
  // Um teste mais significativo seria, por exemplo, verificar se a LoginScreen aparece.

  testWidgets('App builds and shows LoginScreen initially (example)', (
    WidgetTester tester,
  ) async {
    // Constrói o app e dispara um frame.
    // É importante que o Firebase seja inicializado nos testes também,
    // o que pode requerer configurações adicionais no setup do teste
    // se os widgets dependerem de dados do Firebase para construir.
    // Para um teste simples de UI inicial, podemos mockar ou prover
    // estados iniciais para os providers.

    // Para este exemplo, vamos apenas construir o app.
    // Em um cenário real, você pode precisar mockar o Firebase.
    // Veja a documentação do FlutterFire sobre testes.

    await tester.pumpWidget(
      const LevvaApp(),
    ); // Alterado de MyApp para LevvaApp

    // Exemplo de verificação: Verifica se um widget da LoginScreen está presente.
    // Este é um exemplo e pode precisar ser ajustado com base no conteúdo exato
    // da sua LoginScreen.
    // Por exemplo, se a LoginScreen tem um título 'Levva - Entrar':
    expect(find.text('Levva - Entrar'), findsOneWidget);
    // Ou se tem um campo de texto com o label 'Telefone (DDD + Número)':
    expect(
      find.widgetWithText(TextFormField, 'Telefone (DDD + Número)'),
      findsOneWidget,
    );

    // O teste original do contador não faz mais sentido aqui:
    // expect(find.text('0'), findsOneWidget);
    // expect(find.text('1'), findsNothing);
    // await tester.tap(find.byIcon(Icons.add));
    // await tester.pump();
    // expect(find.text('0'), findsNothing);
    // expect(find.text('1'), findsOneWidget);
  });
}
