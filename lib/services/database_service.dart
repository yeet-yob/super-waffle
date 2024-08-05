import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:pw_24/models/chat.dart';
import 'package:pw_24/models/message.dart';
import 'package:pw_24/models/todo.dart';
import 'package:pw_24/models/user_profile.dart';
import 'package:pw_24/services/auth_service.dart';
import 'package:pw_24/services/alert_service.dart';
import 'package:pw_24/utils.dart';

const String TODO_COLLECTON_REF = "todos";

class DatabaseService {
  final GetIt _getIt = GetIt.instance;
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;
  final _firestore = FirebaseFirestore.instance;

  late final CollectionReference _todosRef;
  late AuthService _authService;
  late AlertService _alertService;

  CollectionReference? _usersCollection;
  CollectionReference? _chatsCollection;

  DatabaseService() {
    _authService = _getIt.get<AuthService>();
    _alertService = _getIt.get<AlertService>();
    _setupCollectionReferences();
  }

  void _setupCollectionReferences() {
    _usersCollection = _firebaseFirestore.collection('users').withConverter<UserProfile>(
              fromFirestore: (snapshots, _) =>
                  UserProfile.fromJson(snapshots.data()!),
              toFirestore: (userProfile, _) => userProfile.toJson(),
            );
    _chatsCollection = _firebaseFirestore
        .collection('chats')
        .withConverter<Chat>(
            fromFirestore: (snapshots, _) => Chat.fromJson(snapshots.data()!),
            toFirestore: (chat, _) => chat.toJson());
    _todosRef = _firestore.collection(TODO_COLLECTON_REF).withConverter<Todo>(
        fromFirestore: (snapshots, _) => Todo.fromJson(
              snapshots.data()!,
            ),
        toFirestore: (todo, _) => todo.toJson());
  }

  Future<void> createUserProfile({required UserProfile userProfile}) async {
    await _usersCollection?.doc(userProfile.uid).set(userProfile);
  }

