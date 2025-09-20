import 'package:flutter/material.dart';
import 'dart:convert';

class ProfileAvatar extends StatelessWidget {
  final String? photoURL;
  final double radius;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const ProfileAvatar({
    super.key,
    this.photoURL,
    this.radius = 50,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor =
        backgroundColor ?? Theme.of(context).colorScheme.primaryContainer;
    final fgColor =
        foregroundColor ?? Theme.of(context).colorScheme.onPrimaryContainer;

    // If no photo, show default avatar
    if (photoURL == null || photoURL!.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: bgColor,
        child: Icon(
          Icons.person,
          size: radius * 1.2,
          color: fgColor,
        ),
      );
    }

    // Check if it's a Base64 image (data URL)
    if (photoURL!.startsWith('data:image/')) {
      try {
        // Extract base64 data after the comma
        final base64Data = photoURL!.split(',')[1];
        final imageBytes = base64Decode(base64Data);

        return CircleAvatar(
          radius: radius,
          backgroundColor: bgColor,
          backgroundImage: MemoryImage(imageBytes),
          onBackgroundImageError: (exception, stackTrace) {
            // If Base64 image fails to load, show default avatar
          },
          child: null, // No child when image is present
        );
      } catch (e) {
        // If Base64 decoding fails, show default avatar
        return CircleAvatar(
          radius: radius,
          backgroundColor: bgColor,
          child: Icon(
            Icons.person,
            size: radius * 1.2,
            color: fgColor,
          ),
        );
      }
    }

    // Handle regular network URLs (for backward compatibility)
    return CircleAvatar(
      radius: radius,
      backgroundColor: bgColor,
      backgroundImage: NetworkImage(photoURL!),
      onBackgroundImageError: (exception, stackTrace) {
        // If network image fails to load, show default avatar
      },
      child: null, // No child when image is present
    );
  }
}
