import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/tab_header.dart';

enum CommTab { chat, notifications }

final _commTabProvider = StateProvider<CommTab>((ref) => CommTab.chat);

class CommunicationScreen extends ConsumerWidget {
  const CommunicationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tab = ref.watch(_commTabProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: Column(
        children: [
          _CommHeader(isDark: isDark, tab: tab, onTabChanged: (t) => ref.read(_commTabProvider.notifier).state = t),
          Expanded(
            child: tab == CommTab.chat ? _ChatList(isDark: isDark) : _NotificationList(isDark: isDark),
          ),
        ],
      ),
      floatingActionButton: tab == CommTab.chat
          ? FloatingActionButton.extended(
              onPressed: () {},
              icon: const Icon(Icons.edit_rounded),
              label: const Text('새 공지'),
              backgroundColor: isDark ? AppColors.primaryDark : AppColors.primaryLight,
              foregroundColor: Colors.white,
            )
          : null,
    );
  }
}

class _CommHeader extends StatelessWidget {
  final bool isDark;
  final CommTab tab;
  final ValueChanged<CommTab> onTabChanged;

  const _CommHeader({required this.isDark, required this.tab, required this.onTabChanged});

  @override
  Widget build(BuildContext context) {
    return TabHeader(
      title: '소통',
      isDark: isDark,
      bottom: Row(
        children: [
          _TabBtn(label: '채팅 & 문의', isSelected: tab == CommTab.chat, onTap: () => onTabChanged(CommTab.chat), badge: '3'),
          const SizedBox(width: 8),
          _TabBtn(label: '알림', isSelected: tab == CommTab.notifications, onTap: () => onTabChanged(CommTab.notifications), badge: '2'),
        ],
      ),
    );
  }
}

class _TabBtn extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final String? badge;

  const _TabBtn({required this.label, required this.isSelected, required this.onTap, this.badge});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: isSelected ? Colors.white : Colors.transparent, width: 2)),
        ),
        child: Row(
          children: [
            Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.white60, fontSize: 14, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400)),
            if (badge != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(color: AppColors.unregistered, borderRadius: BorderRadius.circular(10)),
                child: Text(badge!, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ChatList extends StatelessWidget {
  final bool isDark;
  const _ChatList({required this.isDark});

  static const _channels = [
    ('📢', '공지사항', '단지 관리자', '엘리베이터 점검 안내', '10:30', '0', false),
    ('⚙️', '운영 채널', '내부', '방문 차량 처리 완료', '09:15', '0', false),
    ('💬', '홍길동 · 1:1 문의', '입주민', '주차 위반 이의제기 건', '어제', '3', true),
    ('💬', '이미래 · 1:1 문의', '입주민', '방문 차량 등록 문의', '어제', '0', false),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        _SectionLabel('채널', isDark: isDark),
        const SizedBox(height: 8),
        ..._channels.take(2).map((c) => _ChatItem(
          icon: c.$1, title: c.$2, subtitle: c.$3,
          lastMsg: c.$4, time: c.$5, badge: c.$6, isUnread: c.$7,
          isDark: isDark,
        )),
        const SizedBox(height: 16),
        _SectionLabel('1:1 문의', isDark: isDark),
        const SizedBox(height: 8),
        ..._channels.skip(2).map((c) => _ChatItem(
          icon: c.$1, title: c.$2, subtitle: c.$3,
          lastMsg: c.$4, time: c.$5, badge: c.$6, isUnread: c.$7,
          isDark: isDark,
        )),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final bool isDark;
  const _SectionLabel(this.label, {required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isDark ? AppColors.textDark : AppColors.textLight));
  }
}

class _ChatItem extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  final String lastMsg;
  final String time;
  final String badge;
  final bool isUnread;
  final bool isDark;

  const _ChatItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.lastMsg,
    required this.time,
    required this.badge,
    required this.isUnread,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final subColor = isDark ? AppColors.subtextDark : AppColors.subtextLight;
    final cardBg = isDark ? AppColors.surfaceDark : Colors.white;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        boxShadow: isDark ? null : [BoxShadow(color: AppColors.primaryLight.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: (isDark ? AppColors.primaryDark : AppColors.accentLight).withOpacity(0.13),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(child: Text(icon, style: const TextStyle(fontSize: 20))),
        ),
        title: Row(
          children: [
            Expanded(child: Text(title, style: TextStyle(fontSize: 14, fontWeight: isUnread ? FontWeight.w700 : FontWeight.w500, color: textColor))),
            Text(time, style: TextStyle(fontSize: 10, color: subColor)),
          ],
        ),
        subtitle: Row(
          children: [
            Expanded(
              child: Text(
                lastMsg,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: isUnread ? textColor : subColor, fontWeight: isUnread ? FontWeight.w500 : FontWeight.w400),
              ),
            ),
            if (badge != '0') ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(color: AppColors.unregistered, borderRadius: BorderRadius.circular(10)),
                child: Text(badge, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
              ),
            ],
          ],
        ),
        onTap: () => _openChat(context, isDark),
      ),
    );
  }

  void _openChat(BuildContext context, bool isDark) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _ChatDetailScreen(title: title, isDark: isDark)),
    );
  }
}

