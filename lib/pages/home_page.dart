import 'package:chat_app/components/my_drawer.dart';
import 'package:chat_app/components/user_tile.dart';
import 'package:chat_app/pages/chat_page.dart';
import 'package:chat_app/services/auth/auth_service.dart';
import 'package:chat_app/services/chat/chat_service.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // chat & auth service
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Home'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.grey,
        elevation: 0,
      ),
      drawer: const MyDrawer(),
      body: _buildUserList(),
    );
  }

  // build a list of users except for the current logged in user
  Widget _buildUserList() {
    return StreamBuilder(
      stream: _chatService.getUsersStreamExcludingBlocked(),
      builder: (context, snapshotUser) {
        return StreamBuilder(
          stream: _chatService.getChatRoomIds(),
          builder: (context, snapshotChat) {
            // error
            if (snapshotUser.hasError || snapshotChat.hasError) {
              return const Center(
                child: Text('Error'),
              );
            }

            // loading..
            if (snapshotUser.connectionState == ConnectionState.waiting ||
                snapshotChat.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            final users = snapshotUser.data ?? [];
            final chatRooms = snapshotChat.data ?? [];

            if (chatRooms.isEmpty) {
              return const Center(
                child: Text('No conversation created yet'),
              );
            }

            // return list view of users
            return ListView(
              children: users
                  .map<Widget>(
                    (userData) => _buildUserListItem(
                      userData,
                      chatRooms,
                      context,
                    ),
                  )
                  .toList(),
            );
          },
        );
      },
    );
  }

  // build individual list tile for user.
  // note: this is the implementation from tutorial. it will show all users except current user.
  /* Widget _buildUserListItem(
    Map<String, dynamic> userData,
    BuildContext context,
  ) {
    // display all users except current user
    if (userData['email'] != _authService.getCurrentUser()!.email) {
      return UserTile(
        text: userData['email'],
        onTap: () {
          Navigator.push(
            context,
            ChatPage.route(
              receiverID: userData['uid'],
              receiverEmail: userData['email'],
            ),
          );
        },
      );
    } else {
      return Container();
    }
  } */

  // build individual list tile for user.
  // note: this is the modified version. it will show all users except current user, and it only show
  // users that has a conversation.
  Widget _buildUserListItem(
    Map<String, dynamic> userData,
    List<String> chatRoomIds,
    BuildContext context,
  ) {
    final userId = userData['uid'];

    // construct a chatroom ID to check recent conversation
    List<String> ids = [_authService.getCurrentUser()!.uid, userId];
    ids.sort();
    String chatId = ids.join('_');

    // Why if function below does not follow with else?
    // Because if you put else, you want to return nothing, for example you can return a Container().
    // The problem is, when you return something, it will end the chatRoomIds loop. So it is better
    // to just use if function without the else.

    // display all users except current user and only show users that has a conversation.
    for (String chatRoomId in chatRoomIds) {
      if (userData['email'] != _authService.getCurrentUser()!.email &&
          chatRoomId.contains(chatId)) {
        return UserTile(
          text: userData['email'],
          onTap: () {
            Navigator.push(
              context,
              ChatPage.route(
                receiverID: userData['uid'],
                receiverEmail: userData['email'],
              ),
            );
          },
        );
      }
    }

    return Container();
  }
}
