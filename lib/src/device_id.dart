import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

Future<String> getOrCreateDeviceId() async {
  final prefs = await SharedPreferences.getInstance();
  final existing = prefs.getString('device_id');
  if (existing != null && existing.isNotEmpty) return existing;

  final rng = Random.secure();
  String rand() => List.generate(16, (_) => rng.nextInt(36).toRadixString(36)).join();
  final id = '${rand()}${rand()}'.substring(0, 26);
  await prefs.setString('device_id', id);
  return id;
}
