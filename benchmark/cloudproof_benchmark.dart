// ignore_for_file: avoid_print

import 'dart:convert';

import 'package:cloudproof/cloudproof.dart';

final ciphertext = base64Decode(
    "oD8q4cFGxcxHmGPC5V6efR13E47tCON2G0RQSl9YUCZuFQj541tDu8UZiABPRaiUqA8vpkLfeiZ2Cex477YNPls7IWCu32dJTU0NW/EiVLvnQMCOGBTPiB6ndkuXx7fmAQDGpTSrF/AXE5l2MXPuysmnQ/h2WCDLGlYmN1PPWR5ENiI8oclVAlS9tVOVJmJSZqShfNKW7eju2xNo3QbIxmi9jtQi44Pup4yaL8zsHBvFEYxZoZHGM7QMfJVxBZjyzwZx+Le7zClRXQMz/NDrjE0JiZA2fw==");

final key = base64Decode(
    "8G7kFEBgLPmmnMMCWnS3Ed02JW/j/gX/f4pqbvLGlAKp/Mu0m5nGmyyhmYHzTturZ6FZBn2WZS7Foi4JcbZdDAMAJwYkRk/JBRiR+Ihhy19Uua/ZjcJslGfpl4NR2bteVAYAeoc3b36LsO0gfyMB8tSven42jw/j4jiu0gEog/k/cgIA0BpZ10uVpyal9H8s6u9EDaN/O/MVBFvCjzlgugIh1wk=");

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
