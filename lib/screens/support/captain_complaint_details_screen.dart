import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../models/firestore_models.dart';
import '../../services/captain_state_service.dart';

class CaptainComplaintDetailsScreen extends StatefulWidget {
  final FirestoreComplaintModel complaint;

  const CaptainComplaintDetailsScreen({
    super.key,
    required this.complaint,
  });

  @override
  State<CaptainComplaintDetailsScreen> createState() => _CaptainComplaintDetailsScreenState();
}

class _CaptainComplaintDetailsScreenState extends State<CaptainComplaintDetailsScreen> {
  final _replyController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSendingReply = false;

  @override
  void dispose() {
    _replyController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleSendReply() async {
    final text = _replyController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSendingReply = true);
    _replyController.clear();

    try {
      await CaptainStateService().sendComplaintReply(
        complaintId: widget.complaint.complaintId,
        message: text,
      );

      // Scroll to bottom after a short delay
      await Future.delayed(const Duration(milliseconds: 200));
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send reply: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSendingReply = false);
      }
    }
  }

  void _showImageZoom(String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            Center(
              child: InteractiveViewer(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Center(
                    child: Text('Unable to load full image', style: TextStyle(color: Colors.white70)),
                  ),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final complaint = widget.complaint;
    final isClosed = complaint.status.toUpperCase() == 'CLOSED';
    final isResolved = complaint.status.toUpperCase() == 'RESOLVED';
    final stateService = CaptainStateService();

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimaryDark),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Ticket #${complaint.complaintId}',
          style: const TextStyle(
            color: AppColors.textPrimaryDark,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.all(AppDimensions.space16),
              children: [
                // Ticket Overview Card
                _buildOverviewCard(complaint),
                const SizedBox(height: AppDimensions.space16),

                // Description Card
                _buildDescriptionCard(complaint),
                const SizedBox(height: AppDimensions.space16),

                // Linked Ride (if present)
                if (complaint.rideId != null && complaint.rideId!.isNotEmpty) ...[
                  _buildLinkedRideCard(complaint.rideId!),
                  const SizedBox(height: AppDimensions.space16),
                ],

                // Attachment (if present)
                if (complaint.attachmentUrl != null && complaint.attachmentUrl!.isNotEmpty) ...[
                  _buildAttachmentCard(complaint.attachmentUrl!),
                  const SizedBox(height: AppDimensions.space16),
                ],

                // Resolution Summary (if resolved or closed with resolution)
                if ((isResolved || isClosed) &&
                    ((complaint.resolutionSummary != null && complaint.resolutionSummary!.isNotEmpty) ||
                        (complaint.adminNotes != null && complaint.adminNotes!.isNotEmpty))) ...[
                  _buildResolutionCard(complaint),
                  const SizedBox(height: AppDimensions.space16),
                ],

                // Conversation Header
                const Text(
                  'Support Conversation',
                  style: TextStyle(
                    color: AppColors.textPrimaryDark,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),

                // Replies Thread
                StreamBuilder<List<FirestoreComplaintReplyModel>>(
                  stream: stateService.streamComplaintReplies(complaint.complaintId),
                  builder: (context, snapshot) {
                    final replies = snapshot.data ?? [];

                    if (replies.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceDark,
                          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                          border: Border.all(color: AppColors.borderDark),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 36,
                              color: AppColors.textSecondaryDark.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'No responses yet',
                              style: TextStyle(
                                color: AppColors.textPrimaryDark,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Our support team will review your ticket and reply shortly.',
                              style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 11.5),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }

                    return Column(
                      children: replies.map(_buildReplyBubble).toList(),
                    );
                  },
                ),
                const SizedBox(height: AppDimensions.space20),
              ],
            ),
          ),

          // Reply Composer Bar
          _buildComposerBar(isClosed),
        ],
      ),
    );
  }

  Widget _buildOverviewCard(FirestoreComplaintModel complaint) {
    final statusColor = _getStatusColor(complaint.status);
    final priorityColor = _getPriorityColor(complaint.priority);

    return Container(
      padding: const EdgeInsets.all(AppDimensions.space16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  complaint.category,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      color: priorityColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: priorityColor.withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      complaint.priority,
                      style: TextStyle(
                        color: priorityColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      complaint.statusLabel,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            complaint.subject,
            style: const TextStyle(
              color: AppColors.textPrimaryDark,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Submitted on ${_formatDate(complaint.createdAt)}',
            style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard(FirestoreComplaintModel complaint) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.space16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DESCRIPTION',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            complaint.description,
            style: const TextStyle(
              color: AppColors.textPrimaryDark,
              fontSize: 13.5,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkedRideCard(String rideId) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.space14),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.two_wheeler_rounded, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Associated Trip',
                  style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 11),
                ),
                const SizedBox(height: 2),
                Text(
                  'Ride #$rideId',
                  style: const TextStyle(
                    color: AppColors.textPrimaryDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.check_circle_rounded, color: AppColors.onlineGreen, size: 18),
        ],
      ),
    );
  }

  Widget _buildAttachmentCard(String attachmentUrl) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.space14),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ATTACHED PHOTO EVIDENCE',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => _showImageZoom(attachmentUrl),
            child: Stack(
              alignment: Alignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                  child: Image.network(
                    attachmentUrl,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, stack) => Container(
                      height: 120,
                      color: AppColors.surfaceElevatedDark,
                      child: const Center(
                        child: Text(
                          'Photo evidence attached (offline placeholder)',
                          style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 12),
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.zoom_in_rounded, color: Colors.white, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'Tap to zoom',
                        style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResolutionCard(FirestoreComplaintModel complaint) {
    final text = (complaint.resolutionSummary != null && complaint.resolutionSummary!.isNotEmpty)
        ? complaint.resolutionSummary!
        : (complaint.adminNotes ?? 'Ticket resolved.');

    return Container(
      padding: const EdgeInsets.all(AppDimensions.space16),
      decoration: BoxDecoration(
        color: AppColors.onlineGreen.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(color: AppColors.onlineGreen.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: AppColors.onlineGreen, size: 20),
              SizedBox(width: 8),
              Text(
                'Admin Resolution Summary',
                style: TextStyle(
                  color: AppColors.onlineGreen,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: const TextStyle(
              color: AppColors.textPrimaryDark,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          if (complaint.resolvedAt != null) ...[
            const SizedBox(height: 8),
            Text(
              'Resolved on ${_formatDate(complaint.resolvedAt!)}',
              style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReplyBubble(FirestoreComplaintReplyModel reply) {
    final isAdmin = reply.senderRole.toUpperCase() == 'ADMIN';

    return Align(
      alignment: isAdmin ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isAdmin
              ? AppColors.surfaceElevatedDark
              : AppColors.primary.withValues(alpha: 0.18),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: Radius.circular(isAdmin ? 2 : 12),
            bottomRight: Radius.circular(isAdmin ? 12 : 2),
          ),
          border: Border.all(
            color: isAdmin ? AppColors.borderDark : AppColors.primary.withValues(alpha: 0.4),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isAdmin) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: const Text(
                      'SUPPORT',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
                Text(
                  isAdmin ? 'QuickRide Desk (${reply.senderName})' : 'You (Captain)',
                  style: TextStyle(
                    color: isAdmin ? AppColors.primary : AppColors.textPrimaryDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              reply.message,
              style: const TextStyle(
                color: AppColors.textPrimaryDark,
                fontSize: 13,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(reply.createdAt),
              style: const TextStyle(
                color: AppColors.textSecondaryDark,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComposerBar(bool isClosed) {
    if (isClosed) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        color: AppColors.surfaceDark,
        child: const Center(
          child: Text(
            'This complaint has been closed. You cannot add new replies.',
            style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 12),
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 8,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceDark,
        border: Border(top: BorderSide(color: AppColors.borderDark)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _replyController,
                style: const TextStyle(color: AppColors.textPrimaryDark, fontSize: 13.5),
                decoration: InputDecoration(
                  hintText: 'Type a message to support...',
                  hintStyle: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 13),
                  filled: true,
                  fillColor: AppColors.surfaceElevatedDark,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => _handleSendReply(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: _isSendingReply
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded, color: AppColors.primary),
              onPressed: _isSendingReply ? null : _handleSendReply,
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'OPEN':
        return Colors.orange;
      case 'IN_REVIEW':
        return Colors.blue;
      case 'RESOLVED':
        return AppColors.onlineGreen;
      case 'CLOSED':
        return Colors.grey;
      default:
        return AppColors.primary;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toUpperCase()) {
      case 'URGENT':
        return AppColors.error;
      case 'HIGH':
        return Colors.deepOrange;
      case 'NORMAL':
        return AppColors.primary;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} at ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
