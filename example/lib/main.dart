import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:cloudproof/cloudproof.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'findex_redis_implementation.dart';

const redisHost = "192.168.1.95";
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

  late FindexMasterKeys masterKeys;
  late Uint8List userSecretKey;
  late Uint8List label;

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
      final db = await FindexRedisImplementation.db;
      final Uint8List sseKeys = Uint8List.fromList(
          await FindexRedisImplementation.get(
              db, RedisTable.others, Uint8List.fromList([0])));
      masterKeys = FindexMasterKeys.fromJson(jsonDecode(utf8.decode(sseKeys)));

      userSecretKey = Uint8List.fromList(await FindexRedisImplementation.get(
          db, RedisTable.others, Uint8List.fromList([3])));

      label = Uint8List.fromList(utf8.encode("NewLabel"));

      setState(() => loading = false);

      log("Initialized");
    } catch (e) {
      setState(() => error = "Problem during Redis initialization $e");
      log("Problem during Redis initialization $e");
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
        final indexedValues = await FindexRedisImplementation.search(
          masterKeys.k,
          label,
          [Keyword.fromString(query)],
        );

        final newSearchDuration = stopwatch.elapsed;

        if (indexedValues.isEmpty) {
          setState(() {
            results = [];
            searchDuration = null;
            decryptDuration = null;
            error = "No result";
          });
          return;
        }

        final encryptedUsersFromRedis = (await FindexRedisImplementation.mget(
          await FindexRedisImplementation.db,
          RedisTable.users,
          indexedValues.map((e) => e.location.bytes).toList(),
        ))
            // Remove `null` if some location doesn't exists inside Redis
            .whereType<List<int>>()
            .map(Uint8List.fromList)
            .toList();

        stopwatch.reset();
        final plaintextUsersBytes = encryptedUsersFromRedis.map((userBytes) {
          // Try to decrypt user information.
          try {
            return CoverCrypt.decrypt(userSecretKey, userBytes);
          } catch (e) {
            return null;
          }
        }).toList();
        final newDecryptDuration = stopwatch.elapsed;

        final plaintextUsers = plaintextUsersBytes
            .map((e) => e == null ? null : utf8.decode(e.plaintext))
            .toList();

        setState(() {
          results = plaintextUsers;
          searchDuration = newSearchDuration;
          decryptDuration = newDecryptDuration;
        });
      } catch (e, stacktrace) {
        setState(() => error = "Exception during search $e $stacktrace");
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
