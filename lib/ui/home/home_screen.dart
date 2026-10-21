import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../data/db/app_database.dart';
import '../../data/models/models.dart';
import '../chat/chat_screen.dart';
import '../profile/my_profile_screen.dart';
import '../status/status_tab.dart';
import '../theme.dart';
import '../widgets/connection_banner.dart';
import '../widgets/initials_avatar.dart';
import '../widgets/qr_panel.dart';
import '../widgets/receipt_ticks.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final _search = TextEditingController();
  final _statusTab = GlobalKey<StatusTabState>();
  bool _searching = false;
  TabController? _tabs;

  TabController get _tabController {
    final existing = _tabs;
    if (existing != null) return existing;
    final created = TabController(length: 3, vsync: this);
    created.addListener(() {
      if (mounted) setState(() {});
    });
    return _tabs = created;
  }

  @override
  void dispose() {
    _tabs?.dispose();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final tabs = _tabController;
    final onStatus = tabs.index == 1;
    final onChannels = tabs.index == 2;
    return ValueListenableBuilder<String>(
      valueListenable: scope.controller.shellPhase,
      builder: (context, phase, _) {
        if (phase == AppShellPhase.needQr) {
          return const _LinkAccountScreen();
        }
        if (phase != AppShellPhase.ready) {
          return const _BootstrapGate();
        }
        return _buildInbox(scope, tabs, onStatus, onChannels);
      },
    );
  }

  Widget _buildInbox(
    AppScope scope,
    TabController tabs,
    bool onStatus,
    bool onChannels,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: _searching
            ? TextField(
                controller: _search,
                autofocus: true,
                style: const TextStyle(color: AppColors.ink),
                cursorColor: AppColors.accent,
                decoration: InputDecoration(
                  hintText: onChannels
                      ? 'ابحث في القنوات'
                      : onStatus
                      ? 'ابحث في الحالات'
                      : 'ابحث في الدردشات المحفوظة',
                  hintStyle: const TextStyle(color: Color(0xFF7A8494)),
                  fillColor: Colors.transparent,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
                onChanged: (_) => setState(() {}),
              )
            : Text(onChannels ? 'القنوات' : onStatus ? 'الحالات' : 'راسل'),
        actions: [
          IconButton(
            tooltip: 'بحث',
            onPressed: () {
              setState(() {
                _searching = !_searching;
                if (!_searching) _search.clear();
              });
            },
            icon: Icon(_searching ? Icons.close : Icons.search),
          ),
          IconButton(
            tooltip: 'الملف الشخصي',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MyProfileScreen()),
              );
            },
            icon: ValueListenableBuilder<WaProfile>(
              valueListenable: scope.controller.myProfile,
              builder: (context, profile, _) {
                return InitialsAvatar(
                  name: profile.name,
                  path: profile.photoPath,
                  size: 30,
                );
              },
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'profile') {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const MyProfileScreen()),
                );
              } else if (value == 'connect' || value == 'sync') {
                await scope.controller.connect();
              } else if (value == 'logout') {
                await scope.controller.disconnect(logout: true);
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'profile', child: Text('الملف الشخصي')),
              PopupMenuItem(value: 'connect', child: Text('ربط الحساب')),
              PopupMenuItem(value: 'sync', child: Text('مزامنة الآن')),
              PopupMenuItem(value: 'logout', child: Text('تسجيل الخروج')),
            ],
          ),
        ],
        bottom: TabBar(
          controller: tabs,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          indicatorSize: TabBarIndicatorSize.tab,
          indicator: BoxDecoration(
            color: AppColors.accentSoft,
            borderRadius: BorderRadius.circular(20),
          ),
          tabs: const [
            Tab(text: 'الدردشات'),
            Tab(text: 'القصص'),
            Tab(text: 'القنوات'),
          ],
        ),
      ),
      body: Column(
        children: [
          const ConnectionBanner(),
          Expanded(
            child: TabBarView(
              controller: tabs,
              children: [
                _ChatList(
                  stream: scope.db.watchChats(),
                  query: _search.text,
                  empty: _EmptyChats(searching: _search.text.isNotEmpty),
                ),
                StatusTab(
                  key: _statusTab,
                  query: _search.text,
                  active: onStatus,
                ),
                _ChatList(
                  stream: scope.db.watchChannels(),
                  query: _search.text,
                  empty: _EmptyChannels(searching: _search.text.isNotEmpty),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: onChannels
          ? null
          : FloatingActionButton.extended(
              tooltip: onStatus ? 'إضافة قصة' : 'محادثة جديدة',
              onPressed: () {
                if (onStatus) {
                  _statusTab.currentState?.addStatus(context);
                  return;
                }
                _newChat(context);
              },
              icon: Icon(onStatus ? Icons.add_photo_alternate_outlined : Icons.edit_outlined),
              label: Text(onStatus ? 'قصة جديدة' : 'محادثة'),
            ),
    );
  }

  Future<void> _newChat(BuildContext context) async {
    final phone = await showDialog<String>(
      context: context,
      builder: (context) => const _NewChatDialog(),
    );
    if (phone == null || !context.mounted) return;
    final chat = await AppScope.of(context).controller.openOrCreateChat(phone);
    if (!context.mounted) return;
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => ChatScreen(chat: chat)));
  }
}

class _BootstrapGate extends StatelessWidget {
  const _BootstrapGate();

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context).controller;
    return Material(
      color: AppColors.canvas,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: ValueListenableBuilder<double>(
            valueListenable: controller.bootstrapProgress,
            builder: (context, progress, _) {
              return ValueListenableBuilder<String>(
                valueListenable: controller.bootstrapLabel,
                builder: (context, label, _) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.forum_outlined,
                        size: 56,
                        color: AppColors.accent,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'راسل',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 28),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progress <= 0 ? null : progress,
                          minHeight: 8,
                          backgroundColor: const Color(0xFFE6E9EF),
                          color: AppColors.accent,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        label,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.5,
                          color: Color(0xFF5B6574),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'انتظر حتى تكتمل المزامنة ثم تظهر المحادثات.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF8A93A3),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _LinkAccountScreen extends StatelessWidget {
  const _LinkAccountScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: const Text('ربط الحساب')),
      body: const SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            children: [
              Text(
                'امسح الرمز من واتساب في هاتفك.\nلن تظهر المحادثات إلا بعد اكتمال الربط.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, height: 1.6, color: Color(0xFF5B6574)),
              ),
              SizedBox(height: 20),
              QrPanel(),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatList extends StatelessWidget {
  const _ChatList({
    required this.stream,
    required this.query,
    required this.empty,
  });

  final Stream<List<LocalChat>> stream;
  final String query;
  final Widget empty;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<LocalChat>>(
      stream: stream,
      builder: (context, snapshot) {
        final chats = (snapshot.data ?? const <LocalChat>[]).where((chat) {
          final text = query.trim();
          if (text.isEmpty) return true;
          return chat.name.contains(text) ||
              (chat.lastMessageText?.contains(text) ?? false);
        }).toList();

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (chats.isEmpty) return empty;
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 88),
          itemCount: chats.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            return _ChatTile(chat: chats[index]);
          },
        );
      },
    );
  }
}

