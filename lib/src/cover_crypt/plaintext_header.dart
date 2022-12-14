import 'dart:typed_data';

class PlaintextHeader {
  Uint8List plaintext;
  Uint8List headerMetadata;

  PlaintextHeader(this.plaintext, this.headerMetadata);
}
