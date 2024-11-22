import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as path;
import 'package:video_player/video_player.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_archive/flutter_archive.dart';

class SplashScreen extends StatefulWidget {
  static const routeName = '/splash';
  const SplashScreen({Key? key}) : super(key: key);

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> {
  // video controller
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();

    _controller = VideoPlayerController.asset(
      'media/splash.mp4',
    )
      ..initialize().then((_) {
        setState(() {});
      })
      ..setVolume(0.0);

    _initAppData();
  }

  Future<bool> _unZip(String bundlePath, Directory destDir) async {
    try {
      await destDir.create(recursive: true);
    } catch (_) {}

    ByteData data = await rootBundle.load(bundlePath);
    final zipFile = File(path.join(
        (await getTemporaryDirectory()).path, bundlePath.split('/').last));
    await zipFile.writeAsBytes(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        flush: true);

    try {
      await ZipFile.extractToDirectory(
        zipFile: zipFile,
        destinationDir: destDir,
      );
    } catch (_) {
      return false;
    }
    zipFile.deleteSync();
    return true;
  }

  void _initAppData() async {
    var databasesPath = await getDatabasesPath();
    var dbPath = path.join(databasesPath, "arujisho.db");
    var exists = await databaseExists(dbPath);

    if (!exists) {
      _controller.play();
      var f = Future.delayed(const Duration(seconds: 8));
      await _unZip("sudachi.rs/resources/sudachidict.zip",
          await getApplicationSupportDirectory());
      await _unZip("db/arujisho.db.zip", Directory(path.dirname(dbPath)));
      await f;
    }

    if (!mounted) return;
    context.go('/');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: _controller.value.isInitialized
            ? AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(
                  _controller,
                ),
              )
            : Container(),
      ),
    );
  }
}
