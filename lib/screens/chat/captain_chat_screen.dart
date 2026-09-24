import 'package:flutter/material.dart';
import '../../models/firestore_models.dart';
import '../../services/captain_chat_service.dart';
import '../../widgets/captain_offline_banner.dart';

/// Real-time chat screen for Captains communicating with passengers during active trips.
class CaptainChatScreen extends StatefulWidget {
  final String rideId;
  final String currentCaptainId;
  final String currentCaptainName;
  final String passengerId;
  final String passengerName;
  final String passengerPhone;
  final String pickupAddress;
  final String dropAddress;
  final String? rideStatus; // 'ACCEPTED', 'ARRIVED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED'

  const CaptainChatScreen({
    super.key,
    required this.rideId,
    required this.currentCaptainId,
    this.currentCaptainName = 'Captain',
    required this.passengerId,
    this.passengerName = 'Passenger',
    this.passengerPhone = '',
    this.pickupAddress = '',
    this.dropAddress = '',
    this.rideStatus,
  });

  @override
  State<CaptainChatScreen> createState() => _CaptainChatScreenState();
}

class _CaptainChatScreenState extends State<CaptainChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final CaptainChatService _chatService = CaptainChatService();
  bool _isSending = false;

  static const List<String> _quickResponses = [
    "I have arrived at your pickup point",
    "I'm on the way, arriving in 2 mins",
    "I'm near the main gate / landmark",
    "Please come out to the vehicle",
    "Stuck in traffic, arriving shortly",
    "Okay, acknowledged!",
  ];

  bool get _isChatClosed {
    final status = widget.rideStatus?.toUpperCase().replaceAll(' ', '_');
    return status == 'COMPLETED' || status == 'CANCELLED';
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSendMessage([String? predefinedText]) async {
    final text = predefinedText ?? _messageController.text;
    final trimmed = text.trim();

    if (trimmed.isEmpty || _isSending || _isChatClosed) return;

    if (trimmed.length > 500) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message cannot exceed 500 characters.')),
      );
      return;
    }

    setState(() => _isSending = true);
    if (predefinedText == null) {
      _messageController.clear();
    }

    final success = await _chatService.sendMessage(
      rideId: widget.rideId,
      senderId: widget.currentCaptainId,
      senderName: widget.currentCaptainName,
      senderRole: 'CAPTAIN',
      message: trimmed,
      rideStatus: widget.rideStatus,
    );

    if (mounted) {
      setState(() => _isSending = false);
      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send message. Please try again.')),
        );
      } else {
        _scrollToBottom();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryYellow = Color(0xFFFFC700);
    const bgDark = Color(0xFF0D131F);
    const surfaceDark = Color(0xFF162032);
    const surfaceElevated = Color(0xFF1E2C44);
    const borderDark = Color(0xFF283953);

    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        backgroundColor: surfaceDark,
        elevation: 1,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: primaryYellow.withValues(alpha: 0.2),
              child: const Icon(Icons.person_outline_rounded, color: primaryYellow, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.passengerName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    widget.pickupAddress.isNotEmpty
                        ? 'Pickup: ${widget.pickupAddress}'
                        : 'Passenger on Ride',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF94A3B8),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (widget.passengerPhone.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.call_rounded, color: primaryYellow),
              tooltip: 'Call Passenger',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Calling ${widget.passengerName} (${widget.passengerPhone})...')),
                );
              },
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const CaptainOfflineBanner(),
            // Status banner if ride completed / cancelled
            if (_isChatClosed)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                color: Colors.amber.shade900.withValues(alpha: 0.3),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: primaryYellow, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Ride is ${widget.rideStatus ?? 'closed'}. Chat messaging is disabled.',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Messages Stream List
            Expanded(
              child: StreamBuilder<List<FirestoreChatMessageModel>>(
                stream: _chatService.streamMessages(widget.rideId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(color: primaryYellow),
                    );
                  }

                  final messages = snapshot.data ?? [];

                  // Auto mark unread messages as read
                  if (messages.isNotEmpty) {
                    _chatService.markAllReceivedAsRead(
                      rideId: widget.rideId,
                      currentCaptainId: widget.currentCaptainId,
                      messages: messages,
                    );
                  }

                  if (messages.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: const BoxDecoration(
                                color: surfaceElevated,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.chat_rounded,
                                color: Color(0xFF00E5FF),
                                size: 36,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Chat with Passenger',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Send quick arrival updates or confirm pickup details.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final isMe = msg.senderId == widget.currentCaptainId;
                      return _buildMessageBubble(msg, isMe);
                    },
                  );
                },
              ),
            ),

            // Quick Response Chips (shown only when chat is active)
            if (!_isChatClosed)
              Container(
                height: 42,
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _quickResponses.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final responseText = _quickResponses[index];
                    return ActionChip(
                      label: Text(
                        responseText,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                        ),
                      ),
                      backgroundColor: surfaceElevated,
                      side: const BorderSide(color: borderDark),
                      onPressed: () => _handleSendMessage(responseText),
                    );
                  },
                ),
              ),

            // Input bar
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(FirestoreChatMessageModel msg, bool isMe) {
    const primaryYellow = Color(0xFFFFC700);
    const surfaceElevated = Color(0xFF1E2C44);
    const borderDark = Color(0xFF283953);
    final timeStr = '${msg.createdAt.hour.toString().padLeft(2, '0')}:${msg.createdAt.minute.toString().padLeft(2, '0')}';

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? primaryYellow.withValues(alpha: 0.92) : surfaceElevated,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          border: Border.all(
            color: isMe ? primaryYellow : borderDark,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMe && msg.senderName.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  msg.senderName,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00E5FF),
                  ),
                ),
              ),
            Text(
              msg.message,
              style: TextStyle(
                fontSize: 14,
                color: isMe ? const Color(0xFF0F172A) : Colors.white,
                fontWeight: isMe ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  timeStr,
                  style: TextStyle(
                    fontSize: 10,
                    color: isMe ? const Color(0xFF334155) : const Color(0xFF94A3B8),
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    msg.read ? Icons.done_all_rounded : Icons.check_rounded,
                    size: 13,
                    color: msg.read ? const Color(0xFF0F172A) : const Color(0xFF475569),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    const primaryYellow = Color(0xFFFFC700);
    const surfaceDark = Color(0xFF162032);
    const surfaceElevated = Color(0xFF1E2C44);
    const borderDark = Color(0xFF283953);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: surfaceDark,
        border: Border(top: BorderSide(color: borderDark)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              focusNode: _focusNode,
              enabled: !_isChatClosed && !_isSending,
              maxLength: 500,
              buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: _isChatClosed ? 'Chat is closed' : 'Message passenger...',
                hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
                filled: true,
                fillColor: surfaceElevated,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: borderDark),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: borderDark),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: primaryYellow, width: 1.5),
                ),
              ),
              onSubmitted: (_) => _handleSendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: (_isChatClosed || _isSending) ? null : () => _handleSendMessage(),
            icon: _isSending
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: primaryYellow),
                  )
                : const Icon(Icons.send_rounded),
            color: primaryYellow,
            disabledColor: const Color(0xFF64748B).withValues(alpha: 0.4),
            style: IconButton.styleFrom(
              backgroundColor: surfaceElevated,
              padding: const EdgeInsets.all(10),
            ),
          ),
        ],
      ),
    );
  }
}
