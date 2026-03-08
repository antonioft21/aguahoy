import 'package:just_audio/just_audio.dart';

class SoundService {
  static AudioPlayer? _player;
  static bool _ready = false;

  static Future<void> _ensureInit() async {
    if (_ready) return;
    try {
      _player = AudioPlayer();
      await _player!.setAsset('assets/sounds/water_drop.wav');
      _ready = true;
    } catch (_) {
      _player = null;
    }
  }

  static Future<void> playWaterDrop() async {
    try {
      await _ensureInit();
      if (_player == null) return;
      await _player!.seek(Duration.zero);
      await _player!.play();
    } catch (_) {}
  }

  static void dispose() {
    _player?.dispose();
    _player = null;
    _ready = false;
  }
}
