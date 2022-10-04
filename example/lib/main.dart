import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:ffi';
import 'dart:typed_data';

import 'package:cloudproof/cloudproof.dart';
import 'package:flutter/material.dart';
import 'package:redis/redis.dart';

const redisHost = "192.168.1.18";
const redisPort = 6379;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cloudproof Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Cloudproof Flutter Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  bool loading = true;

  late MasterKeys masterKeys;
  late Uint8List userDecryptionKey;
  late Uint8List label;
  late CoverCryptDecryptionWithCache coverCryptDecryptionWithCache;

  String? error;

  List<String?> results = [];
  Duration? searchDuration;
  Duration? decryptDuration;

  late Debouncer _debouncer;
  late AnimationController controller;

  _MyHomePageState() {
    _debouncer = Debouncer(milliseconds: 500);
  }

  @override
  void initState() {
    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..addListener(() {
        setState(() {});
      });
    controller.repeat(reverse: true);
    fetchDemoDataFromRedis();
    super.initState();
  }

  void fetchDemoDataFromRedis() async {
    try {
      final db = await RedisFindex.db;
      final Uint8List sseKeys = Uint8List.fromList(await RedisFindex.get(
          db, RedisTable.others, Uint8List.fromList([0])));
      masterKeys = MasterKeys.fromJson(jsonDecode(utf8.decode(sseKeys)));

      userDecryptionKey = Uint8List.fromList(await RedisFindex.get(
          db, RedisTable.others, Uint8List.fromList([3])));

      label = Uint8List.fromList(utf8.encode("label"));
      coverCryptDecryptionWithCache =
          CoverCryptDecryptionWithCache(userDecryptionKey);
      setState(() => loading = false);

      log("Inited");
    } catch (e) {
      error = "Problem during Redis initialisation $e";
      log("Problem during Redis initialisation $e");
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void setQuery(String query) {
    log(query);

    _debouncer.run(() async {
      try {
        final stopwatch = Stopwatch()..start();
        final indexedValues = await RedisFindex.search(
          masterKeys.k,
          label,
          [Word.fromString(query)],
        );

        final newSearchDuration = stopwatch.elapsed;

        if (indexedValues.isEmpty) {
          setState(() {
            results = [];
            searchDuration = null;
            decryptDuration = null;
          });
          return;
        }

        final encryptedUsersFromRedis = (await RedisFindex.mget(
          await RedisFindex.db,
          RedisTable.users,
          indexedValues.map((e) => e.location.bytes).toList(),
        ))
            // Remove `null` if some location doesn't exists inside Redis
            .whereType<List<int>>()
            .map(Uint8List.fromList)
            .toList();

        stopwatch.reset();
        final clearTextUsersBytes = encryptedUsersFromRedis.map((userBytes) {
          // Try to decrypt user information.
          try {
            return coverCryptDecryptionWithCache.decrypt(userBytes);
          } catch (e) {
            return null;
          }
        }).toList();
        final newDecryptDuration = stopwatch.elapsed;

        final clearTextUsers = clearTextUsersBytes
            .map((e) => e == null ? null : utf8.decode(e))
            .toList();

        setState(() {
          results = clearTextUsers;
          searchDuration = newSearchDuration;
          decryptDuration = newDecryptDuration;
        });
      } catch (e, stacktrace) {
        error = "Exception during search $e $stacktrace";
        log("Exception during search $e $stacktrace");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug painting" (press "p" in the console, choose the
          // "Toggle Debug Paint" action from the Flutter Inspector in Android
          // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
          // to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (loading)
              CircularProgressIndicator(
                value: controller.value,
                semanticsLabel: 'Circular progress indicator',
              ),
            if (!loading)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                child: TextField(
                  onChanged: (text) {
                    setQuery(text);
                  },
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Enter a search term',
                  ),
                ),
              ),
            if (error != null) Text(error as String),
            if (!loading && searchDuration != null && decryptDuration != null)
              Text(
                  "${results.length} results. Search took ${searchDuration!.inMilliseconds}ms. Decrypt took ${decryptDuration!.inMilliseconds}ms"),
            if (!loading)
              Expanded(
                  child: ListView.separated(
                padding: const EdgeInsets.all(8),
                separatorBuilder: (context, index) => const Divider(
                  color: Colors.black,
                ),
                itemCount: results.length,
                itemBuilder: (context, index) {
                  return Text(results[index] ??
                      "Impossible to decrypt this data with current permissions");
                },
              ))
          ],
        ),
      ),
    );
  }
}

class Debouncer {
  final int milliseconds;
  Timer? _timer;

  Debouncer({required this.milliseconds});

  run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }
}

class RedisFindex {
  static Future<Command> get db async {
    final conn = RedisConnection();
    return await conn.connect(redisHost, redisPort);
  }

  static Future<dynamic> execute(Command db, List<dynamic> params) async {
    Command binaryCommand = Command.from(db).setParser(RedisParserBulkBinary());
    return await binaryCommand.send_object(params);
  }

  static Uint8List key(RedisTable table, Uint8List key) {
    return Uint8List.fromList(const Utf8Encoder().convert("cosmian") +
        Uint8List.fromList([0, 0, 0, table.number] + key));
  }

  static Future<void> del(Command db, Uint8List keyWithPrefix) async {
    await execute(db, ["DEL", RedisBulk(keyWithPrefix)]);
  }

  static Future<dynamic> get(
      Command db, RedisTable table, Uint8List key) async {
    return await getWithoutPrefix(db, RedisFindex.key(table, key));
  }

  static Future<List<dynamic>> mget(
      Command db, RedisTable table, List<Uint8List> keys) async {
    return await mgetWithoutPrefix(
        db, keys.map((key) => RedisFindex.key(table, key)).toList());
  }

