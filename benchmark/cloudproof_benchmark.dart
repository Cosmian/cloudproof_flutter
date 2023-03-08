// ignore_for_file: avoid_print

import 'dart:convert';

import 'package:cloudproof/cloudproof.dart';

final ciphertext = base64Decode(
    "nlxv3eKL702lNpGq4LsZTx4+hLhTXLmyxYQtWvQXHh9OoN7vpO1Q9/wghxpvgkfyK0Xo1FTdZt1BHFgGWjmhc0e1T6Q8+9MdniWHFNMJtdwBAOTBgZd7v7xU4shYU3tXBIPc81ptyTF2g9pozrd+N/zqIha1Q3xkEXtewwKSlTy0MnCP3xAFwhB98aKAPfqNJwSIiHFPGepVqCrqJ4ewWGpIQwk64u//6CWYTwURoGH9hDhMqAX49gtoi+oLvU/HSLX3bIP0");

final key = base64Decode(
    "xuQZX/OD65iYnM29oCqlddMmoC040QSPAe0Agocs4gf6+eQY1i5z7SVbiwHHGRi25fbbHG8gjcCaVhh6uKfDAgMAPNiWUCE5fcb98qgF+Fy+N8K+DY5wzThUTYvBD4BtgAoAPA3DzTfk3hnLSWBrquosJEBU18eHPAoGQ6qC+TZpYAUAzDOJ+JzM2MA1gRIwFKRaHD6ILLbNAXuGN7eWhAhdZAw=");

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
