import 'dart:typed_data';

import 'package:cloudproof/src/cover_crypt/metadata.dart';

class ClearTextHeader {
  static const symmetricKeySize = 32;

  Uint8List symmetricKey;
  Metadata metadata;

  ClearTextHeader(this.symmetricKey, this.metadata);
}
