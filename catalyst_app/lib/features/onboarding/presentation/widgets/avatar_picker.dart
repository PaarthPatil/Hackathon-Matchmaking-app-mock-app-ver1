import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AvatarPicker extends StatelessWidget {
  final File? selectedFile;
  final String? existingUrl;
  final ValueChanged<File> onPick;

  const AvatarPicker({
    super.key,
    this.selectedFile,
    this.existingUrl,
    required this.onPick,
  });

  Future<void> _pickImage(BuildContext context) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );
    if (picked != null) {
      onPick(File(picked.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    ImageProvider? imageProvider;
    if (selectedFile != null) {
      imageProvider = FileImage(selectedFile!);
    } else if (existingUrl != null && existingUrl!.isNotEmpty) {
      imageProvider = NetworkImage(existingUrl!);
    }

    return GestureDetector(
      onTap: () => _pickImage(context),
      child: Column(
        children: [
          CircleAvatar(
            radius: 48,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            backgroundImage: imageProvider,
            child: imageProvider == null
                ? Icon(
                    Icons.add_a_photo_outlined,
                    size: 32,
                    color: theme.colorScheme.onSurfaceVariant,
                  )
                : null,
          ),
          const SizedBox(height: 8),
          Text(
            imageProvider == null ? 'Add a photo' : 'Change photo',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