class _ChatTile extends StatelessWidget {
  const _ChatTile({required this.chat});

  final LocalChat chat;

  @override
  Widget build(BuildContext context) {
    final channel = ChatKinds.isChannelId(chat.waChatId);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      leading: InitialsAvatar(
        name: chat.name,
        path: chat.profilePicPath,
        isGroup: chat.isGroup,
        isChannel: channel,
      ),
      title: Text(
        SafeText.display(chat.name, fallback: channel ? 'قناة' : 'محادثة'),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: StreamBuilder<LocalMessage?>(
        stream: AppScope.of(context).db.watchLatestMessage(chat.id),
        builder: (context, snapshot) {
          final last = snapshot.data;
          final preview = SafeText.display(
            MediaText.preview(chat.lastMessageText),
            fallback: channel
                ? 'لا توجد منشورات محفوظة بعد'
                : 'لا توجد رسائل محفوظة بعد',
          );
          return Row(
            children: [
              if (last?.fromMe == true) ...[
                ReceiptTicks(
                  status: last!.deliveryStatus,
                  isGroup: chat.isGroup,
                  size: 16,
                ),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: Text(
                  preview,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );
        },
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            formatChatTime(chat.lastMessageAt),
            style: TextStyle(
              fontSize: 12,
              color: chat.unreadCount > 0
                  ? AppColors.accent
                  : Colors.grey.shade600,
            ),
          ),
          if (chat.unreadCount > 0) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${chat.unreadCount}',
                style: const TextStyle(color: Colors.white, fontSize: 11),
              ),
            ),
          ],
        ],
      ),
      onTap: () {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => ChatScreen(chat: chat)));
      },
    ),
    );
  }
}

class _EmptyChats extends StatelessWidget {
  const _EmptyChats({required this.searching});

  final bool searching;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Icon(
          searching ? Icons.search_off : Icons.chat_bubble_outline,
          size: 56,
          color: Colors.grey.shade400,
        ),
        const SizedBox(height: 16),
        Text(
          searching ? 'لا توجد نتائج في الدردشات' : 'لا توجد محادثات بعد',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          searching
              ? 'البحث يعمل على ما تم حفظه محليًا فقط.'
              : 'عند وصول رسائل جديدة ستظهر هنا.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade600),
        ),
      ],
    );
  }
}

class _EmptyChannels extends StatelessWidget {
  const _EmptyChannels({required this.searching});

  final bool searching;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Icon(
          searching ? Icons.search_off : Icons.campaign_outlined,
          size: 56,
          color: Colors.grey.shade400,
        ),
        const SizedBox(height: 16),
        Text(
          searching ? 'لا توجد نتائج في القنوات' : 'لا توجد قنوات محفوظة',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          searching
              ? 'البحث يعمل على القنوات المحفوظة محليًا فقط.'
              : 'القنوات تظهر هنا بعد المزامنة، منفصلة عن الدردشات العادية.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade600),
        ),
      ],
    );
  }
}

class _NewChatDialog extends StatefulWidget {
  const _NewChatDialog();

  @override
  State<_NewChatDialog> createState() => _NewChatDialogState();
}

class _NewChatDialogState extends State<_NewChatDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('محادثة جديدة'),
      content: TextField(
        controller: _controller,
        keyboardType: TextInputType.phone,
        decoration: const InputDecoration(
          labelText: 'رقم الهاتف',
          hintText: '9665xxxxxxx',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text.trim()),
          child: const Text('فتح'),
        ),
      ],
    );
  }
}
