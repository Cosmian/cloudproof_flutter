import 'dart:typed_data';

class Metadata {
  Uint8List uid;
  Uint8List additionalData;

  Metadata(this.uid, this.additionalData);
}
