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
    testWidgets('run app and check link over cloudproof static lib',
        (tester) async {
      app.main();

      final encrypted = base64Decode(
          "/i6YTjLUDJHMLezlNkBaL5L76XpqGlJ4+8/+KrDNFTXY0Muh2ECoo4hwkYrpVAma+qhvWIqlBsaM92OmQnL1VZ/7CR9D0Jd2d5V7RrrPmKMBAFBMdBCPr+1XWuzLrefTyo94RoCT+PDkpLn9YhiPtcNDABqGUvrekTkOO2o+yt5L7bm0KadyOcjERUttmoSmDfIr0lEoFpKQJCOkHQ5DwZouZ2Y=");

      final key = base64Decode(
          "NpzWWCt372s6WFrc1J2pSUVCBKlNqhNvnaznWJHz8gUSYcFJQ5nae5v0mjPQeSN0V8mdJ1W1n4bnYoEDlEIGAgoCBQgBAKSJW1XQGmevE28HdBxgR01GyNDX5THXjVkKKjGmMmIJAgIIAQArDPz7dMYJqLDzEfWqhOUgWkZGiGpPYIDbhdWxiyFcCQIDCAEA2lXmhpg9nEkKjlJHTnM1cViqL1cigglvDeCYrY6o7QMCBQkBAKnQPh7svagfzB1RzqYVVMp1JDB07MrrM+VhgKks76wKAgEJAQA5QqU3ec7H6Jxr81BUqAV1el6NLfpx9148FkLZ7Ik/AAIDCQEAk2p4uNWLPjAiQBII2cDi0TZLe18pkpgAykRNAHOWDw0CAQgBAOGKX2tkG9B3mg2Ep/c69knIVUZ3eJ46eSMcxlewivsCAgQJAQCJLA+7B9Ft7MScUENn+QjIo3yJz9j8VjjtRs1J/FEjDgICCQEAJ+NGRu0LkXSYBxwCo+4aI372eIHbck9Ed7sDpXUdwQwCBAgBACUVIQWY2m9xj2jctDO9m0DhWlTj4+bn+u7Y1PZAaJAI+VFpYN24RzKUqoG6Xj3bIdHEZ6EJtV0URCQCsZuJ0Pw=");

      final plaintext = base64Decode("TG93U2VjcmV0RmluUGxhaW50ZXh0");

      final result = CoverCrypt.decrypt(key, encrypted);

      expect(result.plaintext, equals(plaintext));

      final findexKey = base64Decode("6hb1TznoNQFvCWisGWajkA==");
      await testFunction(findexKey, "Some Label");

      print("findex and cover_crypt OK");
    });
  });
}
