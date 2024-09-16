import 'package:chat_app/components/user_tile.dart';
import 'package:chat_app/pages/chat_page.dart';
import 'package:chat_app/services/auth/auth_service.dart';
import 'package:chat_app/services/chat/chat_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SearchUserPage extends StatefulWidget {
  static route() =>
      MaterialPageRoute(builder: (context) => const SearchUserPage());
  const SearchUserPage({super.key});

  @override
  State<SearchUserPage> createState() => _SearchUserPageState();
}

class _SearchUserPageState extends State<SearchUserPage> {
  // chat service
  final ChatService chatService = ChatService();
  final AuthService authService = AuthService();

  String name = '';

  @override
  Widget build(BuildContext context) {
    // This gesture detector that wrapped scaffold is used when we use CupertinoSearchTextField().
    // Because CupertinoSearchTextField() doesn't have onTapOutside parameter. If we use regular
    // TextField(), it will have onTapOutside parameter, and we don't need to wrap our scaffold
    // with GestureDetector().
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: CupertinoSearchTextField(
            onChanged: (value) {
              setState(() {
                name = value;
              });
            },
          ),
          // title: Card(
          //   child: TextField(
          //     decoration: const InputDecoration(
          //       prefixIcon: Icon(Icons.search),
          //       hintText: 'Search',
          //       filled: true,
          //       fillColor: Colors.white,
          //     ),
          //     onChanged: (value) {
          //       setState(() {
          //         name = value;
          //       });
          //     },
          //     onTapOutside: (event) {
          //       FocusManager.instance.primaryFocus?.unfocus();
          //     },
          //   ),
          // ),
        ),
        body: StreamBuilder<List<Map<String, dynamic>>>(
          stream: chatService.getUsersStreamExcludingBlocked(),
          builder: (context, snapshot) {
            // error
            if (snapshot.hasError) {
              return const Center(
                child: Text('Error'),
              );
            }

            // loading..
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            final searchUser = snapshot.data ?? [];

            // Check whether the text field is empty or not. If it's empty we show nothing.
            // If it's not, then we will show the searched user.
            // Change 'name.isNotEmpty' to 'name.isEmpty' or just remove the if function
            // if you want to show all users.
            if (name.isNotEmpty) {
              return ListView.builder(
                itemCount: searchUser.length,
                itemBuilder: (context, index) {
                  final user = searchUser[index];

                  if (user['email']
                      .toString()
                      .toLowerCase()
                      .contains(name.toLowerCase())) {
                    return UserTile(
                      text: user['email'],
                      onTap: () {
                        Navigator.push(
                          context,
                          ChatPage.route(
                            receiverID: user['uid'],
                            receiverEmail: user['email'],
                          ),
                        );
                      },
                    );
                  }

                  return Container();
                },
              );
            }

            return Container();
          },
        ),
      ),
    );
  }
}
