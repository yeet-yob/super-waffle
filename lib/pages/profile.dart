import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:pw_24/consts.dart';
import 'package:pw_24/services/database_service.dart';
import 'package:pw_24/services/auth_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final DatabaseService _databaseService = GetIt.instance<DatabaseService>();
  final AuthService _authService = GetIt.instance<AuthService>();
  final ImagePicker _picker = ImagePicker();

  String _username = 'John Doe';
  String _profileImageUrl = 'https://example.com/default-profile-image.jpg';
  String _goalType = 'Not set';

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  void _loadUserProfile() async {
    final userProfile =
        await _databaseService.getUserProfile(_authService.user!.uid);
    if (userProfile != null) {
      setState(() {
        _username = userProfile.username ?? 'user';
        _profileImageUrl = userProfile.pfpURL ?? PLACEHOLDER_PFP;
        _goalType = userProfile.goalType ?? 'Not set';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: GestureDetector(
                onTap: _changeProfilePicture,
                child: CircleAvatar(
                  radius: 50,
                  child: ClipOval(
                    child: FadeInImage.assetNetwork(
                      placeholder: 'assets/placeholder_image.png',
                      image: _profileImageUrl,
                      fit: BoxFit.cover,
                      width: 100,
                      height: 100,
                      imageErrorBuilder: (context, error, stackTrace) {
                        return Image.asset('assets/placeholder_image.png', fit: BoxFit.cover);
                      },
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Username: $_username'),
            const SizedBox(height: 10),
            Text('Goal Type: $_goalType'),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _changeUsername,
              child: const Text('Change Username'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _changeProfilePicture() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      final File imageFile = File(image.path);
      final String fileName = '${_authService.user!.uid}_profile_picture.jpg';
      final Reference storageRef =
          FirebaseStorage.instance.ref().child('profile_pictures/$fileName');

      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Uploading image...')),
      );

      await storageRef.putFile(imageFile);
      final String downloadUrl = await storageRef.getDownloadURL();

      await _databaseService.changeProfilePicture(
          _authService.user!.uid, downloadUrl);

      // Update the state and force a rebuild
      setState(() {
        _profileImageUrl = downloadUrl;
      });

      // Clear previous snackbar and show success message
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile picture updated successfully')),
      );

      // Force image cache to clear
      imageCache.clear();
      imageCache.clearLiveImages();

      // Reload user profile to ensure we have the latest data
      _loadUserProfile();
    } catch (e) {
      print('Error changing profile picture: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update profile picture')),
      );
    }
  }

  Future<void> _changeUsername() async {
    String? newUsername = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        String? enteredUsername;
        return AlertDialog(
          title: const Text('Change Username'),
          content: TextField(
            onChanged: (value) => enteredUsername = value,
            decoration: const InputDecoration(hintText: "Enter new username"),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Save'),
              onPressed: () => Navigator.of(context).pop(enteredUsername),
            ),
          ],
        );
      },
    );

    if (newUsername != null && newUsername.isNotEmpty) {
      try {
        await _databaseService.changeUsername(
            _authService.user!.uid, newUsername);
        setState(() {
          _username = newUsername!;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Username updated successfully')),
        );
      } catch (e) {
        print('Error changing username: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update username')),
        );
      }
    }
  }
}