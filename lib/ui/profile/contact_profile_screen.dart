import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../data/db/app_database.dart';
import '../../data/models/models.dart';
import '../theme.dart';
import '../widgets/initials_avatar.dart';
import 'photo_viewer.dart';

class ContactProfileScreen extends StatefulWidget {
  const ContactProfileScreen({super.key, required this.chat});

  final LocalChat chat;

  @override
  State<ContactProfileScreen> createState() => _ContactProfileScreenState();
}

class _ContactProfileScreenState extends State<ContactProfileScreen> {
  WaProfile? _profile;
  bool _loading = true;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _load();
  }

  Future<void> _load() async {
    final profile = await AppScope.of(context).controller.loadContactProfile(
      widget.chat,
    );
    if (!mounted) return;
    setState(() {
      _profile = profile;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final chat = widget.chat;
    final profile = _profile;
    final name = profile?.name ?? chat.name;
    final photo = profile?.photoPath ?? chat.profilePicPath;
    final group = chat.isGroup;
    final channel = ChatKinds.isChannelId(chat.waChatId);
    final phone = profile?.phone;
    return Scaffold(
      appBar: AppBar(title: Text(group ? 'بيانات المجموعة' : 'بيانات جهة الاتصال')),
      body: ListView(
        children: [
          Container(
            color: AppColors.ink,
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
            child: Column(
              children: [
                GestureDetector(
                  onTap: photo == null
                      ? null
                      : () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => PhotoViewer(
                                path: photo,
                                title: name,
                              ),
                            ),
                          );
                        },
                  child: InitialsAvatar(
                    name: name,
                    path: photo,
                    isGroup: group,
                    isChannel: channel,
                    size: 140,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  SafeText.display(name, fallback: group ? 'مجموعة' : 'جهة اتصال'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline, color: AppColors.teal),
            title: const Text('نبذة'),
            subtitle: Text(
              SafeText.display(
                profile?.about,
                fallback: _loading ? 'جاري التحميل...' : 'لا توجد نبذة',
              ),
            ),
          ),
          ListTile(
            leading: Icon(
              group ? Icons.group_outlined : Icons.phone_outlined,
              color: AppColors.teal,
            ),
            title: Text(group ? 'معرف المجموعة' : 'الهاتف'),
            subtitle: Text(
              group
                  ? chat.waChatId
                  : SafeText.display(
                      phone,
                      fallback: _loading
                          ? 'جاري التحميل...'
                          : 'لا يوجد رقم هاتف ظاهر لهذا الحساب',
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
