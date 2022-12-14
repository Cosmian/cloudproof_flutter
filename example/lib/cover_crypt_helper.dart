import 'dart:typed_data';

import 'package:cloudproof/cloudproof.dart';

class CoverCryptHelper {
  late String policy;
  late Uint8List userSecretKey;
  late CoverCryptMasterKeys masterKeys;

  CoverCryptHelper() {
    policy =
        "{\"last_attribute_value\":9,\"max_attribute_creations\":100,\"axes\":{\"Department\":[[\"R&D\",\"HR\",\"MKG\",\"FIN\"],false],\"Security Level\":[[\"Protected\",\"Low Secret\",\"Medium Secret\",\"High Secret\",\"Top Secret\"],true]},\"attribute_to_int\":{\"Security Level::Medium Secret\":[3],\"Security Level::Protected\":[1],\"Security Level::High Secret\":[4],\"Department::R&D\":[6],\"Department::HR\":[7],\"Security Level::Low Secret\":[2],\"Department::MKG\":[8],\"Security Level::Top Secret\":[5],\"Department::FIN\":[9]}}";
    masterKeys = CoverCrypt.generateMasterKeys(policy);

    userSecretKey = CoverCrypt.generateUserSecretKey(
        "(Department::MKG || Department:: FIN) && Security Level::Top Secret",
        policy,
        masterKeys.masterSecretKey);
  }
}
