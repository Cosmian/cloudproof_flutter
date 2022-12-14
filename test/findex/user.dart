import 'dart:typed_data';

import 'package:cloudproof/cloudproof.dart';

class User {
  final int id;
  final String firstName;
  final String lastName;
  final String phone;
  final String email;
  final String country;
  final String region;
  final String employeeNumber;
  final String security;

  User(this.id, this.firstName, this.lastName, this.phone, this.email,
      this.country, this.region, this.employeeNumber, this.security);

  factory User.fromMap(Map<String, dynamic> json) {
    return User(
      json['id'],
      json['firstName'],
      json['lastName'],
      json['phone'],
      json['email'],
      json['country'],
      json['region'],
      json['employeeNumber'],
      json['security'],
    );
  }

  Location get location {
    return Location(Uint8List.fromList([id]));
  }

  List<Keyword> get indexedWords {
    return [
      Keyword.fromString(firstName),
      Keyword.fromString(lastName),
      Keyword.fromString(phone),
      Keyword.fromString(email),
      Keyword.fromString(country),
      Keyword.fromString(region),
      Keyword.fromString(employeeNumber),
      Keyword.fromString(security)
    ];
  }
}
