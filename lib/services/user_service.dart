import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../utils/image_utils.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;

  // Get current user profile
  Stream<User?> getCurrentUserProfile() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return Stream.value(null);

    return _firestore
        .collection('users')
        .doc(currentUser.uid)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return User.fromMap(doc.data()!, doc.id);
    });
  }

  // Get user profile by ID
  Future<User?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) return null;
      return User.fromMap(doc.data()!, doc.id);
    } catch (e) {
      if (kDebugMode) print('Error getting user profile: $e');
      return null;
    }
  }

  // Create initial user profile
  Future<User> createUserProfile({
    required String uid,
    required String email,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    DateTime? dateOfBirth,
    String? photoURL,
    bool isGoogleUser = false,
  }) async {
    try {
      // Parse names from Firebase display name if available
      final firebaseUser = _auth.currentUser;
      String parsedFirstName = firstName ?? '';
      String parsedLastName = lastName ?? '';

      if (isGoogleUser && firebaseUser?.displayName != null) {
        final nameParts = firebaseUser!.displayName!.split(' ');
        parsedFirstName = firstName ?? nameParts.first;
        parsedLastName = lastName ??
            (nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '');
      }

      final user = User(
        uid: uid,
        firstName: parsedFirstName,
        lastName: parsedLastName,
        email: email,
        phoneNumber: phoneNumber,
        dateOfBirth: dateOfBirth,
        photoURL: photoURL ?? firebaseUser?.photoURL,
        settings: UserSettings(),
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
        profileCompleted: _isProfileComplete(
            parsedFirstName, parsedLastName, phoneNumber, dateOfBirth),
        isGoogleUser: isGoogleUser,
      );

      await _firestore.collection('users').doc(uid).set(user.toMap());
      return user;
    } catch (e) {
      if (kDebugMode) print('Error creating user profile: $e');
      rethrow;
    }
  }

  // Update user profile
  Future<void> updateUserProfile(User user) async {
    try {
      await _firestore.collection('users').doc(user.uid).update(user.toMap());
    } catch (e) {
      if (kDebugMode) print('Error updating user profile: $e');
      rethrow;
    }
  }

  // Update specific fields
  Future<void> updateUserFields(String uid, Map<String, dynamic> fields) async {
    try {
      await _firestore.collection('users').doc(uid).update(fields);
    } catch (e) {
      if (kDebugMode) print('Error updating user fields: $e');
      rethrow;
    }
  }

  // Upload profile photo as Base64 string
  Future<String?> uploadProfilePhoto(XFile imageFile, String uid) async {
    try {
      // Validate the image first
      if (!await ImageUtils.validateProfileImage(imageFile)) {
        throw Exception('Invalid image format or size too large');
      }

      // Compress image to Base64
      final base64Image = await ImageUtils.compressImageToBase64(imageFile);
      if (base64Image == null) {
        throw Exception('Failed to compress image');
      }

      // Check final size
      final imageSize = ImageUtils.getBase64ImageSize(base64Image);
      if (imageSize > 150 * 1024) {
        // 150KB limit for safety
        throw Exception('Compressed image is still too large');
      }

      // Update the user document with Base64 image and timestamp
      await updateUserFields(uid, {
        'photoURL': base64Image,
        'lastPhotoUpdate': DateTime.now().millisecondsSinceEpoch,
      });

      if (kDebugMode) {
        print(
            'Profile photo uploaded successfully. Size: ${(imageSize / 1024).toStringAsFixed(1)}KB');
      }

      return base64Image;
    } catch (e) {
      if (kDebugMode) print('Error uploading profile photo: $e');
      rethrow;
    }
  }

  // Check if profile is complete
  bool _isProfileComplete(String? firstName, String? lastName,
      String? phoneNumber, DateTime? dateOfBirth) {
    return firstName?.isNotEmpty == true &&
        lastName?.isNotEmpty == true &&
        phoneNumber?.isNotEmpty == true &&
        dateOfBirth != null;
  }

  // Export user data
  Future<Map<String, dynamic>> exportUserData(String uid) async {
    try {
      final user = await getUserProfile(uid);
      if (user == null) throw Exception('User not found');

      return {
        'profile': user.toMap(),
        'exportedAt': DateTime.now().toIso8601String(),
        'dataVersion': '1.0',
      };
    } catch (e) {
      if (kDebugMode) print('Error exporting user data: $e');
      rethrow;
    }
  }

  // Complete profile after signup
  Future<void> completeProfile({
    required String uid,
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required DateTime dateOfBirth,
    XFile? profilePhoto,
  }) async {
    try {
      final updates = <String, dynamic>{
        'firstName': firstName,
        'lastName': lastName,
        'phoneNumber': phoneNumber,
        'dateOfBirth': dateOfBirth.millisecondsSinceEpoch,
        'profileCompleted': true,
      };

      // Upload photo if provided
      if (profilePhoto != null) {
        final photoUrl = await uploadProfilePhoto(profilePhoto, uid);
        if (photoUrl != null) {
          updates['photoURL'] = photoUrl;
          updates['lastPhotoUpdate'] = DateTime.now().millisecondsSinceEpoch;
        }
      }

      await updateUserFields(uid, updates);
    } catch (e) {
      if (kDebugMode) print('Error completing profile: $e');
      rethrow;
    }
  }

  // Delete user profile and data
  Future<void> deleteUserProfile(String uid) async {
    try {
      // Since we're using Base64 storage in Firestore, just delete the user document
      // The photo is stored as part of the document and will be deleted automatically
      await _firestore.collection('users').doc(uid).delete();
    } catch (e) {
      if (kDebugMode) print('Error deleting user profile: $e');
      rethrow;
    }
  }
}

// Riverpod providers
final userServiceProvider = Provider<UserService>((ref) => UserService());

final currentUserProfileProvider = StreamProvider<User?>((ref) {
  final userService = ref.watch(userServiceProvider);
  return userService.getCurrentUserProfile();
});

final userProfileProvider = FutureProvider.family<User?, String>((ref, uid) {
  final userService = ref.watch(userServiceProvider);
  return userService.getUserProfile(uid);
});
