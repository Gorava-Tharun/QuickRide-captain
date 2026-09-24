import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../services/captain_state_service.dart';
import '../../services/captain_storage_service.dart';
import 'captain_complaint_details_screen.dart';

class CaptainCreateComplaintScreen extends StatefulWidget {
  final String? preselectedRideId;

  const CaptainCreateComplaintScreen({
    super.key,
    this.preselectedRideId,
  });

  @override
  State<CaptainCreateComplaintScreen> createState() => _CaptainCreateComplaintScreenState();
}

class _CaptainCreateComplaintScreenState extends State<CaptainCreateComplaintScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();

  String _selectedCategory = 'PAYMENT';
  String _selectedPriority = 'NORMAL';
  String? _selectedRideId;
  String? _selectedSubject;
  bool _isSubmitting = false;

  XFile? _attachedImage;
  double _uploadProgress = 0.0;
  bool _isUploadingAttachment = false;

  final Map<String, String> _categories = const {
    'PAYMENT': 'Fare / Settlement Dispute',
    'RIDER_ISSUE': 'Rider Misconduct / Damage',
    'CANCELLATION': 'Cancellation Fee Issue',
    'NAVIGATION': 'Navigation / Route Issue',
    'APP_ISSUE': 'App / Technical Bug',
    'SAFETY': 'Safety & Security Incident',
    'OTHER': 'Other Query / Feedback',
  };

  final Map<String, List<String>> _categorySubjects = const {
    'PAYMENT': [
      'Weekly incentive bonus missing',
      'Incorrect ride fare settled',
      'UPI instant withdrawal failed',
      'Cash collected dispute',
      'Toll / Parking reimbursement',
      'Other payment issue',
    ],
    'RIDER_ISSUE': [
      'Rider damaged vehicle interior/seat',
      'Rider refusal to pay cash fare',
      'Verbal abuse or harassment',
      'Intoxicated / unruly passenger',
      'Excess baggage / overloading',
      'Other passenger issue',
    ],
    'CANCELLATION': [
      'Passenger cancelled after arrival (No fee paid)',
      'Passenger was unreachable at pickup',
      'Captain cancellation penalty appeal',
      'Other cancellation dispute',
    ],
    'NAVIGATION': [
      'Pickup location placed in non-drivable zone',
      'Destination dropped pin inaccurate',
      'App map routing suggested blocked road',
      'Other navigation issue',
    ],
    'APP_ISSUE': [
      'Duty toggle button unresponsive',
      'Ride request modal froze or crashed',
      'GPS location lagging during ride',
      'Other technical issue',
    ],
    'SAFETY': [
      'Physical altercation or threat',
      'Accident / collision during trip',
      'Emergency medical situation',
      'Route detour safety risk',
      'Other safety concern',
    ],
    'OTHER': [
      'Captain rating dispute',
      'Profile document update query',
      'General captain support inquiry',
      'Other topic',
    ],
  };

  @override
  void initState() {
    super.initState();
    _selectedRideId = widget.preselectedRideId;
    _updateSubjectForCategory(_selectedCategory);
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _updateSubjectForCategory(String category) {
    final list = _categorySubjects[category] ?? ['General issue'];
    _selectedSubject = list.first;
    if (category == 'SAFETY') {
      _selectedPriority = 'HIGH';
    } else if (_selectedPriority == 'HIGH' && category != 'SAFETY') {
      _selectedPriority = 'NORMAL';
    }
  }

  Future<void> _pickAttachment(ImageSource source) async {
    final image = await CaptainStorageService().pickImage(source: source);
    if (image != null && mounted) {
      setState(() => _attachedImage = image);
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final stateService = CaptainStateService();
      String? attachmentUrl;

      if (_attachedImage != null) {
        setState(() => _isUploadingAttachment = true);
        final tempId = 'CPT-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
        final uploadResult = await CaptainStorageService().uploadComplaintAttachment(
          captainId: stateService.account.id,
          complaintId: tempId,
          file: _attachedImage!,
          onProgress: (p) {
            if (mounted) setState(() => _uploadProgress = p);
          },
        );
        if (uploadResult.success) {
          attachmentUrl = uploadResult.downloadUrl;
        }
      }

      final complaint = await stateService.createComplaint(
        category: _selectedCategory,
        subject: _selectedSubject ?? 'Complaint',
        description: _descriptionController.text.trim(),
        rideId: _selectedRideId,
        priority: _selectedPriority,
        attachmentUrl: attachmentUrl,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ticket #${complaint.complaintId} submitted successfully.'),
          backgroundColor: AppColors.onlineGreen,
        ),
      );

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => CaptainComplaintDetailsScreen(complaint: complaint),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit ticket: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _isUploadingAttachment = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final stateService = CaptainStateService();
    final completedRides = stateService.completedRides;
    final subjects = _categorySubjects[_selectedCategory] ?? ['General issue'];

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimaryDark),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'File Captain Complaint',
          style: TextStyle(
            color: AppColors.textPrimaryDark,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppDimensions.space16),
          children: [
            // Category Dropdown
            _buildSectionHeader('COMPLAINT CATEGORY'),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                border: Border.all(color: AppColors.borderDark),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCategory,
                  dropdownColor: AppColors.surfaceDark,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary),
                  isExpanded: true,
                  items: _categories.entries.map((entry) {
                    return DropdownMenuItem<String>(
                      value: entry.key,
                      child: Text(
                        entry.value,
                        style: const TextStyle(
                          color: AppColors.textPrimaryDark,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedCategory = val;
                        _updateSubjectForCategory(val);
                      });
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.space16),

            // Priority Level
            _buildSectionHeader('PRIORITY LEVEL'),
            const SizedBox(height: 6),
            Row(
              children: ['LOW', 'NORMAL', 'HIGH', 'URGENT'].map((p) {
                final isSelected = _selectedPriority == p;
                final isSafetyForced = _selectedCategory == 'SAFETY' && (p == 'LOW' || p == 'NORMAL');
                final color = _getPriorityColor(p);

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: OutlinedButton(
                      onPressed: isSafetyForced ? null : () => setState(() => _selectedPriority = p),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        backgroundColor: isSelected ? color.withValues(alpha: 0.15) : AppColors.surfaceDark,
                        side: BorderSide(
                          color: isSelected ? color : AppColors.borderDark,
                          width: isSelected ? 1.5 : 1.0,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                        ),
                      ),
                      child: Text(
                        p,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected ? color : AppColors.textSecondaryDark,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            if (_selectedCategory == 'SAFETY') ...[
              const SizedBox(height: 6),
              const Row(
                children: [
                  Icon(Icons.shield_rounded, size: 14, color: AppColors.error),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Safety incident complaints are automatically marked High/Urgent priority.',
                      style: TextStyle(color: AppColors.error, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: AppDimensions.space16),

            // Subject / Issue Type
            _buildSectionHeader('SPECIFIC ISSUE / SUBJECT'),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                border: Border.all(color: AppColors.borderDark),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedSubject,
                  dropdownColor: AppColors.surfaceDark,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary),
                  isExpanded: true,
                  items: subjects.map((subj) {
                    return DropdownMenuItem<String>(
                      value: subj,
                      child: Text(
                        subj,
                        style: const TextStyle(
                          color: AppColors.textPrimaryDark,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedSubject = val);
                  },
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.space16),

            // Associated Ride Selector (Optional)
            _buildSectionHeader('ASSOCIATED RIDE (OPTIONAL)'),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                border: Border.all(color: AppColors.borderDark),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String?>(
                  value: _selectedRideId,
                  dropdownColor: AppColors.surfaceDark,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary),
                  isExpanded: true,
                  hint: const Text(
                    'None / General Captain Query',
                    style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 13.5),
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text(
                        'None / General Captain Query',
                        style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 13.5),
                      ),
                    ),
                    ...completedRides.map((ride) {
                      return DropdownMenuItem<String?>(
                        value: ride.id,
                        child: Text(
                          '${ride.id} — ${ride.passengerName} (₹${ride.fare.toStringAsFixed(0)})',
                          style: const TextStyle(
                            color: AppColors.textPrimaryDark,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }),
                  ],
                  onChanged: (val) => setState(() => _selectedRideId = val),
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.space16),

            // Description Field
            _buildSectionHeader('DETAILED DESCRIPTION'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _descriptionController,
              maxLines: 5,
              maxLength: 500,
              style: const TextStyle(color: AppColors.textPrimaryDark, fontSize: 13.5),
              decoration: InputDecoration(
                hintText: 'Please describe exactly what occurred, including locations, times, or any evidence...',
                hintStyle: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 13),
                filled: true,
                fillColor: AppColors.surfaceDark,
                counterStyle: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 11),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                  borderSide: const BorderSide(color: AppColors.borderDark),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                  borderSide: const BorderSide(color: AppColors.borderDark),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Please provide details for your complaint.';
                }
                if (val.trim().length < 10) {
                  return 'Description must be at least 10 characters.';
                }
                return null;
              },
            ),
            const SizedBox(height: AppDimensions.space12),

            // Attachment Picker
            _buildSectionHeader('ATTACH PHOTO EVIDENCE (OPTIONAL)'),
            const SizedBox(height: 6),
            _buildAttachmentPicker(),
            const SizedBox(height: AppDimensions.space24),

            // Submit Button
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, AppDimensions.buttonHeight),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                ),
                elevation: 0,
              ),
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded),
              label: Text(
                _isSubmitting
                    ? (_isUploadingAttachment ? 'Uploading Attachment...' : 'Submitting Ticket...')
                    : 'Submit Captain Ticket',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
              ),
              onPressed: _isSubmitting ? null : _handleSubmit,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.primary,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildAttachmentPicker() {
    if (_attachedImage != null) {
      return Container(
        padding: const EdgeInsets.all(AppDimensions.space12),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          border: Border.all(color: AppColors.borderDark),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.surfaceElevatedDark,
                borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
              ),
              child: const Icon(Icons.image_rounded, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _attachedImage!.name,
                    style: const TextStyle(
                      color: AppColors.textPrimaryDark,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (_isUploadingAttachment) ...[
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: _uploadProgress > 0 ? _uploadProgress : null,
                      backgroundColor: AppColors.borderDark,
                      color: AppColors.primary,
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, color: AppColors.error),
              onPressed: () => setState(() => _attachedImage = null),
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              side: const BorderSide(color: AppColors.borderDark),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              ),
              backgroundColor: AppColors.surfaceDark,
            ),
            icon: const Icon(Icons.photo_library_rounded, color: AppColors.primary, size: 18),
            label: const Text(
              'Gallery',
              style: TextStyle(color: AppColors.textPrimaryDark, fontSize: 13, fontWeight: FontWeight.w600),
            ),
            onPressed: () => _pickAttachment(ImageSource.gallery),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              side: const BorderSide(color: AppColors.borderDark),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              ),
              backgroundColor: AppColors.surfaceDark,
            ),
            icon: const Icon(Icons.camera_alt_rounded, color: AppColors.primary, size: 18),
            label: const Text(
              'Take Photo',
              style: TextStyle(color: AppColors.textPrimaryDark, fontSize: 13, fontWeight: FontWeight.w600),
            ),
            onPressed: () => _pickAttachment(ImageSource.camera),
          ),
        ),
      ],
    );
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
}