  static Future<dynamic> getWithoutPrefix(
      Command db, Uint8List keyWithPrefix) async {
    return await execute(db, ["GET", RedisBulk(keyWithPrefix)]);
  }

  static Future<List<dynamic>> mgetWithoutPrefix(
      Command db, List<Uint8List> keysWithPrefix) async {
    return await execute(
        db, ["MGET", ...keysWithPrefix.map((key) => RedisBulk(key))]);
  }

  static Future<void> set(
      Command db, RedisTable table, Uint8List key, Uint8List value) async {
    await execute(
        db, ["SET", RedisBulk(RedisFindex.key(table, key)), RedisBulk(value)]);
  }

  static Future<void> mset(
      Command db, RedisTable table, Map<Uint8List, Uint8List> entries) async {
    await execute(db, [
      "MSET",
      ...entries.entries.expand(
          (entry) => [RedisBulk(key(table, entry.key)), RedisBulk(entry.value)])
    ]);
  }

  static Future<List<Uint8List>> keys(RedisTable table) async {
    return (await execute(await db, [
      "KEYS",
      RedisBulk(key(table, Uint8List(0)) + utf8.encode("*"))
    ]) as List)
        .map((e) => Uint8List.fromList(e))
        .toList();
  }

  static Future<Map<Uint8List, Uint8List>> fetchEntriesOrChains(
      RedisTable table, List<Uint8List> uids) async {
    final db = await RedisFindex.db;

    Map<Uint8List, Uint8List> results = {};

    final values = await mget(db, table, uids);

    for (final entry in uids.asMap().entries) {
      final value = values[entry.key];

      if (value != null) {
        if (value is! List<int>) {
          throw Exception("Should only store bytes in Redis for $table");
        }
        results[entry.value] = Uint8List.fromList(value);
      }
    }

    return results;
  }

  static Future<Map<Uint8List, Uint8List>> fetchEntries(
      List<Uint8List> uids) async {
    return await fetchEntriesOrChains(RedisTable.entries, uids);
  }

  static Future<Map<Uint8List, Uint8List>> fetchChains(
      List<Uint8List> uids) async {
    return await fetchEntriesOrChains(RedisTable.chains, uids);
  }

  static Future<void> upsertEntries(Map<Uint8List, Uint8List> entries) async {
    await mset(await db, RedisTable.entries, entries);
  }

  static Future<void> upsertChains(Map<Uint8List, Uint8List> chains) async {
    await mset(await db, RedisTable.chains, chains);
  }

  // ---------------------
  // Auto-Generated stuff.
  // ---------------------

  static Future<List<IndexedValue>> search(
    Uint8List keyK,
    Uint8List label,
    List<Word> words,
  ) async {
    return await Findex.search(
      keyK,
      label,
      words,
      Pointer.fromFunction(
          fetchEntriesCallback, errorCodeInCaseOfCallbackException),
      Pointer.fromFunction(
          fetchChainsCallback, errorCodeInCaseOfCallbackException),
    );
  }

  static Future<void> upsert(
    MasterKeys masterKeys,
    Uint8List label,
    Map<IndexedValue, List<Word>> indexedValuesAndWords,
  ) async {
    await Findex.upsert(
      masterKeys,
      label,
      indexedValuesAndWords,
      Pointer.fromFunction(
          fetchEntriesCallback, errorCodeInCaseOfCallbackException),
      Pointer.fromFunction(
          upsertEntriesCallback, errorCodeInCaseOfCallbackException),
      Pointer.fromFunction(
          upsertChainsCallback, errorCodeInCaseOfCallbackException),
    );
  }

  static int fetchEntriesCallback(
    Pointer<Uint8> outputPointer,
    Pointer<Uint32> outputLength,
    Pointer<Uint8> entriesUidsListPointer,
    int entriesUidsListLength,
  ) {
    return Findex.fetchWrapper(
        outputPointer,
        outputLength,
        entriesUidsListPointer,
        entriesUidsListLength,
        RedisFindex.fetchEntries);
  }

  static int fetchChainsCallback(
    Pointer<Uint8> outputPointer,
    Pointer<Uint32> outputLength,
    Pointer<Uint8> chainsUidsListPointer,
    int chainsUidsListLength,
  ) {
    return Findex.fetchWrapper(outputPointer, outputLength,
        chainsUidsListPointer, chainsUidsListLength, RedisFindex.fetchChains);
  }

  static int upsertEntriesCallback(
    Pointer<Uint8> entriesListPointer,
    int entriesListLength,
  ) {
    return Findex.upsertWrapper(
        entriesListPointer, entriesListLength, RedisFindex.upsertEntries);
  }

  static int upsertChainsCallback(
    Pointer<Uint8> chainsListPointer,
    int chainsListLength,
  ) {
    return Findex.upsertWrapper(
        chainsListPointer, chainsListLength, RedisFindex.upsertChains);
  }
}

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

  List<Word> get indexedWords {
    return [
      Word.fromString(firstName),
      Word.fromString(lastName),
      Word.fromString(phone),
      Word.fromString(email),
      Word.fromString(country),
      Word.fromString(region),
      Word.fromString(employeeNumber),
      Word.fromString(security)
    ];
  }
}

enum RedisTable {
  entries,
  chains,
  users,
  others,
}

extension RedisTableExtension on RedisTable {
  int get number {
    switch (this) {
      case RedisTable.entries:
        return 1;
      case RedisTable.chains:
        return 2;
      case RedisTable.users:
        return 3;
      case RedisTable.others:
        return 4;
      default:
        throw Exception("Unknown RedisTable $this");
    }
  }
}
