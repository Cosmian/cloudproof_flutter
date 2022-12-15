import 'dart:typed_data';

import 'package:cloudproof/cloudproof.dart';

class CoverCryptHelper {
  late Policy policy;
  late Uint8List userSecretKey;
  late CoverCryptMasterKeys masterKeys;

  CoverCryptHelper() {
    policy = Policy.withMaxAttributeCreations(100)
        .addAxis(
            "Security Level",
            [
              "Protected",
              "Low Secret",
              "Medium Secret",
              "High Secret",
              "Top Secret"
            ],
            true)
        .addAxis("Department", ["R&D", "HR", "MKG", "FIN"], false);
    masterKeys = CoverCrypt.generateMasterKeys(policy);

    userSecretKey = CoverCrypt.generateUserSecretKey(
        "(Department::MKG || Department:: FIN) && Security Level::Top Secret",
        policy,
        masterKeys.masterSecretKey);
  }
}
