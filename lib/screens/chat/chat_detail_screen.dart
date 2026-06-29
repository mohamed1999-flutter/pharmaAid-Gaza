import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../core/models/chat_models.dart';
import '../../core/service/auth_service.dart';
import '../../core/service/firestore_service.dart';

class ChatDetailScreen extends StatefulWidget {
  final String chatId;
  final String otherName;
  final String otherId;
  final bool isPharmacy;
  final String? otherImageUrl;
  final String? initialMessage;

  const ChatDetailScreen({
    super.key,
    required this.chatId,
    required this.otherName,
    required this.otherId,
    required this.isPharmacy,
    this.otherImageUrl,
    this.initialMessage,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String get _uid => AuthService.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _markAsRead();
    if (widget.initialMessage != null && widget.initialMessage!.isNotEmpty) {
      _messageController.text = widget.initialMessage!;
    }
  }

  void _markAsRead() {
    if (_uid.isEmpty) return;
    FirestoreService.markChatAsRead(
      chatId: widget.chatId,
      isPharmacy: widget.isPharmacy,
      uid: _uid,
    );
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty || _uid.isEmpty) return;

    FirestoreService.sendMessage(
      chatId: widget.chatId,
      senderId: _uid,
      receiverId: widget.otherId,
      text: text,
      isPharmacySender: widget.isPharmacy,
    );

    _messageController.clear();
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final theme = Theme.of(context);

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Hero(
                tag: 'chat_avatar_${widget.chatId}',
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  backgroundImage: widget.otherImageUrl != null
                      ? NetworkImage(widget.otherImageUrl!)
                      : null,
                  child: widget.otherImageUrl == null
                      ? Icon(
                          widget.isPharmacy
                              ? Icons.person
                              : Icons.local_pharmacy,
                          size: 20,
                          color: theme.colorScheme.onPrimaryContainer,
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.otherName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          elevation: 1,
        ),
        body: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirestoreService.chatMessagesStream(widget.chatId),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    debugPrint('--- CHAT DETAIL ERROR ---');
                    debugPrint('Error: ${snapshot.error}');
                    debugPrint('Stacktrace: ${snapshot.stackTrace}');
                    return Center(
                      child: Text(
                        isAr
                            ? 'حدث خطأ ما فى الرسائل'
                            : 'Error loading messages',
                      ),
                    );
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final messages =
                      snapshot.data?.docs
                          .map(
                            (doc) =>
                                ChatMessageModel.fromMap(doc.id, doc.data()),
                          )
                          .toList() ??
                      [];

                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 20,
                    ),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isMe = message.senderId == _uid;

                      bool showDateHeader = false;
                      if (index == messages.length - 1) {
                        showDateHeader = true;
                      } else {
                        final nextMessage = messages[index + 1];
                        if (message.timestamp.day !=
                                nextMessage.timestamp.day ||
                            message.timestamp.month !=
                                nextMessage.timestamp.month ||
                            message.timestamp.year !=
                                nextMessage.timestamp.year) {
                          showDateHeader = true;
                        }
                      }

                      return Column(
                        children: [
                          if (showDateHeader)
                            _DateHeader(
                              date: message.timestamp,
                              isAr: isAr,
                              theme: theme,
                            ),
                          _ChatBubble(
                            message: message,
                            isMe: isMe,
                            theme: theme,
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
            _buildMessageInput(theme, isAr),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput(ThemeData theme, bool isAr) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withOpacity(
                    0.5,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: isAr ? 'اكتب رسالة...' : 'Type a message...',
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  maxLines: 4,
                  minLines: 1,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: _sendMessage,
              icon: const Icon(Icons.send_rounded),
              style: IconButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateHeader extends StatelessWidget {
  final DateTime date;
  final bool isAr;
  final ThemeData theme;

  const _DateHeader({
    required this.date,
    required this.isAr,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    String dateText;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      dateText = isAr ? 'اليوم' : 'Today';
    } else if (messageDate == yesterday) {
      dateText = isAr ? 'أمس' : 'Yesterday';
    } else {
      dateText = DateFormat('dd MMMM yyyy').format(date);
    }

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 20),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          dateText,
          style: TextStyle(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatMessageModel message;
  final bool isMe;
  final ThemeData theme;

  const _ChatBubble({
    required this.message,
    required this.isMe,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = theme.colorScheme;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isMe
              ? colorScheme.primary
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isMe ? 20 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(
                color: isMe ? colorScheme.onPrimary : colorScheme.onSurface,
                fontSize: 15,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat('hh:mm a').format(message.timestamp),
                  style: TextStyle(
                    color:
                        (isMe
                                ? colorScheme.onPrimary
                                : colorScheme.onSurfaceVariant)
                            .withOpacity(0.7),
                    fontSize: 10,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    message.isRead
                        ? Icons.done_all_rounded
                        : Icons.done_rounded,
                    size: 14,
                    color: colorScheme.onPrimary.withOpacity(0.8),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
