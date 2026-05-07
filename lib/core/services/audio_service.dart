import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

/// Driver tald: incoming duudlaga ireh uyed loop hiidg ringtone +
/// statusiin uurchlult dur ner ner buruugaar tovshing.
/// debugPrint-ar logging hiine — `flutter run` console deer harah bolomjtoi.
class AudioService {
  final AudioPlayer _oneShot = AudioPlayer();
  final AudioPlayer _incoming = AudioPlayer();
  bool _incomingActive = false;
  bool _contextSet = false;

  Future<void> _ensureContext() async {
    if (_contextSet) return;
    _contextSet = true;
    try {
      await AudioPlayer.global.setAudioContext(
        AudioContext(
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
          ),
          android: AudioContextAndroid(
            isSpeakerphoneOn: false,
            stayAwake: false,
            contentType: AndroidContentType.music,
            usageType: AndroidUsageType.media,
            audioFocus: AndroidAudioFocus.gainTransientMayDuck,
          ),
        ),
      );
      debugPrint('[AudioService] audio context set');
    } catch (e) {
      debugPrint('[AudioService] context set failed: $e');
    }
  }

  Future<void> _playAsset(String fileName) async {
    debugPrint('[AudioService] play sounds/$fileName');
    await _ensureContext();
    try {
      await _oneShot.play(AssetSource('sounds/$fileName'));
      debugPrint('[AudioService] play OK: $fileName');
      return;
    } catch (e) {
      debugPrint('[AudioService] play FAILED $fileName: $e');
    }
    try {
      await SystemSound.play(SystemSoundType.click);
      debugPrint('[AudioService] system click fallback');
    } catch (_) {}
  }

  Future<void> _vibrate({int duration = 200}) async {
    try {
      final has = await Vibration.hasVibrator();
      if (has == true) {
        Vibration.vibrate(duration: duration);
      }
    } catch (_) {}
  }

  Future<void> _vibratePattern(List<int> pattern) async {
    try {
      final has = await Vibration.hasVibrator();
      if (has == true) {
        Vibration.vibrate(pattern: pattern, repeat: 0);
      }
    } catch (_) {}
  }

  /// Rider duudlaga ireh uyed loop togdog ringtone + repeat vibration.
  Future<void> startIncomingLoop() async {
    if (_incomingActive) return;
    _incomingActive = true;
    debugPrint('[AudioService] startIncomingLoop');
    await _ensureContext();
    try {
      await _incoming.setReleaseMode(ReleaseMode.loop);
      await _incoming.play(AssetSource('sounds/incoming.wav'));
      debugPrint('[AudioService] incoming loop OK');
    } catch (e) {
      debugPrint('[AudioService] incoming loop FAILED: $e');
      try {
        await SystemSound.play(SystemSoundType.alert);
      } catch (_) {}
    }
    await _vibratePattern([0, 600, 400, 600, 400]);
  }

  Future<void> stopIncomingLoop() async {
    _incomingActive = false;
    debugPrint('[AudioService] stopIncomingLoop');
    try {
      await _incoming.stop();
    } catch (_) {}
    try {
      Vibration.cancel();
    } catch (_) {}
  }

  Future<void> playArrived() async {
    await _vibrate(duration: 150);
    await _playAsset('arrived.wav');
  }

  Future<void> playStart() async {
    await _vibrate(duration: 150);
    await _playAsset('start.wav');
  }

  Future<void> playComplete() async {
    await _vibrate(duration: 300);
    await _playAsset('complete.wav');
  }

  Future<void> dispose() async {
    await _oneShot.dispose();
    await _incoming.dispose();
  }
}
