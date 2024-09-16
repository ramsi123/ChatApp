import 'package:chat_app/models/message.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChatService extends ChangeNotifier {
  // get instance of firestore and auth
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // GET ALL USERS STREAM
  /*
  Example for the return of this function
  [
    {
      'email': test@gmail.com,
      'id': ..
    },
    {
      'email': krrblob@gmail.com,
      'id': ..
    }
  ]
  */
  Stream<List<Map<String, dynamic>>> getUsersStream() {
    // return all users
    // return _firestore.collection('Users').snapshots().map((snapshot) {
    //   return snapshot.docs.map((doc) {
    //     // go through each individual user
    //     final user = doc.data();
    //     // return user
    //     return user;
    //   }).toList();
    // });

    // return all users except himself
    return _firestore.collection('Users').snapshots().map((snapshot) {
      return snapshot.docs
          .where((doc) => doc.data()['email'] != _auth.currentUser!.email)
          .map((doc) => doc.data())
          .toList();
    });
  }

  // GET ALL CHAT ROOM IDS
  Stream<List<String>> getChatRoomIds() {
    return _firestore.collection('chat_rooms').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => doc.id).toList();
    });
  }

  // GET ALL CHAT ROOM IDS OLDER VERSION
  // This older version only return Future<List<String>>. The downside of this version is that,
  // it doesn't return as a stream, which means the home screen does not refresh the data
  // automatically. The stream return is the one that can refresh the data automatically.
  /* Future<List<String>> getChatRoomIds() async {
    final res = await _firestore.collection('chat_rooms').get();
    return res.docs.map((doc) => doc.id).toList();
  } */

  // GET ALL USERS STREAM EXCEPT BLOCKED USERS
  Stream<List<Map<String, dynamic>>> getUsersStreamExcludingBlocked() {
    final currentUser = _auth.currentUser;

    return _firestore
        .collection('Users')
        .doc(currentUser!.uid)
        .collection('BlockedUsers')
        .snapshots()
        .asyncMap((snapshot) async {
      // get blocked user ids
      final blockedchatRoomIds = snapshot.docs.map((doc) => doc.id).toList();

      // get all users
      final usersSnapshot = await _firestore.collection('Users').get();

      // return as stream list, excluding current user and blocked users
      return usersSnapshot.docs
          .where((doc) =>
              doc.data()['email'] != currentUser.email &&
              !blockedchatRoomIds.contains(doc.id))
          .map((doc) => doc.data())
          .toList();
    });
  }

  // SEND MESSAGE
  Future<void> sendMessage(String receiverID, message) async {
    // get current user info
    final String currentUserID = _auth.currentUser!.uid;
    final String currentUserEmail = _auth.currentUser!.email!;
    final Timestamp timestamp = Timestamp.now();

    // create a new message
    Message newMessage = Message(
      senderID: currentUserID,
      senderEmail: currentUserEmail,
      receiverID: receiverID,
      message: message,
      timestamp: timestamp,
    );

    // construct chat room ID for the two users (sorted to ensure uniqueness)
    List<String> ids = [currentUserID, receiverID];
    ids.sort(); // sort the ids (this ensure the chatroomID is the same for any 2 people)
    String chatRoomID = ids.join('_');

    // add members to database
    await _firestore.collection('chat_rooms').doc(chatRoomID).set(
      {
        'members': [currentUserID, receiverID],
      },
    );

    // add new message to database
    await _firestore
        .collection('chat_rooms')
        .doc(chatRoomID)
        .collection('messages')
        .add(newMessage.toMap());
  }

  // GET MESSAGES
  Stream<QuerySnapshot> getMessages(String userID, otherUserID) {
    // construct a chatroom ID for the two users
    List<String> ids = [userID, otherUserID];
    ids.sort();
    String chatRoomID = ids.join('_');

    return _firestore
        .collection('chat_rooms')
        .doc(chatRoomID)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  // REPORT USER
  Future<void> reportUser(String messageId, userId) async {
    final currentUser = _auth.currentUser;
    final report = {
      'reported by': currentUser!.uid,
      'messageId': messageId,
      'messageOwnerId': userId,
      'timestamp': FieldValue.serverTimestamp(),
    };

    await _firestore.collection('Reports').add(report);
  }

  // The tutor is using notifyListeners(). But, i tried without using it and it still work.
  // The reason for that, when returning user data in home and blocked users screen, its returning
  // as a stream. So i guess it works just fine to not use notifyListeners().
  // BLOCK USER
  Future<void> blockUser(String userId) async {
    final currentUser = _auth.currentUser;

    await _firestore
        .collection('Users')
        .doc(currentUser!.uid)
        .collection('BlockedUsers')
        .doc(userId)
        .set({});
    notifyListeners();
  }

  // UNBLOCK USER
  Future<void> unblockUser(String blockedUserId) async {
    final currentUser = _auth.currentUser;

    await _firestore
        .collection('Users')
        .doc(currentUser!.uid)
        .collection('BlockedUsers')
        .doc(blockedUserId)
        .delete();
  }

  // GET BLOCKED USERS STREAM
  Stream<List<Map<String, dynamic>>> getBlockedUsersStream(String userId) {
    return _firestore
        .collection('Users')
        .doc(userId)
        .collection('BlockedUsers')
        .snapshots()
        .asyncMap(
      (snapshot) async {
        // get list of blocked user ids
        final blockedchatRoomIds = snapshot.docs.map((doc) => doc.id).toList();

        final userDocs = await Future.wait(
          blockedchatRoomIds.map(
            (id) => _firestore.collection('Users').doc(id).get(),
          ),
        );

        // return as a list
        return userDocs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList();
      },
    );
  }
}
