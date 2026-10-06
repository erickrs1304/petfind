import 'package:share_plus/share_plus.dart';

import '../data/models/animal.dart';
import 'formatters.dart';

// Compartilhamento do caso via share sheet do sistema — atende o botão
// "Compartilhar caso" (RF-007 A1) e "Compartilhar boa notícia" (RF-009, passo 8).

/// Divulgação de um caso ainda em busca.
Future<void> compartilharCaso(Animal animal) {
  final linhas = [
    '🐾 AJUDE A ENCONTRAR ${animal.nome.toUpperCase()}!',
    '',
    'Espécie: ${animal.especie}',
    if (animal.raca != null && animal.raca!.isNotEmpty) 'Raça: ${animal.raca}',
    if (animal.porte != null && animal.porte!.isNotEmpty) 'Porte: ${animal.porte}',
    'Características: ${animal.caracteristicas}',
    'Desapareceu em: ${formatarData(animal.dataDesaparecimento)}',
    'Última localização: ${animal.ultimaLocalizacaoTexto}',
    '',
    'Viu esse animal? Registre o avistamento no PetFind e ajude a levá-lo de volta para casa.',
  ];

  return _compartilhar(linhas.join('\n'), assunto: 'Animal perdido: ${animal.nome}');
}

/// Aviso de que o caso foi encerrado com o animal encontrado.
Future<void> compartilharBoaNoticia(Animal animal) {
  final texto = [
    '🎉 ${animal.nome} FOI ENCONTRADO!',
    '',
    'O caso foi encerrado no PetFind. Obrigado a todos que ajudaram na busca!',
  ].join('\n');

  return _compartilhar(texto, assunto: '${animal.nome} foi encontrado!');
}

Future<void> _compartilhar(String texto, {required String assunto}) async {
  await SharePlus.instance.share(ShareParams(text: texto, subject: assunto));
}
