// ignore_for_file: avoid_print

import 'dart:convert';

import 'package:cloudproof/cloudproof.dart';

final ciphertext = base64Decode(
    "5j7n/1b6P+1hMehqkVDYcTIlEOBrG3t5F90FTo/YuB5QBvVhrvs1xCGiiBukyLgUyGDXs0Myown+b83DuggIXbCSKwvH8m7/wwY8gnBJD7cBAJh3xwIiFvV2tF07x0M1BLYm4fMKmJ2U3Qt94Cr/U9iGImvBrR081if/7XG1Nm3Ch6ljRHX2JpoKT3ARszYMQvjUmnLdqC4wqjX8MHpHMsHQ246qwdFY1mVjQphad9EhPrlTY8mgcLYokZ5l+2Ici3BYHWlC");

final key = base64Decode(
    "4Ff3RK2BtQGKPm9vUdTWb0Nq4m2XKSvtL9XV4bHLKQBltKPrgIcTpf5yyNVLY8gCLSeMUtP9ILXQmv0ZNZ9TCQMCAQgBAA7cLGrYnoYJ79bWRkfG8x4hqAEtxztuJARlw89YP84OAgMIAQAqFV9qTRTkTeHYIv7bjLOEe/ZiR3lC5ELOwCNo7Bj/CAICCAEAqF62dJnjUlTsHUGY7yEVW9h2gJhAL3+QTMkUNnHWOA6fGiAFVHvf9xIjQH5VWGfzE/BXaZu/+IpUEOlyszC/ZA==");

const numIteration = 10000;

void main() {
  {
    Stopwatch stopwatch = Stopwatch()..start();
    for (var i = 0; i < numIteration; i++) {
      CoverCrypt.decrypt(key, ciphertext);
    }
    print(
        'CoverCryptDecryption() executed in ${stopwatch.elapsed ~/ numIteration} (mean on $numIteration iterations)');
  }
}
