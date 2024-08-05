import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:pw_24/models/user_profile.dart';
import 'package:pw_24/pages/chat_page.dart';
import 'package:pw_24/services/alert_service.dart';
import 'package:pw_24/services/auth_service.dart';
import 'package:pw_24/services/database_service.dart';
import 'package:pw_24/services/navigation_service.dart';
import 'package:pw_24/widgets/chat_tile.dart';
import 'package:pw_24/pages/goals_page.dart';
import 'package:pw_24/pages/profile.dart'; // Add this import

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late AlertService _alertService;
  late AuthService _authService;
  late DatabaseService _databaseService;
  final GetIt _getIt = GetIt.instance;
  late NavigationService _navigationService;
  bool _isLoading = false;
  int _selectedIndex = 0;
  late PageController _pageController;

  Stream<UserProfile?> get _userProfileStream => 
      _databaseService.getUserProfileStream(_authService.user!.uid);

  @override
  void initState() {
    super.initState();
    _authService = _getIt.get<AuthService>();
    _navigationService = _getIt.get<NavigationService>();
    _alertService = _getIt.get<AlertService>();
    _databaseService = _getIt.get<DatabaseService>();
    _pageController = PageController(initialPage: _selectedIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getAppBarTitle()),
        actions: _getAppBarActions(),
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() => _selectedIndex = index);
        },
        children: [
          _buildUI(),
          GoalsPage(),
          ProfilePage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.checklist),
            label: 'Goals',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
      ),
    );
  }

  String _getAppBarTitle() {
    switch (_selectedIndex) {
      case 0:
        return "Messages";
      case 1:
        return "Your action plan";
      case 2:
        return "Profile";
      default:
        return "Messages";
    }
  }

  List<Widget> _getAppBarActions() {
    switch (_selectedIndex) {
      case 0:
        return [
          IconButton(
            onPressed: () async {
              bool result = await _authService.logout();
              if (result) {
                _alertService.showToast(
                    text: "Successfully logged out!", icon: Icons.check);
                _navigationService.pushReplacementNamed("/login");
              }
            },
            color: Colors.red,
            icon: const Icon(Icons.logout),
          ),
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: _addFriend,
          ),
          IconButton(
            icon: const Icon(Icons.people),
            onPressed: _findMatch,
          ),
        ];
      case 1:
        return [];
      case 2:
        return []; // No actions for the profile page
      default:
        return [];
    }
  }

  void _addFriend() async {
    final username = await _showAddFriendDialog();
    if (username != null && username.isNotEmpty) {
      setState(() {
        _isLoading = true;
      });
      try {
        print('Attempting to add friend with username: $username');
        final success = await _databaseService.addFriendByUsername(_authService.user!.uid, username);
        if (success) {
          print('Friend added successfully');
          _alertService.showToast(text: "Friend added successfully!", icon: Icons.check);
        } else {
          print('Failed to add friend');
          _alertService.showToast(text: "User not found or already a friend.", icon: Icons.info);
        }
      } catch (e) {
        print("Error adding friend: $e");
        _alertService.showToast(text: "Error adding friend. Please try again.", icon: Icons.error);
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<String?> _showAddFriendDialog() async {
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        String username = '';
        return AlertDialog(
          title: const Text('Add Friend'),
          content: TextField(
            onChanged: (value) => username = value,
            decoration: const InputDecoration(hintText: "Enter friend's username"),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Add'),
              onPressed: () => Navigator.of(context).pop(username),
            ),
          ],
        );
      },
    );
  }

  Future<void> _findMatch() async {
    setState(() {
      _isLoading = true;
    });

    try {
      String currentUserId = _authService.user!.uid;
      print('Current User ID: $currentUserId');
      
      UserProfile? currentUserProfile = await _databaseService.getUserProfile(currentUserId);
      
      if (currentUserProfile == null) {
        print('Error: User profile not found for ID: $currentUserId');
        _alertService.showToast(text: "Error: User profile not found", icon: Icons.error);
        return;
      }

      print('Current User Profile: ${currentUserProfile.toJson()}');

      if (currentUserProfile.match != null && currentUserProfile.match!.isNotEmpty) {
        print('User already has a match: ${currentUserProfile.match}');
        _alertService.showToast(text: "You already have a match!", icon: Icons.info);
        return;
      }

      String? matchedUserId = await _databaseService.findMatchForUser(currentUserId, currentUserProfile.goalType);
      if (matchedUserId != null) {
        print('Match found: $matchedUserId');
        _alertService.showToast(text: "Match found!", icon: Icons.check);
        setState(() {});
      } else {
        print('No match found');
        _alertService.showToast(text: "No match found at this time.", icon: Icons.info);
      }
    } catch (e) {
      print("Error finding match: $e");
      _alertService.showToast(text: "Error finding match. Please try again.", icon: Icons.error);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _displayGoalInputDialog() async {
    // Implement the dialog logic here
    // For example:
    String? newGoal = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        String goal = '';
        return AlertDialog(
          title: const Text('Set a New Goal'),
          content: TextField(
            onChanged: (value) => goal = value,
            decoration: const InputDecoration(hintText: "Enter your goal"),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Set'),
              onPressed: () => Navigator.of(context).pop(goal),
            ),
          ],
        );
      },
    );

    if (newGoal != null && newGoal.isNotEmpty) {
      // Handle the new goal (e.g., save it to the database)
      // You might want to use _databaseService here
    }
  }

  Widget _buildUI() {
    return SafeArea(
        child: Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 15.0,
        vertical: 20.0,
      ),
      child: _chatsList(),
    ));
  }

  Widget _chatsList() {
    return StreamBuilder(
      stream: _databaseService.getMatchProfiles(_authService.user!.uid),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text("unable to load data"),
          );
        }
        if (snapshot.hasData && snapshot.data != null) {
          final users = snapshot.data!.docs;
          return ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                UserProfile user = users[index].data();
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 10.0,
                  ),
                  child: ChatTile(
                    userProfile: user,
                    onTap: () async {
                      final chatExists = await _databaseService.checkChatExists(
                          _authService.user!.uid, user.uid!);
                      if (!chatExists) {
                        await _databaseService.createNewChat(
                            _authService.user!.uid, user.uid!);
                      }
                      _navigationService.push(
                        MaterialPageRoute(
                          builder: (context) {
                            return ChatPage(
                              chatUser: user,
                            );
                          },
                        ),
                      );
                    },
                  ),
                );
              });
            } 
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }

}