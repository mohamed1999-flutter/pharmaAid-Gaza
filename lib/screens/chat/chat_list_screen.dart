import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../core/models/chat_models.dart';
import '../../core/service/auth_service.dart';
import '../../core/service/firestore_service.dart';
import 'chat_detail_screen.dart';

class ChatListScreen extends StatefulWidget {
  final bool isPharmacy;

  const ChatListScreen({super.key, required this.isPharmacy});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final uid = AuthService.currentUser?.uid ?? '';
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final theme = Theme.of(context);

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isAr ? 'المحادثات' : 'Chats'),
          centerTitle: true,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
                decoration: InputDecoration(
                  hintText: isAr ? 'بحث عن محادثة...' : 'Search for a chat...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest
                      .withOpacity(0.5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
              ),
            ),
          ),
        ),
        body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: widget.isPharmacy
              ? FirestoreService.pharmacyChatsStream(uid)
              : FirestoreService.userChatsStream(uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      size: 80,
                      color: theme.colorScheme.primary.withOpacity(0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isAr ? 'لا توجد محادثات حتى الآن' : 'No chats yet',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              );
            }

            var chats = snapshot.data!.docs
                .map((doc) => ChatRoomModel.fromMap(doc.id, doc.data()))
                .toList();

            if (_searchQuery.isNotEmpty) {
              chats = chats.where((chat) {
                final otherName = widget.isPharmacy
                    ? chat.userName
                    : chat.pharmacyName;
                return otherName.toLowerCase().contains(_searchQuery);
              }).toList();
            }

            if (chats.isEmpty && _searchQuery.isNotEmpty) {
              return Center(
                child: Text(isAr ? 'لا توجد نتائج' : 'No results found'),
              );
            }

            return ListView.separated(
              itemCount: chats.length,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              separatorBuilder: (context, index) =>
                  const Divider(height: 1, indent: 70),
              itemBuilder: (context, index) {
                final chat = chats[index];
                final unreadCount = widget.isPharmacy
                    ? chat.pharmacyUnreadCount
                    : chat.userUnreadCount;
                final otherName = widget.isPharmacy
                    ? chat.userName
                    : chat.pharmacyName;
                final otherImageUrl = widget.isPharmacy
                    ? chat.userImageUrl
                    : chat.pharmacyImageUrl;

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  leading: Stack(
                    children: [
                      Hero(
                        tag: 'chat_avatar_${chat.id}',
                        child: CircleAvatar(
                          radius: 30,
                          backgroundColor: theme.colorScheme.primary
                              .withOpacity(0.1),
                          backgroundImage: otherImageUrl != null
                              ? NetworkImage(otherImageUrl)
                              : null,
                          child: otherImageUrl == null
                              ? Icon(
                                  widget.isPharmacy
                                      ? Icons.person
                                      : Icons.local_pharmacy,
                                  color: theme.colorScheme.primary,
                                  size: 30,
                                )
                              : null,
                        ),
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: theme.colorScheme.surface,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          otherName,
                          style: TextStyle(
                            fontWeight: unreadCount > 0
                                ? FontWeight.w900
                                : FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        _formatTime(chat.lastMessageTime),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: unreadCount > 0
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant,
                          fontWeight: unreadCount > 0
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            chat.lastMessage.isEmpty
                                ? (isAr
                                      ? 'ابدأ المحادثة...'
                                      : 'Start chatting...')
                                : chat.lastMessage,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: unreadCount > 0
                                  ? theme.colorScheme.onSurface
                                  : theme.colorScheme.onSurfaceVariant,
                              fontWeight: unreadCount > 0
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (unreadCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              unreadCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatDetailScreen(
                          chatId: chat.id,
                          otherName: otherName,
                          otherId: widget.isPharmacy
                              ? chat.userId
                              : chat.pharmacyId,
                          isPharmacy: widget.isPharmacy,
                          otherImageUrl: otherImageUrl,
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return DateFormat('hh:mm a').format(dateTime);
    } else if (difference.inDays == 1) {
      return Localizations.localeOf(context).languageCode == 'ar'
          ? 'أمس'
          : 'Yesterday';
    } else if (difference.inDays < 7) {
      return DateFormat('EEEE').format(dateTime);
    } else {
      return DateFormat('dd/MM/yyyy').format(dateTime);
    }
  }
}
