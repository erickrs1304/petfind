import 'dart:typed_data';

// Representa uma foto selecionada pelo usuário como bytes em memória, para
// que o mesmo fluxo funcione tanto em mobile (dart:io File) quanto na web
// (onde não há acesso a caminhos de arquivo reais).
class PickedPhoto {
  const PickedPhoto({required this.bytes, required this.filename});

  final Uint8List bytes;
  final String filename;
}
