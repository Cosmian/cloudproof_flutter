import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:cloudproof/cloudproof.dart';
import 'package:cloudproof_demo/main.dart' as app;

import '../../test/findex/in_memory_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('end-to-end test', () {
    testWidgets('tap on the floating action button, verify counter',
        (tester) async {
      app.main();
      final encrypted = base64Decode(
          "3DnOR7troSUW3TJA7rRltGzkqz5eVzfqOnTLupvliy/w7XRzQ6uPIkiRjtfHnOwH7ewmUHbiq/8Di9/RZQuWIAEtfSF6I+gHUChts2uoQklvQ4miSoLx8KYacB2VxYfOu7ad8DdoWK8uShldAhP6vl0tgmSvWW+Qn5q7OoIjjU4PIgoeFPl1REJ93rPizbde2nM/wkHEqDvcbVvOScvApjdn7hfmLIWGRghzZLBJj+4wFBoAAMdzZGuiZ9QnG0dXmcZdjgKH5ZpHTDjbdR4JraI7FaF8");

      final key = base64Decode(
          "jHlN6FrJyNDvNV5mS2bOXfGjXkvvPUG8IOQoHJGqIgvirbMshM0uO2QpBLV6h4cDOkGF2PtR5Jo8XB4avhcgAQqpJbg/a6k2gSFaJiQkTgvjpOveCwY1ko62SmBuNTn1B5gBgPeox1CtyBN8LlILnYIK3lK22e4n+1S8Alr6SK8BXMGnOPN6WCU5YavcsnCT4zsVkw9RryzQql7UhNKoNQSsjEt3Ol/64qXHZNR0L4JC8QLPX8HunDLylDy5R0EaDxqT6rI9latktRUAwBwmr0lXPdtnsAEMZ9yHe0Zfb6cCLQ1vNSXZ+OGjq6+ktbabJ0QSbrxEPJ1XscyZmc7mWwAKerIZLvW2umrvT9p5s0FlVqH7G1upDmynT6douwaRCU6KzaS6wDo+rf63jdqd3wIGq3IljQ1/Lv8oMAEfmHYG43HxsKHQcxGzHd/+Phi98crqZLlevV2/HNB/QGoQvgU9uZqTzUdUcH2EUKyEO0FF4dXcpixLe9hNkpBQ5Po1Dg==");

      final plaintext = base64Decode("VG9wU2VjcmV0TWtnUGxhaW50ZXh0");
      final authenticationData = base64Decode("BwgJCgs=");

      final result = CoverCrypt.decryptWithAuthenticationData(
          key, encrypted, authenticationData);

      expect(result.plaintext, equals(plaintext));

      final masterKey =
          FindexMasterKey(base64Decode("6hb1TznoNQFvCWisGWajkA=="));
      final label = Uint8List.fromList(utf8.encode("Some Label"));
      await testFunction(masterKey, label);

      print("findex and cover_crypt OK");
    });
  });
}
