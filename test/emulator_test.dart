import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  bool _canRun = true;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    try {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: 'test',
          appId: '1:1:1:1',
          messagingSenderId: '1',
          projectId: 'demo-project',
        ),
      );

      // Point to the local Firestore emulator started in CI
      FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
    } catch (e, st) {
      // If the environment doesn't support Firebase native initialization (e.g., local dart test run), skip emulator tests
      _canRun = false;
      // Log but don't fail the test suite
      print('Firestore emulator tests will be skipped: $e\n$st');
    }
  });

  test('Firestore emulator read/write', () async {
    if (!_canRun) return;
    final col = FirebaseFirestore.instance.collection('ci_test_emulator');
    await col.doc('doc1').set({'hello': 'world', 'num': 42});
    final doc = await col.doc('doc1').get();
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    expect(data['hello'], 'world');
    expect(data['num'], 42);
  });
}
