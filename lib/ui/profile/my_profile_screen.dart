import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../app_scope.dart';
import '../../data/models/models.dart';
import '../theme.dart';
import '../widgets/initials_avatar.dart';
import 'photo_viewer.dart';

class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({super.key});

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppScope.of(context).controller.refreshMyProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context).controller;
    return Scaffold(
      appBar: AppBar(title: const Text('الملف الشخصي')),
      body: ValueListenableBuilder<WaProfile>(
        valueListenable: controller.myProfile,
        builder: (context, profile, _) {
          return ListView(
            children: [
              const SizedBox(height: 28),
              Center(
                child: GestureDetector(
                  onTap: () {
                    if (profile.photoPath != null) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PhotoViewer(
                            path: profile.photoPath!,
                            title: profile.name,
                          ),
                        ),
                      );
                    }
                  },
                  child: Stack(
                    children: [
                      InitialsAvatar(
                        name: profile.name,
                        path: profile.photoPath,
                        size: 140,
                      ),
                      Positioned(
                        left: 4,
                        bottom: 4,
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: AppColors.teal,
                          child: IconButton(
                            tooltip: 'تغيير الصورة',
                            onPressed: () => _changePhoto(context),
                            icon: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
              ListTile(
                leading: const Icon(Icons.person_outline, color: AppColors.teal),
                title: const Text('الاسم'),
                subtitle: Text(
                  SafeText.display(profile.name, fallback: 'حسابي'),
                ),
                trailing: const Icon(Icons.edit_outlined),
                onTap: () => _editName(context, profile.name),
              ),
              ListTile(
                leading: const Icon(Icons.info_outline, color: AppColors.teal),
                title: const Text('نبذة'),
                subtitle: Text(
                  SafeText.display(
                    profile.about,
                    fallback: 'مرحبًا! أنا أستخدم واتساب.',
                  ),
                ),
                trailing: const Icon(Icons.edit_outlined),
                onTap: () => _editAbout(context, profile.about),
              ),
              ListTile(
                leading: const Icon(Icons.phone_outlined, color: AppColors.teal),
                title: const Text('الهاتف'),
                subtitle: Text(
                  SafeText.display(
                    profile.phone ?? DisplayNames.digits(profile.waId),
                    fallback: profile.waId,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => controller.refreshMyProfile(),
                child: const Text('تحديث الملف من واتساب'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _changePhoto(BuildContext context) async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (file == null || !context.mounted) return;
    try {
      await AppScope.of(context).controller.updateMyPhoto(
        await file.readAsBytes(),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر تحديث الصورة')),
      );
    }
  }

  Future<void> _editName(BuildContext context, String current) async {
    final value = await _prompt(context, 'الاسم', current);
    if (value == null || !context.mounted) return;
    try {
      await AppScope.of(context).controller.updateMyName(value);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر تحديث الاسم')),
      );
    }
  }

  Future<void> _editAbout(BuildContext context, String current) async {
    final value = await _prompt(context, 'نبذة', current);
    if (value == null || !context.mounted) return;
    try {
      await AppScope.of(context).controller.updateMyAbout(value);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر تحديث النبذة')),
      );
    }
  }

  Future<String?> _prompt(BuildContext context, String title, String current) {
    final input = TextEditingController(text: current);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: input,
          autofocus: true,
          maxLength: 140,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, input.text.trim()),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }
}