  Stream<QuerySnapshot<UserProfile>> getUserProfiles() {
    return _usersCollection
        ?.where('uid', isNotEqualTo: _authService.user!.uid)
        .snapshots() as Stream<QuerySnapshot<UserProfile>>;
  }

  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return UserProfile.fromMap(doc.data() as Map<String, dynamic>);
      }
    } catch (e) {
      print('Error getting user profile: $e');
    }
    return null;
  }

  Future<String?> findMatchForUser(String userId, String? goalType) async {
    try {
      print('Searching for match. User ID: $userId, Goal Type: $goalType');
      
      // Query for users with the same goalType who don't have a match
      QuerySnapshot matchQuery = await _firestore
          .collection('users')
          .where('goalType', isEqualTo: goalType)
          .where('match', isNull: true)
          .where(FieldPath.documentId, isNotEqualTo: userId)
          .limit(1)
          .get();

      print('Match query results: ${matchQuery.docs.length} documents');

      if (matchQuery.docs.isNotEmpty) {
        String matchedUserId = matchQuery.docs.first.id;
        print('Match found. Matched User ID: $matchedUserId');
        
        // Update both users' profiles with the match
        await _firestore.collection('users').doc(userId).update({'match': matchedUserId});
        await _firestore.collection('users').doc(matchedUserId).update({'match': userId});
        
        print('Both user profiles updated with match');
        return matchedUserId;
      } else {
        print('No match found');
      }
    } catch (e) {
      print('Error finding match: $e');
    }
    return null;
  }

  Future<bool> addFriendByUsername(String currentUserId, String username) async {
    try {
      print('Searching for user with username: $username');
      
      // Query for the user with the given username
      QuerySnapshot userQuery = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      print('User query results: ${userQuery.docs.length} documents');

      if (userQuery.docs.isEmpty) {
        print('User not found with username: $username');
        return false;
      }

      String friendId = userQuery.docs.first.id;
      print('Found user with ID: $friendId');

      // Check if they're already friends
      DocumentSnapshot currentUserDoc = await _firestore.collection('users').doc(currentUserId).get();
      List<String> friends = List<String>.from(currentUserDoc.get('friends') ?? []);

      if (friends.contains(friendId)) {
        print('Already friends with user: $friendId');
        return false;
      }

      // Add friend to current user's friends list
      friends.add(friendId);
      await _firestore.collection('users').doc(currentUserId).update({'friends': friends});
      print('Added friend to current user\'s friend list');

      // Add current user to friend's friends list
      DocumentSnapshot friendDoc = await _firestore.collection('users').doc(friendId).get();
      List<String> friendsFriends = List<String>.from(friendDoc.get('friends') ?? []);
      friendsFriends.add(currentUserId);
      await _firestore.collection('users').doc(friendId).update({'friends': friendsFriends});
      print('Added current user to friend\'s friend list');

      return true;
    } catch (e) {
      print('Error adding friend: $e');
      return false;
    }
  }

  Stream<QuerySnapshot<UserProfile>> getMatchProfiles(String userId) {
    return _usersCollection!
        .where(Filter.or(
          Filter('match', isEqualTo: userId),
          Filter('friends', arrayContains: userId)
        ))
        .snapshots() as Stream<QuerySnapshot<UserProfile>>;
  }

  Future<bool> checkChatExists(String uid1, String uid2) async {
    String chatID = generateChatID(uid1: uid1, uid2: uid2);
    final result = await _chatsCollection?.doc(chatID).get();
    if (result != null) {
      return result.exists;
    }
    return false;
  }

  Future<void> createNewChat(String uid1, String uid2) async {
    String chatID = generateChatID(uid1: uid1, uid2: uid2);
    final docRef = _chatsCollection!.doc(chatID);
    final chat = Chat(id: chatID, participants: [uid1, uid2], messages: []);
    await docRef.set(chat);
  }

  Future<void> sendChatMessage(
      String uid1, String uid2, Message message) async {
    String chatID = generateChatID(uid1: uid1, uid2: uid2);
    final docRef = _chatsCollection!.doc(chatID);
    await docRef.update(
      {
        "messages": FieldValue.arrayUnion(
          [
            message.toJson(),
          ],
        ),
      },
    );
  }

  Stream getChatData(String uid1, String uid2) {
    String chatID = generateChatID(uid1: uid1, uid2: uid2);
    return _chatsCollection?.doc(chatID).snapshots()
        as Stream<DocumentSnapshot<Chat>>;
  }

  Stream<QuerySnapshot<Todo>> getTodos() {
    String uid = _authService.user!.uid;
    return _todosRef.where('uid', isEqualTo: uid).snapshots()
        as Stream<QuerySnapshot<Todo>>;
  }

  void addTodo(Todo todo) async {
    _todosRef.add(todo);
  }

  void updateTodo(String todoId, Todo todo) {
    _todosRef.doc(todoId).update(todo.toJson());
  }

  void deleteTodo(String todoId) {
    _todosRef.doc(todoId).delete();
  }

  void updateGoal(
    String goalType,
  ) {
    _usersCollection;
  }

  Future<void> updateGoalType(String uid, String newGoalType) async {
   
      // Get the document reference for the user with the given uid
      final userDocRef = _usersCollection?.doc(uid);

      // Update the goaltype field
      await userDocRef?.update({'goalType': newGoalType});
  }


  Stream<UserProfile?> getUserProfileStream(String uid) {
    return _usersCollection!.doc(uid).snapshots().map((snapshot) {
      if (snapshot.exists) {
        return UserProfile.fromJson(snapshot.data() as Map<String, dynamic>);
      }
      return null;
    });
  }

  Future<List<Todo>> getOtherUserTodos(String userId) async {
    try {
      QuerySnapshot<Todo> todoSnapshot = await _todosRef
          .where('uid', isEqualTo: userId)
          .get() as QuerySnapshot<Todo>;
      
      return todoSnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('Error getting other user todos: $e');
      return [];
    }
  }

  Future<void> changeUsername(String uid, String newUsername) async {
    try {
      await _usersCollection?.doc(uid).update({'username': newUsername});
    } catch (e) {
      print('Error changing username: $e');
      throw Exception('Failed to change username');
    }
  }

  Future<void> changeProfilePicture(String uid, String newImageUrl) async {
    try {
      await _usersCollection?.doc(uid).update({'profileImageUrl': newImageUrl});
    } catch (e) {
      print('Error changing profile picture: $e');
      throw Exception('Failed to change profile picture');
    }
  }
}