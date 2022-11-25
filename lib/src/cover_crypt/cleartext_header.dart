import 'dart:typed_data';

class CleartextHeader {
  Uint8List cleartext;
  Uint8List metadata;

  CleartextHeader(this.cleartext, this.metadata);
}
