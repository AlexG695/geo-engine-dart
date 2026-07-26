import 'package:hive_flutter/hive_flutter.dart';
import '../models/location_ping.dart';

class OfflineBufferManager {
  static const String _boxName = 'geo_engine_buffer_v3';
  final int maxBufferLimit;
  Box<LocationPing>? _box;

  OfflineBufferManager({this.maxBufferLimit = 10000});

  Future<void> init() async {
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(LocationPingAdapter());
    }

    if (Hive.isBoxOpen(_boxName)) {
      _box = Hive.box<LocationPing>(_boxName);
    } else {
      _box = await Hive.openBox<LocationPing>(_boxName);
    }
  }

  Future<void> enqueue(LocationPing ping) async {
    final box = _getBox();

    if (box.length >= maxBufferLimit) {
      final keysToDelete = box.keys.take(100).toList();
      await box.deleteAll(keysToDelete);
    }

    await box.add(ping);
  }

  List<LocationPing> peekBatch({int batchSize = 100}) {
    final box = _getBox();
    return box.values.take(batchSize).toList();
  }

  Future<void> removePings(int count) async {
    final box = _getBox();
    final keys = box.keys.take(count).toList();
    await box.deleteAll(keys);
  }

  int get length => _getBox().length;
  bool get isEmpty => _getBox().isEmpty;

  Box<LocationPing> _getBox() {
    if (_box == null || !_box!.isOpen) {
      throw StateError(
          'OfflineBufferManager no ha sido inicializado. Llama a init() primero.');
    }
    return _box!;
  }
}
