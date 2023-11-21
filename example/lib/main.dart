import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:cloudproof/cloudproof.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'cover_crypt_helper.dart';
import 'findex_redis_implementation.dart';

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

  late FindexKey findexKey;
  late Uint8List label;
  late CoverCryptHelper coverCryptHelper;

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
    // controller.repeat(reverse: true);
    coverCryptHelper = CoverCryptHelper();
    indexDataForDemo();
    super.initState();
  }

  void indexDataForDemo() async {
    try {
      label = Uint8List.fromList(utf8.encode("NewLabel"));
      findexKey = FindexKey(Uint8List(16));
      await FindexRedisImplementation.init(coverCryptHelper, findexKey, label);
      await FindexRedisImplementation.indexAll();

      setState(() => loading = false);

      log("Initialized");
    } catch (e) {
      setState(() => error = "Problem during indexation $e");
      log("Problem during indexation $e");
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  List<Uint8List> getAllLocations(Iterable<Set<Location>> searchResult) {
    List<Uint8List> res = [];
    for (final locations in searchResult) {
      for (final loc in locations) {
        res.add(loc.bytes);
      }
    }
    return res;
  }

  void setQuery(String query) {
    log(query);

    _debouncer.run(() async {
      try {
        final stopwatch = Stopwatch()..start();
        final searchResult =
            await FindexRedisImplementation.search({Keyword.fromString(query)});

        final newSearchDuration = stopwatch.elapsed;

        if (searchResult.isEmpty) {
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
                getAllLocations(searchResult.values)))
            // Remove `null` if some location doesn't exists inside Redis
            .whereType<List<int>>()
            .map(Uint8List.fromList)
            .toList();

        stopwatch.reset();
        final plaintextUsersBytes = encryptedUsersFromRedis.map((userBytes) {
          // Try to decrypt user information.
          try {
            return CoverCrypt.decrypt(
                coverCryptHelper.userSecretKey, userBytes);
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
          error = "";
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
