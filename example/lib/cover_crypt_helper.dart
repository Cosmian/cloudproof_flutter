import 'dart:typed_data';

import 'package:cloudproof/cloudproof.dart';
import 'package:tuple/tuple.dart';

class CoverCryptHelper {
  late Policy policy;
  late Uint8List userSecretKey;
  late CoverCryptMasterKeys masterKeys;

  CoverCryptHelper() {
    policy = Policy.init()
        .addAxis(
            "Security Level",
            [
              const Tuple2("Protected", false),
              const Tuple2("Low Secret", false),
              const Tuple2("Medium Secret", false),
              const Tuple2("High Secret", false),
              const Tuple2("Top Secret", false),
            ],
            true)
        .addAxis(
            "Department",
            [
              const Tuple2("R&D", false),
              const Tuple2("HR", false),
              const Tuple2("MKG", false),
              const Tuple2("FIN", false)
            ],
            false);
    masterKeys = CoverCrypt.generateMasterKeys(policy);

    userSecretKey = CoverCrypt.generateUserSecretKey(
        "(Department::MKG || Department:: FIN) && Security Level::Top Secret",
        policy,
        masterKeys.masterSecretKey);
  }
}