class _ChatDetailScreen extends StatefulWidget {
  final String title;
  final bool isDark;
  const _ChatDetailScreen({required this.title, required this.isDark});

  @override
  State<_ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<_ChatDetailScreen> {
  final _ctrl = TextEditingController();
  final _messages = <Map<String, dynamic>>[
    {'text': '안녕하세요. 주차 위반 관련 문의드립니다.', 'isMe': false, 'time': '09:30'},
    {'text': '네, 말씀해 주세요. 어떤 건으로 문의하셨나요?', 'isMe': true, 'time': '09:32'},
    {'text': '어제 제 차량이 주차 위반으로 기록된 것 같은데 확인 부탁드립니다.', 'isMe': false, 'time': '09:33'},
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.primaryLight,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (_, i) {
                final m = _messages[i];
                return _MessageBubble(text: m['text'], isMe: m['isMe'], time: m['time'], isDark: isDark);
              },
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(12, 8, 12, MediaQuery.of(context).padding.bottom + 8),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, -2))],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    decoration: InputDecoration(
                      hintText: '메시지 입력...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                      fillColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: isDark ? AppColors.primaryDark : AppColors.primaryLight,
                  child: IconButton(
                    icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                    onPressed: () {
                      if (_ctrl.text.trim().isEmpty) return;
                      setState(() => _messages.add({'text': _ctrl.text, 'isMe': true, 'time': '방금'}));
                      _ctrl.clear();
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String text;
  final bool isMe;
  final String time;
  final bool isDark;

  const _MessageBubble({required this.text, required this.isMe, required this.time, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(radius: 14, backgroundColor: (isDark ? AppColors.primaryDark : AppColors.primaryLight).withOpacity(0.13), child: const Text('👤', style: TextStyle(fontSize: 12))),
            const SizedBox(width: 8),
          ],
          Column(
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Container(
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.65),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isMe ? (isDark ? AppColors.primaryDark : AppColors.primaryLight) : (isDark ? AppColors.surfaceDark : Colors.white),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isMe ? 16 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 16),
                  ),
                  boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)],
                ),
                child: Text(text, style: TextStyle(fontSize: 14, color: isMe ? Colors.white : (isDark ? AppColors.textDark : AppColors.textLight))),
              ),
              const SizedBox(height: 4),
              Text(time, style: TextStyle(fontSize: 10, color: isDark ? AppColors.subtextDark : AppColors.subtextLight)),
            ],
          ),
        ],
      ),
    );
  }
}

class _NotificationList extends StatelessWidget {
  final bool isDark;
  const _NotificationList({required this.isDark});

  static const _notifs = [
    ('🚨', '미등록 차량 감지', '654마9012 차량이 감지되었습니다', '5분 전', AppColors.unregistered, true),
    ('🚗', '차량 등록 요청', '홍길동(101동 401호) 차량 등록 요청', '10분 전', AppColors.accentLight, true),
    ('👤', '입주민 가입 요청', '강미래 입주민 가입 신청', '1시간 전', AppColors.visitor, false),
    ('✅', '차량 등록 완료', '이서연(102동 504호) 차량 등록 처리', '2시간 전', AppColors.registered, false),
    ('🔔', '방문 차량 만료 임박', '789다1234 방문 허가 만료 30분 전', '30분 전', AppColors.visitor, false),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: _notifs.map((n) => _NotifCard(
        icon: n.$1, title: n.$2, desc: n.$3,
        time: n.$4, color: n.$5, isUnread: n.$6,
        isDark: isDark,
      )).toList(),
    );
  }
}

class _NotifCard extends StatelessWidget {
  final String icon;
  final String title;
  final String desc;
  final String time;
  final Color color;
  final bool isUnread;
  final bool isDark;

  const _NotifCard({
    required this.icon,
    required this.title,
    required this.desc,
    required this.time,
    required this.color,
    required this.isUnread,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final subColor = isDark ? AppColors.subtextDark : AppColors.subtextLight;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: isUnread ? Border(left: BorderSide(color: color, width: 3)) : null,
        boxShadow: isDark ? null : [BoxShadow(color: AppColors.primaryLight.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: color.withOpacity(0.13), borderRadius: BorderRadius.circular(12)),
            child: Center(child: Text(icon, style: const TextStyle(fontSize: 18))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(title, style: TextStyle(fontSize: 13, fontWeight: isUnread ? FontWeight.w700 : FontWeight.w500, color: textColor))),
                    Text(time, style: TextStyle(fontSize: 10, color: subColor)),
                  ],
                ),
                const SizedBox(height: 3),
                Text(desc, style: TextStyle(fontSize: 12, color: subColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
