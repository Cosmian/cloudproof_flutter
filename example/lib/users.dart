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

  @override
  String toString() {
    return "$firstName $lastName $phone $email $country $employeeNumber $security";
  }

  Location get location {
    return Location(Uint8List.fromList([id]));
  }

  Set<Keyword> get indexedWords {
    return {
      Keyword.fromString(firstName),
      Keyword.fromString(lastName),
      Keyword.fromString(phone),
      Keyword.fromString(email),
      Keyword.fromString(country),
      Keyword.fromString(region),
      Keyword.fromString(employeeNumber),
      Keyword.fromString(security)
    };
  }
}

class Users {
  static final rawUsers = [
    {
      "id": 0,
      "firstName": "Felix",
      "lastName": "Shepherd",
      "phone": "06 52 23 63 25",
      "email": "orci@icloud.org",
      "country": "Germany",
      "region": "Upper Austria",
      "employeeNumber": "SPN82TTO0PP",
      "security": "confidential"
    },
    {
      "id": 1,
      "firstName": "Emerson",
      "lastName": "Wilkins",
      "phone": "01 01 31 41 37",
      "email": "enim.diam@icloud.edu",
      "country": "Spain",
      "region": "Antofagasta",
      "employeeNumber": "BYE60HQT6XG",
      "security": "confidential"
    },
    {
      "id": 2,
      "firstName": "Ocean",
      "lastName": "Meyers",
      "phone": "07 45 55 66 55",
      "email": "ultrices.vivamus@aol.net",
      "country": "Spain",
      "region": "Podlaskie",
      "employeeNumber": "SXK82FCR9EP",
      "security": "confidential"
    },
    {
      "id": 3,
      "firstName": "Kiara",
      "lastName": "Harper",
      "phone": "07 17 88 69 58",
      "email": "vitae@outlook.com",
      "country": "Germany",
      "region": "Rajasthan",
      "employeeNumber": "CWN36QTX2BN",
      "security": "secret"
    },
    {
      "id": 4,
      "firstName": "Joelle",
      "lastName": "Becker",
      "phone": "01 11 46 84 14",
      "email": "felis.adipiscing@hotmail.org",
      "country": "France",
      "region": "İzmir",
      "employeeNumber": "AFR04EPJ1YM",
      "security": "secret"
    },
    {
      "id": 5,
      "firstName": "Stacy",
      "lastName": "Reyes",
      "phone": "03 53 66 40 67",
      "email": "risus.a@yahoo.ca",
      "country": "France",
      "region": "Nord-Pas-de-Calais",
      "employeeNumber": "ZVW02EAM3ZC",
      "security": "secret"
    },
    {
      "id": 6,
      "firstName": "Donna",
      "lastName": "Velazquez",
      "phone": "01 69 11 40 51",
      "email": "mus.donec@aol.couk",
      "country": "Germany",
      "region": "Tuyên Quang",
      "employeeNumber": "DOP17EIM7ST",
      "security": "top_secret"
    },
    {
      "id": 7,
      "firstName": "Wylie",
      "lastName": "Snider",
      "phone": "07 36 72 54 66",
      "email": "fringilla.mi@google.com",
      "country": "France",
      "region": "Kansas",
      "employeeNumber": "RYS34KBD5VW",
      "security": "top_secret"
    },
    {
      "id": 8,
      "firstName": "Brielle",
      "lastName": "Finley",
      "phone": "02 75 95 77 31",
      "email": "egestas.aliquam@hotmail.edu",
      "country": "France",
      "region": "Ulyanovsk Oblast",
      "employeeNumber": "MFU36KUO6UD",
      "security": "top_secret"
    },
    {
      "id": 9,
      "firstName": "Bryar",
      "lastName": "Christian",
      "phone": "02 44 54 20 55",
      "email": "ullamcorper.eu.euismod@google.ca",
      "country": "Germany",
      "region": "Hatay",
      "employeeNumber": "TRK72WOV9VH",
      "security": "confidential"
    },
    {
      "id": 10,
      "firstName": "Diana",
      "lastName": "Wilson",
      "phone": "03 35 75 32 28",
      "email": "nascetur.ridiculus.mus@outlook.net",
      "country": "Germany",
      "region": "Ulster",
      "employeeNumber": "UPS23SOZ6QN",
      "security": "confidential"
    },
    {
      "id": 11,
      "firstName": "Paul",
      "lastName": "Ford",
      "phone": "05 13 27 74 63",
      "email": "pede.suspendisse@icloud.com",
      "country": "Germany",
      "region": "Rio Grande do Sul",
      "employeeNumber": "CWT54TJX4RT",
      "security": "confidential"
    },
    {
      "id": 12,
      "firstName": "Felicia",
      "lastName": "Massey",
      "phone": "06 72 81 43 63",
      "email": "lacus.varius.et@yahoo.ca",
      "country": "Germany",
      "region": "Brecknockshire",
      "employeeNumber": "BAC58KIS7DY",
      "security": "secret"
    },
    {
      "id": 13,
      "firstName": "Barclay",
      "lastName": "Allison",
      "phone": "08 71 12 69 37",
      "email": "in.cursus@aol.com",
      "country": "Germany",
      "region": "Caquetá",
      "employeeNumber": "KLL08RGK2JW",
      "security": "secret"
    },
    {
      "id": 14,
      "firstName": "Skyler",
      "lastName": "Richmond",
      "phone": "Figueroa",
      "email": "elit@google.net",
      "country": "France",
      "region": "Chiapas",
      "employeeNumber": "ITO71LVO4PD",
      "security": "secret"
    },
    {
      "id": 15,
      "firstName": "Justin",
      "lastName": "Cross",
      "phone": "07 56 26 00 16",
      "email": "neque.vitae@yahoo.edu",
      "country": "Germany",
      "region": "Friuli-Venezia Giulia",
      "employeeNumber": "HHH01MIH6SZ",
      "security": "top_secret"
    },
    {
      "id": 16,
      "firstName": "Miranda",
      "lastName": "Cotton",
      "phone": "06 73 42 44 47",
      "email": "eget.magna@google.ca",
      "country": "Spain",
      "region": "Møre og Romsdal",
      "employeeNumber": "DFW37PPI8TY",
      "security": "top_secret"
    },
    {
      "id": 17,
      "firstName": "Figueroa",
      "lastName": "Kane",
      "phone": "02 44 08 45 32",
      "email": "aenean.eget@protonmail.ca",
      "country": "France",
      "region": "Kansas",
      "employeeNumber": "HFG82IKJ2OC",
      "security": "top_secret"
    },
    {
      "id": 18,
      "firstName": "Lesley",
      "lastName": "Sullivan",
      "phone": "02 24 15 21 81",
      "email": "orci.ut@protonmail.couk",
      "country": "Spain",
      "region": "Lubelskie",
      "employeeNumber": "WOA67IVR6CM",
      "security": "confidential"
    },
    {
      "id": 19,
      "firstName": "Clio",
      "lastName": "Figueroa",
      "phone": "06 87 82 58 97",
      "email": "tellus@yahoo.org",
      "country": "France",
      "region": "Munster",
      "employeeNumber": "ASS31LNB5CV",
      "security": "confidential"
    },
    {
      "id": 20,
      "firstName": "Forrest",
      "lastName": "Parsons",
      "phone": "06 81 51 26 17",
      "email": "iaculis.quis@yahoo.com",
      "country": "France",
      "region": "Hải Phòng",
      "employeeNumber": "MJS53TBZ8UL",
      "security": "confidential"
    },
    {
      "id": 21,
      "firstName": "Maxwell",
      "lastName": "Park",
      "phone": "01 37 79 08 31",
      "email": "ut@yahoo.com",
      "country": "Germany",
      "region": "Guanacaste",
      "employeeNumber": "PHQ43BNF8MI",
      "security": "secret"
    },
    {
      "id": 22,
      "firstName": "Kalia",
      "lastName": "Hayden",
      "phone": "02 24 48 01 44",
      "email": "non.egestas.a@aol.ca",
      "country": "Spain",
      "region": "Gävleborgs län",
      "employeeNumber": "QUW73NPX4UG",
      "security": "secret"
    },
    {
      "id": 23,
      "firstName": "Russell",
      "lastName": "Willis",
      "phone": "07 42 02 43 15",
      "email": "sit.amet@icloud.edu",
      "country": "France",
      "region": "Bihar",
      "employeeNumber": "QOU03UHS4LQ",
      "security": "secret"
    },
    {
      "id": 24,
      "firstName": "Judah",
      "lastName": "Chang",
      "phone": "02 15 66 88 81",
      "email": "tempor.arcu@icloud.ca",
      "country": "Spain",
      "region": "Assam",
      "employeeNumber": "BJJ93AIN8LC",
      "security": "top_secret"
    },
    {
      "id": 25,
      "firstName": "Chaim",
      "lastName": "Richards",
      "phone": "08 97 39 30 70",
      "email": "nunc.sed@protonmail.com",
      "country": "Germany",
      "region": "Xīběi",
      "employeeNumber": "JTS20MCR7GX",
      "security": "top_secret"
    },
    {
      "id": 26,
      "firstName": "Zachary",
      "lastName": "Porter",
      "phone": "02 02 52 43 30",
      "email": "suscipit.nonummy.fusce@hotmail.couk",
      "country": "Germany",
      "region": "Kaduna",
      "employeeNumber": "NLN76SBS2EI",
      "security": "top_secret"
    },
    {
      "id": 27,
      "firstName": "Cade",
      "lastName": "Gould",
      "phone": "09 82 18 22 16",
      "email": "neque.vitae@google.org",
      "country": "Germany",
      "region": "Luik",
      "employeeNumber": "RSW01YCJ6HJ",
      "security": "confidential"
    },
    {
      "id": 28,
      "firstName": "Hiram",
      "lastName": "Gates",
      "phone": "02 46 85 81 87",
      "email": "tristique.senectus@outlook.net",
      "country": "Spain",
      "region": "Niger",
      "employeeNumber": "EGG84NJY5TH",
      "security": "confidential"
    },
    {
      "id": 29,
      "firstName": "Deirdre",
      "lastName": "Tate",
      "phone": "02 99 26 61 08",
      "email": "laoreet.ipsum@hotmail.com",
      "country": "Spain",
      "region": "Anambra",
      "employeeNumber": "SLO36EYL1LQ",
      "security": "confidential"
    },
    {
      "id": 30,
      "firstName": "Len",
      "lastName": "Carlson",
      "phone": "05 69 55 17 78",
      "email": "non@aol.ca",
      "country": "Germany",
      "region": "Western Visayas",
      "employeeNumber": "DHS57TIH5JX",
      "security": "secret"
    },
    {
      "id": 31,
      "firstName": "Griffin",
      "lastName": "Porter",
      "phone": "03 44 78 02 98",
      "email": "volutpat.nulla@protonmail.org",
      "country": "Germany",
      "region": "Rheinland-Pfalz",
      "employeeNumber": "JTQ18TFU5XL",
      "security": "secret"
    },
    {
      "id": 32,
      "firstName": "Caleb",
      "lastName": "Sellers",
      "phone": "08 43 33 76 76",
      "email": "ipsum.dolor@aol.net",
      "country": "Spain",
      "region": "Lanarkshire",
      "employeeNumber": "DJE23GBD4HV",
      "security": "secret"
    },
    {
      "id": 33,
      "firstName": "Wang",
      "lastName": "Chan",
      "phone": "07 13 38 17 82",
      "email": "venenatis.vel@outlook.net",
      "country": "Spain",
      "region": "Tripura",
      "employeeNumber": "VYY77VOW0QR",
      "security": "top_secret"
    },
    {
      "id": 34,
      "firstName": "Kalia",
      "lastName": "Douglas",
      "phone": "03 56 82 77 04",
      "email": "mus.proin@hotmail.net",
      "country": "France",
      "region": "Tripura",
      "employeeNumber": "AHM27UPN3HD",
      "security": "top_secret"
    },
    {
      "id": 35,
      "firstName": "Ivy",
      "lastName": "Wong",
      "phone": "04 95 11 83 54",
      "email": "sit.amet.lorem@google.org",
      "country": "Germany",
      "region": "Kahramanmaraş",
      "employeeNumber": "YCE84QZN1AU",
      "security": "top_secret"
    },
    {
      "id": 36,
      "firstName": "Brendan",
      "lastName": "Rivers",
      "phone": "02 24 31 11 26",
      "email": "nonummy.ut@aol.couk",
      "country": "Germany",
      "region": "Free State",
      "employeeNumber": "RVY06JHG6DN",
      "security": "confidential"
    },
    {
      "id": 37,
      "firstName": "Jane",
      "lastName": "Mckay",
      "phone": "01 48 61 56 13",
      "email": "vestibulum@protonmail.couk",
      "country": "France",
      "region": "Newfoundland and Labrador",
      "employeeNumber": "CEL23TSP8QV",
      "security": "confidential"
    },
    {
      "id": 38,
      "firstName": "Leroy",
      "lastName": "Cole",
      "phone": "06 78 56 75 66",
      "email": "integer.eu@aol.edu",
      "country": "Germany",
      "region": "Bengkulu",
      "employeeNumber": "SCI84CBR1UF",
      "security": "confidential"
    },
    {
      "id": 39,
      "firstName": "Axel",
      "lastName": "Buckley",
      "phone": "09 61 37 41 27",
      "email": "dignissim.maecenas@aol.com",
      "country": "Germany",
      "region": "Luik",
      "employeeNumber": "JWL04CDN7BL",
      "security": "secret"
    },
    {
      "id": 40,
      "firstName": "Martin",
      "lastName": "Stuart",
      "phone": "09 80 48 88 65",
      "email": "feugiat.non@icloud.com",
      "country": "Germany",
      "region": "Queensland",
      "employeeNumber": "LVT07UPM5YB",
      "security": "secret"
    },
    {
      "id": 41,
      "firstName": "Jerry",
      "lastName": "Gonzales",
      "phone": "07 24 80 13 06",
      "email": "convallis.convallis@aol.org",
      "country": "Spain",
      "region": "São Paulo",
      "employeeNumber": "RBU57EWQ8MI",
      "security": "secret"
    },
    {
      "id": 42,
      "firstName": "Pandora",
      "lastName": "Robinson",
      "phone": "05 92 75 54 58",
      "email": "libero.mauris@yahoo.couk",
      "country": "Spain",
      "region": "Meghalaya",
      "employeeNumber": "GFM62DCY6SQ",
      "security": "top_secret"
    },
    {
      "id": 43,
      "firstName": "Xander",
      "lastName": "Douglas",
      "phone": "08 22 77 36 03",
      "email": "arcu.sed@protonmail.couk",
      "country": "France",
      "region": "Felix",
      "employeeNumber": "DIY45MVM4TV",
      "security": "top_secret"
    },
    {
      "id": 44,
      "firstName": "Tyler",
      "lastName": "Webb",
      "phone": "07 71 71 93 44",
      "email": "pede.praesent@outlook.edu",
      "country": "Germany",
      "region": "Northern Mindanao",
      "employeeNumber": "XWN45SZY1HB",
      "security": "top_secret"
    },
    {
      "id": 45,
      "firstName": "Martena",
      "lastName": "Lynn",
      "phone": "06 88 58 74 37",
      "email": "magnis.dis@outlook.com",
      "country": "Germany",
      "region": "Zhōngnán",
      "employeeNumber": "MYO35XFT4CC",
      "security": "confidential"
    },
    {
      "id": 46,
      "firstName": "Clinton",
      "lastName": "Bradshaw",
      "phone": "08 42 86 17 33",
      "email": "venenatis.lacus.etiam@google.net",
      "country": "France",
      "region": "North West",
      "employeeNumber": "MIK59YOF7GO",
      "security": "confidential"
    },
    {
      "id": 47,
      "firstName": "Giacomo",
      "lastName": "House",
      "phone": "08 84 84 60 44",
      "email": "risus@hotmail.org",
      "country": "Germany",
      "region": "FATA",
      "employeeNumber": "OCQ75JAR6BE",
      "security": "confidential"
    },
    {
      "id": 48,
      "firstName": "Molly",
      "lastName": "Whitehead",
      "phone": "06 61 67 75 61",
      "email": "interdum.nunc.sollicitudin@yahoo.couk",
      "country": "France",
      "region": "South Island",
      "employeeNumber": "NIS84SJD6FR",
      "security": "secret"
    },
    {
      "id": 49,
      "firstName": "Luke",
      "lastName": "Reed",
      "phone": "08 73 28 17 78",
      "email": "molestie@protonmail.org",
      "country": "Spain",
      "region": "Central Region",
      "employeeNumber": "KAY46LAI4JN",
      "security": "secret"
    },
    {
      "id": 50,
      "firstName": "Mason",
      "lastName": "Snider",
      "phone": "02 57 65 38 41",
      "email": "nulla.semper@protonmail.ca",
      "country": "Spain",
      "region": "Ilocos Region",
      "employeeNumber": "YOC20OKT9UN",
      "security": "secret"
    },
    {
      "id": 51,
      "firstName": "Dieter",
      "lastName": "Bright",
      "phone": "04 74 61 75 34",
      "email": "in.molestie@hotmail.ca",
      "country": "Spain",
      "region": "Cajamarca",
      "employeeNumber": "IJI23SQF8YO",
      "security": "top_secret"
    },
    {
      "id": 52,
      "firstName": "Tashya",
      "lastName": "Vazquez",
      "phone": "07 98 70 76 64",
      "email": "ultricies@yahoo.edu",
      "country": "Spain",
      "region": "Zhytomyr oblast",
      "employeeNumber": "DBU82FRI2YJ",
      "security": "top_secret"
    },
    {
      "id": 53,
      "firstName": "Jordan",
      "lastName": "Wilder",
      "phone": "06 50 84 72 43",
      "email": "eget.lacus@aol.ca",
      "country": "Spain",
      "region": "Central Java",
      "employeeNumber": "DGG17XWQ6UM",
      "security": "top_secret"
    },
    {
      "id": 54,
      "firstName": "Dominique",
      "lastName": "Mcfarland",
      "phone": "07 17 21 15 05",
      "email": "ac@outlook.ca",
      "country": "Germany",
      "region": "Kursk Oblast",
      "employeeNumber": "JIP69EHR6KY",
      "security": "confidential"
    },
    {
      "id": 55,
      "firstName": "Hyatt",
      "lastName": "Marks",
      "phone": "03 47 59 28 56",
      "email": "at.sem.molestie@yahoo.com",
      "country": "France",
      "region": "Picardie",
      "employeeNumber": "YVU78WCO3LK",
      "security": "confidential"
    },
    {
      "id": 56,
      "firstName": "Kasper",
      "lastName": "Brennan",
      "phone": "04 57 71 59 02",
      "email": "bibendum@google.ca",
      "country": "France",
      "region": "Rogaland",
      "employeeNumber": "THP01CAA6LJ",
      "security": "confidential"
    },
    {
      "id": 57,
      "firstName": "Summer",
      "lastName": "Crane",
      "phone": "05 35 71 18 22",
      "email": "ipsum@aol.org",
      "country": "Germany",
      "region": "North Chungcheong",
      "employeeNumber": "UJY85LZO1VG",
      "security": "secret"
    },
    {
      "id": 58,
      "firstName": "Xenos",
      "lastName": "Whitfield",
      "phone": "08 30 96 35 54",
      "email": "a.feugiat@outlook.couk",
      "country": "Spain",
      "region": "Kherson oblast",
      "employeeNumber": "NVG99IMP6JD",
      "security": "secret"
    },
    {
      "id": 59,
      "firstName": "Dale",
      "lastName": "Lane",
      "phone": "06 57 86 21 77",
      "email": "lacus@aol.com",
      "country": "Spain",
      "region": "California",
      "employeeNumber": "WOG25MBO3PC",
      "security": "secret"
    },
    {
      "id": 60,
      "firstName": "Baker",
      "lastName": "Knowles",
      "phone": "02 59 68 76 19",
      "email": "sem.ut@protonmail.edu",
      "country": "France",
      "region": "Heredia",
      "employeeNumber": "JAI31QCC1CS",
      "security": "top_secret"
    },
    {
      "id": 61,
      "firstName": "Elaine",
      "lastName": "Chase",
      "phone": "08 96 37 63 57",
      "email": "tellus.sem.mollis@icloud.ca",
      "country": "France",
      "region": "Dalarnas län",
      "employeeNumber": "TCF97SQG4US",
      "security": "top_secret"
    },
    {
      "id": 62,
      "firstName": "Sophia",
      "lastName": "Salinas",
      "phone": "04 88 58 20 33",
      "email": "arcu.sed@outlook.couk",
      "country": "Spain",
      "region": "East Java",
      "employeeNumber": "QPD64DEE4MN",
      "security": "top_secret"
    },
    {
      "id": 63,
      "firstName": "Ramona",
      "lastName": "Sampson",
      "phone": "07 66 19 62 82",
      "email": "nullam.suscipit@yahoo.ca",
      "country": "France",
      "region": "Principado de Asturias",
      "employeeNumber": "XDX32WIN7KD",
      "security": "confidential"
    },
    {
      "id": 64,
      "firstName": "Iris",
      "lastName": "Berg",
      "phone": "01 00 34 62 27",
      "email": "ante@aol.ca",
      "country": "Spain",
      "region": "Atacama",
      "employeeNumber": "JOJ64MTG8YN",
      "security": "confidential"
    },
    {
      "id": 65,
      "firstName": "Calvin",
      "lastName": "Joyner",
      "phone": "06 84 59 78 28",
      "email": "ipsum@google.couk",
      "country": "France",
      "region": "Lagos",
      "employeeNumber": "DPF55GCD6AS",
      "security": "confidential"
    },
    {
      "id": 66,
      "firstName": "Martina",
      "lastName": "Hickman",
      "phone": "02 21 24 02 39",
      "email": "erat.volutpat@protonmail.com",
      "country": "Spain",
      "region": "Catalunya",
      "employeeNumber": "YRL83GET3VE",
      "security": "secret"
    },
    {
      "id": 67,
      "firstName": "Xantha",
      "lastName": "Montgomery",
      "phone": "03 05 74 29 97",
      "email": "risus.odio@protonmail.com",
      "country": "Germany",
      "region": "Merionethshire",
      "employeeNumber": "UCQ10RTQ2SI",
      "security": "secret"
    },
    {
      "id": 68,
      "firstName": "Amy",
      "lastName": "Wright",
      "phone": "05 65 15 40 63",
      "email": "nunc.lectus@aol.com",
      "country": "France",
      "region": "Penza Oblast",
      "employeeNumber": "IPT58WWO5LX",
      "security": "secret"
    },
    {
      "id": 69,
      "firstName": "Alma",
      "lastName": "Schroeder",
      "phone": "04 23 46 16 33",
      "email": "aliquet.magna.a@protonmail.couk",
      "country": "Germany",
      "region": "East Kalimantan",
      "employeeNumber": "EMH30WSQ3MS",
      "security": "top_secret"
    },
    {
      "id": 70,
      "firstName": "Marvin",
      "lastName": "Bowen",
      "phone": "07 42 38 86 27",
      "email": "malesuada@aol.couk",
      "country": "France",
      "region": "Tasmania",
      "employeeNumber": "YUQ42QOG7XD",
      "security": "top_secret"
    },
    {
      "id": 71,
      "firstName": "Ila",
      "lastName": "Drake",
      "phone": "02 47 45 63 07",
      "email": "posuere.enim@google.edu",
      "country": "France",
      "region": "Gävleborgs län",
      "employeeNumber": "RJT61MYB8MY",
      "security": "top_secret"
    },
    {
      "id": 72,
      "firstName": "Noble",
      "lastName": "Cunningham",
      "phone": "05 19 20 79 58",
      "email": "mollis.non@yahoo.couk",
      "country": "Spain",
      "region": "Brussels Hoofdstedelijk Gewest",
      "employeeNumber": "FCF77JFT8EW",
      "security": "confidential"
    },
    {
      "id": 73,
      "firstName": "Lilah",
      "lastName": "Stewart",
      "phone": "05 56 71 95 15",
      "email": "tincidunt.orci@google.ca",
      "country": "Germany",
      "region": "South Australia",
      "employeeNumber": "HZI85ZFQ4SH",
      "security": "confidential"
    },
    {
      "id": 74,
      "firstName": "Gavin",
      "lastName": "Bailey",
      "phone": "08 25 25 31 93",
      "email": "dui.in.sodales@protonmail.net",
      "country": "Spain",
      "region": "Diyarbakır",
      "employeeNumber": "NVH67DKP6FV",
      "security": "confidential"
    },
    {
      "id": 75,
      "firstName": "Janna",
      "lastName": "Hurst",
      "phone": "04 26 15 12 98",
      "email": "consectetuer.cursus.et@google.couk",
      "country": "Spain",
      "region": "Ceuta",
      "employeeNumber": "EOR61GBW9OL",
      "security": "secret"
    },
    {
      "id": 76,
      "firstName": "Kylie",
      "lastName": "Mullen",
      "phone": "02 46 54 90 13",
      "email": "lobortis.quam@google.edu",
      "country": "Germany",
      "region": "Waals-Brabant",
      "employeeNumber": "TBS73YUW3PQ",
      "security": "secret"
    },
    {
      "id": 77,
      "firstName": "MacKensie",
      "lastName": "Atkinson",
      "phone": "08 03 38 16 24",
      "email": "integer.eu@google.org",
      "country": "France",
      "region": "Sachsen",
      "employeeNumber": "NGO64EMM1XG",
      "security": "secret"
    },
    {
      "id": 78,
      "firstName": "Jack",
      "lastName": "Armstrong",
      "phone": "07 22 43 06 14",
      "email": "varius.nam@protonmail.edu",
      "country": "Spain",
      "region": "Andaman and Nicobar Islands",
      "employeeNumber": "EEI44MCQ4MF",
      "security": "top_secret"
    },
    {
      "id": 79,
      "firstName": "Karly",
      "lastName": "Maxwell",
      "phone": "03 93 73 18 84",
      "email": "pharetra.nam@icloud.edu",
      "country": "Spain",
      "region": "Henegouwen",
      "employeeNumber": "ABY52MFR3GP",
      "security": "top_secret"
    },
    {
      "id": 80,
      "firstName": "Lucius",
      "lastName": "Baxter",
      "phone": "06 37 54 06 88",
      "email": "eu.metus@icloud.org",
      "country": "France",
      "region": "North Region",
      "employeeNumber": "UCI44NTO1YV",
      "security": "top_secret"
    },
    {
      "id": 81,
      "firstName": "Palmer",
      "lastName": "Mccall",
      "phone": "01 95 80 85 96",
      "email": "a.auctor@google.edu",
      "country": "Germany",
      "region": "Michigan",
      "employeeNumber": "QCB22NGM7VN",
      "security": "confidential"
    },
    {
      "id": 82,
      "firstName": "Reagan",
      "lastName": "Lynch",
      "phone": "04 15 43 21 21",
      "email": "donec.nibh@google.ca",
      "country": "France",
      "region": "Gävleborgs län",
      "employeeNumber": "BUD99RIH9KB",
      "security": "confidential"
    },
    {
      "id": 83,
      "firstName": "Kibo",
      "lastName": "Mcintosh",
      "phone": "08 88 35 57 43",
      "email": "aliquam@protonmail.net",
      "country": "France",
      "region": "Małopolskie",
      "employeeNumber": "VZR07UEQ2PU",
      "security": "confidential"
    },
    {
      "id": 84,
      "firstName": "Peter",
      "lastName": "Edwards",
      "phone": "01 56 71 49 15",
      "email": "cras@protonmail.edu",
      "country": "Spain",
      "region": "Chernivtsi oblast",
      "employeeNumber": "FIY93USG7LF",
      "security": "secret"
    },
    {
      "id": 85,
      "firstName": "Kato",
      "lastName": "Parsons",
      "phone": "02 15 37 96 48",
      "email": "lectus@google.com",
      "country": "France",
      "region": "Western Australia",
      "employeeNumber": "BXB16IOM1OH",
      "security": "secret"
    },
    {
      "id": 86,
      "firstName": "Suki",
      "lastName": "Newman",
      "phone": "07 25 82 47 51",
      "email": "sed.id@protonmail.ca",
      "country": "France",
      "region": "Bình Dương",
      "employeeNumber": "EFC57JHW4MT",
      "security": "secret"
    },
    {
      "id": 87,
      "firstName": "Sean",
      "lastName": "Tucker",
      "phone": "02 55 88 99 01",
      "email": "quis.arcu.vel@icloud.ca",
      "country": "Germany",
      "region": "Kahramanmaraş",
      "employeeNumber": "DPF11YBI4FX",
      "security": "top_secret"
    },
    {
      "id": 88,
      "firstName": "Eve",
      "lastName": "Collier",
      "phone": "02 38 25 54 78",
      "email": "diam.duis.mi@icloud.org",
      "country": "Germany",
      "region": "Corse",
      "employeeNumber": "EXV52JNI9ZG",
      "security": "top_secret"
    },
    {
      "id": 89,
      "firstName": "Martena",
      "lastName": "Grimes",
      "phone": "08 78 28 44 11",
      "email": "cras.eu@yahoo.edu",
      "country": "Germany",
      "region": "South Island",
      "employeeNumber": "NBX34YIH1OQ",
      "security": "top_secret"
    },
    {
      "id": 90,
      "firstName": "Eagan",
      "lastName": "Foster",
      "phone": "05 27 63 48 34",
      "email": "donec.sollicitudin@yahoo.couk",
      "country": "Germany",
      "region": "Munster",
      "employeeNumber": "DVD87LBG6UL",
      "security": "confidential"
    },
    {
      "id": 91,
      "firstName": "Eleanor",
      "lastName": "Snow",
      "phone": "05 95 41 55 09",
      "email": "et.magnis@hotmail.couk",
      "country": "Spain",
      "region": "Antofagasta",
      "employeeNumber": "JDG52IJE1FN",
      "security": "confidential"
    },
    {
      "id": 92,
      "firstName": "Shaine",
      "lastName": "Quinn",
      "phone": "06 13 89 12 11",
      "email": "sit.amet.lorem@protonmail.edu",
      "country": "Germany",
      "region": "West Region",
      "employeeNumber": "XNW76UKP0DP",
      "security": "confidential"
    },
    {
      "id": 93,
      "firstName": "Wylie",
      "lastName": "Gay",
      "phone": "08 99 13 97 15",
      "email": "adipiscing.lobortis.risus@hotmail.ca",
      "country": "Germany",
      "region": "Antofagasta",
      "employeeNumber": "OMR67KMM3QR",
      "security": "secret"
    },
    {
      "id": 94,
      "firstName": "Xenos",
      "lastName": "Olson",
      "phone": "08 26 78 84 71",
      "email": "pede.sagittis@aol.org",
      "country": "Spain",
      "region": "Paraíba",
      "employeeNumber": "EQN94VSX2IJ",
      "security": "secret"
    },
    {
      "id": 95,
      "firstName": "Beck",
      "lastName": "Gray",
      "phone": "08 72 82 86 44",
      "email": "felis.ullamcorper@google.couk",
      "country": "Germany",
      "region": "Noord Holland",
      "employeeNumber": "VCD88TYG7IX",
      "security": "secret"
    },
    {
      "id": 96,
      "firstName": "Zeus",
      "lastName": "Cherry",
      "phone": "03 37 88 63 83",
      "email": "dolor.sit@hotmail.edu",
      "country": "France",
      "region": "Munster",
      "employeeNumber": "BTZ36YSA2XP",
      "security": "top_secret"
    },
    {
      "id": 97,
      "firstName": "Aaron",
      "lastName": "Stanton",
      "phone": "09 21 34 93 29",
      "email": "magna.sed@yahoo.org",
      "country": "Germany",
      "region": "Mexico City",
      "employeeNumber": "UDB51OGB2XO",
      "security": "top_secret"
    },
    {
      "id": 98,
      "firstName": "Uriah",
      "lastName": "Foley",
      "phone": "09 39 55 67 05",
      "email": "mi.fringilla.mi@yahoo.edu",
      "country": "Germany",
      "region": "North Gyeongsang",
      "employeeNumber": "JXW87GWD3IF",
      "security": "top_secret"
    },
    {
      "id": 99,
      "firstName": "Ima",
      "lastName": "Ewing",
      "phone": "02 91 58 54 73",
      "email": "vitae@yahoo.com",
      "country": "Germany",
      "region": "National Capital Region",
      "employeeNumber": "JCO37AVA1LH",
      "security": "confidential"
    }
  ];

  static List<User> getUsers() {
    List<User> users = [];
    for (final rawUser in rawUsers) {
      final user = User.fromMap(rawUser);
      users.add(user);
    }
    return users;
  }
}
