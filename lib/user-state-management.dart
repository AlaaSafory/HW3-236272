import 'dart:io';

import 'package:english_words/english_words.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart' as firebase_core;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

enum Status { Uninitialized, Authenticated, Authenticating, Unauthenticated }

class AuthorizedUserNotifier extends ChangeNotifier {
  final FirebaseAuth _auth;
  Status _status = Status.Uninitialized;
  User? _user;
  FirebaseStorage _fireBaseStorage = FirebaseStorage.instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  CollectionReference _users = FirebaseFirestore.instance.collection('Users');
  Set<WordPair>? _savedlist = {};

  AuthorizedUserNotifier.instance() : _auth= FirebaseAuth.instance{
    _auth.authStateChanges().listen(_onAuthStateChanged);
    _user = _auth.currentUser;
    _onAuthStateChanged(_user);
  }

  Set<WordPair>? getCurrentList() {
    return _savedlist;
  }

  Future<Set<WordPair>?> getSavedList() async {
    if (_status == Status.Authenticated) {
      Set<WordPair> savedFavorites = <WordPair>{};
      String first, second;
      await _firestore.collection('Users')
          .doc(_user!.uid)
          .collection('Saved List')
          .get()
          .then((querySnapshot) {
        for (var result in querySnapshot.docs) {
          first = result
              .data()
              .entries
              .first
              .value
              .toString();
          second = result
              .data()
              .entries
              .last
              .value
              .toString();
          savedFavorites.add(WordPair(first, second));
        }
      });
      return Future<Set<WordPair>>.value(savedFavorites);
    }
  }



  bool get isAuthenticated => _status == Status.Authenticated;

  bool get isAuthenticating => _status == Status.Authenticating;


  Future<UserCredential?> signUp(String email, String password) async {
    try {
      _status = Status.Authenticating;
      notifyListeners();
      return await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password
      );
    }
    catch (e) {
      _status = Status.Unauthenticated;
      notifyListeners();
      return null;
    }
  }

  String? userEmail() {
    return _user!.email;
  }

  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      _user = null;
      _status = Status.Unauthenticated;
    }
    else {
      _user = firebaseUser;
      _status = Status.Authenticated;
    }
    notifyListeners();
  }

  Future signOut() async {
    _auth.signOut();
    _status = Status.Unauthenticated;
    notifyListeners();
    return Future.delayed(Duration.zero);
  }

  Future<bool> signIn(String email, String password) async {
    try {
      _status = Status.Authenticating;
      notifyListeners();
      await _auth.signInWithEmailAndPassword(
          email: email,
          password: password
      );
      _savedlist = await getSavedList();
      notifyListeners();

      return true;
    }
    catch (e) {
      _status = Status.Unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<void> updateSavedList(WordPair pair, bool add) async {
    if (add) {
      if (_status == Status.Authenticated) {
        await _firestore.collection('Users').doc(_user!.uid)
            .collection('Saved List')
            .doc(pair.toString())
            .set({'first': pair.first, 'second': pair.second});
        _savedlist = await getSavedList();
        notifyListeners();
      }
    }
    else {
      if (_status == Status.Authenticated) {
        await _firestore.collection('Users')
            .doc(_user!.uid)
            .collection('Saved List')
            .doc(pair.toString()).delete();
        _savedlist = await getSavedList();
        notifyListeners();
      }
    }
  }
  Future<void> uploadPFP(
      String pfpPath,
     /* String pfpName,*/
      )
  async {
    File file =File(pfpPath);
    try {
      await _fireBaseStorage.ref('PFP').child(_user!.uid).putFile(file);
      notifyListeners();
    } on firebase_core.FirebaseException
    catch (e)
    {}


  }
  Future<String> userPFP () async{
    String downloadURL = await _fireBaseStorage.ref('PFP').child(_user!.uid).getDownloadURL();
    return downloadURL;
  }

}
// Future<void> addUser( Set<WordPair> saved)  {
// return _users.add({'Saved_favorites': saved.map((wordPair)=>wordPair.asPascalCase).toList(),});

// await _firestore.collection('users').doc(_user?.uid).set({
//   'uid': _user?.uid,
//  'email':_email,
//   'savedList': saved.map((wp) => wp.asPascalCase).toList(),
//   'created_at': Timestamp.now(),
//     });
//}


//
// Future<void> deleteUser(String userId) {
//   return _firestore
//       .collection('users')
//       .doc(userId)
//       .delete();
// }