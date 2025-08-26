import 'package:firebase_database/firebase_database.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final trackingEnabledProvider = StreamProvider<bool>((ref) {
  final db = FirebaseDatabase.instance.ref("settings/trackingEnabled");
  return db.onValue.map((event) {
    final value = event.snapshot.value;
    return value == true; // ensure bool
  });
});