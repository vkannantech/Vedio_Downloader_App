import 'package:flutter/services.dart';
import 'package:fpdart/fpdart.dart';
import '../models/video_metadata.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';


class NativeDownloader {
  static const _channel = MethodChannel('com.kannantech.clivon/ytdl');
  static const _eventChannel = EventChannel('com.kannantech.clivon/events');

  /// Stream of download events from native side
  Stream<dynamic> get progressStream => _eventChannel.receiveBroadcastStream();

  /// Initialize the native binary (ffmpeg, python, aria2c)
  Future<Either<String, bool>> initialize() async {
    try {
      final result = await _channel.invokeMethod<bool>('initialize');
      return Right(result ?? false);
    } catch (e) {
      return Left(e.toString());
    }
  }

  /// Get shared text (if app was opened via Share Sheet)
  Future<String?> getSharedText() async {
    try {
      final text = await _channel.invokeMethod<String>('getSharedText');
      return text;
    } catch (e) {
      return null;
    }
  }

  Future<Either<String, VideoMetadata>> fetchMetadata(String url) async {
    try {
      final docs = await getApplicationDocumentsDirectory();
      final cookiesFile = File('${docs.path}/cookies.txt');
      String? cookiesPath;
      if (await cookiesFile.exists()) {
        cookiesPath = cookiesFile.path;
      }

      final jsonStr = await _channel.invokeMethod<String>('fetchMetadata', {
        'url': url, 
        'cookiesPath': cookiesPath
      });
      if (jsonStr == null) return const Left("No metadata returned");
      return Right(VideoMetadata.fromJson(jsonStr));
    } catch (e) {
      return Left(e.toString());
    }
  }

  /// Start a download for a specific URL with ID
  Future<Either<String, void>> startDownload({
    required String id,
    required String url,
    required String savePath,
    bool isAudioOnly = false,
    String? formatId,
  }) async {
    try {
      final docs = await getApplicationDocumentsDirectory();
      final cookiesFile = File('${docs.path}/cookies.txt');
      String? cookiesPath;
      if (await cookiesFile.exists()) {
        cookiesPath = cookiesFile.path;
      }

      await _channel.invokeMethod('download', {
        'id': id,
        'url': url,
        'savePath': savePath,
        'audioOnly': isAudioOnly,
        'formatId': formatId,
        'cookiesPath': cookiesPath,
      });
      return const Right(null);
    } catch (e) {
      return Left(e.toString());
    }
  }

  /// Cancel a running process
  Future<Either<String, void>> cancel(String id) async {
    try {
      await _channel.invokeMethod('cancel', {'id': id});
      return const Right(null);
    } catch (e) {
      return Left(e.toString());
    }
  }
}
