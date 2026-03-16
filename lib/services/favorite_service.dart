import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../firebase_options.dart';
import '../models/student.dart';

class FavoriteService {
  FavoriteService._();
  static final instance = FavoriteService._();

  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  /// Ensures that Firebase is initialized and the user is signed in (anonymous).
  ///
  /// This can be called from anywhere in the app to safely get an authenticated
  /// user ID even if `Firebase.initializeApp()` wasn't called earlier.
  Future<String> ensureSignedIn() async {
    // Make sure Firebase is initialized before using FirebaseAuth/Firestore.
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    }

    final user = _auth.currentUser;
    if (user != null) return user.uid;

    final cred = await _auth.signInAnonymously();
    return cred.user!.uid;
  }

  /// Returns a set of student ids that are marked as favorites for the
  /// current authenticated user.
  Future<Set<int>> loadFavorites() async {
    final uid = await ensureSignedIn();
    print('Loading favorites for user $uid');
    final snap = await _firestore.collection('users').doc(uid).collection('favorites').get();

    final favorites =
        snap.docs
            .where((doc) => doc.data().containsKey('studentId'))
            .map((doc) => (doc.data()['studentId'] as num).toInt())
            .toSet();
    print('Loaded ${favorites.length} favorites: $favorites');
    return favorites;
  }

  Future<void> setFavorite(Student student, bool isFavorite) async {
    final uid = await ensureSignedIn();
    final favRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .doc(student.id.toString());

    if (isFavorite) {
      print('Adding favorite for student ${student.id} to Firebase');
      await favRef.set({
        'studentId': student.id,
        'name': student.name,
        'age': student.age,
        'address': student.address,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('Favorite added successfully');
    } else {
      print('Removing favorite for student ${student.id} from Firebase');
      await favRef.delete();
      print('Favorite removed successfully');
    }
  }
}
