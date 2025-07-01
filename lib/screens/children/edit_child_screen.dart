import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/child_model.dart';
import '../../providers/auth_provider.dart';
import '../../core/themes/app_theme.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/cached_image.dart';
import '../../core/services/logger_service.dart';
import '../../core/constants/app_colors.dart';

class EditChildScreen extends ConsumerStatefulWidget {
  final String childId;

  const EditChildScreen({super.key, required this.childId});

  @override
  ConsumerState<EditChildScreen> createState() => _EditChildScreenState();
}

class _EditChildScreenState extends ConsumerState<EditChildScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _medicalHistoryController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime? _selectedDate;
  Gender _selectedGender = Gender.male;
  File? _selectedImage;
  bool _isLoading = false;
  bool _isDeleting = false;
  ChildModel? _child;

  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadChildData();
    LoggerService.userAction('edit_child_screen_opened',
        parameters: {'child_id': widget.childId});
  }

  @override
  void dispose() {
    _nameController.dispose();
    _allergiesController.dispose();
    _medicalHistoryController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _loadChildData() {
    final authState = ref.read(authControllerProvider);
    final appUser = authState.userData;
    if (appUser?.children != null) {
      _child = appUser!.children.firstWhere(
        (child) => child.id == widget.childId,
        orElse: () => throw Exception('Child not found'),
      );

      // Populate form fields
      _nameController.text = _child!.name;
      _selectedDate = _child!.dateOfBirth;
      _selectedGender = _child!.gender;
      _allergiesController.text = _child!.allergies?.join(', ') ?? '';
      _medicalHistoryController.text = _child!.medicalHistory?.join(', ') ?? '';
      _notesController.text = _child!.notes ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_child == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Child')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          _child!.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _showDeleteConfirmation,
            icon: const Icon(Icons.delete, color: Colors.red),
          ),
          TextButton(
            onPressed: _isLoading ? null : _updateChild,
            child: Text(
              'Save',
              style: TextStyle(
                color: _isLoading ? Colors.grey : AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Photo Section
                    _buildPhotoSection(),
                    const SizedBox(height: 24),

                    // Quick Actions
                    _buildQuickActions(),
                    const SizedBox(height: 24),

                    // Basic Information
                    _buildSectionHeader('Basic Information'),
                    const SizedBox(height: 16),

                    CustomTextField(
                      controller: _nameController,
                      label: 'Child\'s Name',
                      hint: 'Enter full name',
                      prefixIcon: Icons.person,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter child\'s name';
                        }
                        if (value.trim().length < 2) {
                          return 'Name must be at least 2 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: _buildDateSelector(),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildGenderSelector(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Age Display
                    _buildAgeDisplay(),
                    const SizedBox(height: 24),

                    // Medical Information
                    _buildSectionHeader('Medical Information'),
                    const SizedBox(height: 16),

                    CustomTextField(
                      controller: _allergiesController,
                      label: 'Allergies',
                      hint: 'List any known allergies',
                      prefixIcon: Icons.warning_amber,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),

                    CustomTextField(
                      controller: _medicalHistoryController,
                      label: 'Medical History',
                      hint: 'Previous illnesses, surgeries, etc.',
                      prefixIcon: Icons.medical_services,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),

                    CustomTextField(
                      controller: _notesController,
                      label: 'Additional Notes',
                      hint: 'Any other important information',
                      prefixIcon: Icons.note,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 24),

                    // Child Created Date
                    _buildChildInfo(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),

            // Update Button
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: CustomButton(
                  text: 'Update Child',
                  onPressed: _isLoading ? null : _updateChild,
                  isLoading: _isLoading,
                  icon: Icons.save,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoSection() {
    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: _selectImage,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[100],
                border: Border.all(
                  color: Colors.grey[300]!,
                  width: 2,
                ),
              ),
              child: _selectedImage != null
                  ? ClipOval(
                      child: Image.file(
                        _selectedImage!,
                        width: 120,
                        height: 120,
                        fit: BoxFit.cover,
                      ),
                    )
                  : _child!.photoUrl != null
                      ? CachedAvatar(
                          imageUrl: _child!.photoUrl!,
                          radius: 60,
                        )
                      : Container(
                          decoration: BoxDecoration(
                            color: _getGenderColor(_child!.gender)
                                .withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _child!.gender == Gender.male
                                ? Icons.boy
                                : Icons.girl,
                            size: 60,
                            color: _getGenderColor(_child!.gender),
                          ),
                        ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: _selectImage,
            icon: const Icon(Icons.photo_camera, size: 18),
            label: const Text('Change Photo'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _buildActionCard(
            icon: Icons.video_call,
            title: 'Book Consultation',
            subtitle: 'Schedule with doctor',
            color: Colors.blue,
            onTap: () => _bookConsultation(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionCard(
            icon: Icons.history,
            title: 'Medical History',
            subtitle: 'View past consultations',
            color: Colors.green,
            onTap: () => _viewHistory(),
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildDateSelector() {
    return InkWell(
      onTap: _selectDate,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: Colors.grey[600], size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Date of Birth',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _selectedDate != null
                        ? _formatDate(_selectedDate!)
                        : 'Select date',
                    style: TextStyle(
                      fontSize: 16,
                      color: _selectedDate != null
                          ? Colors.black87
                          : Colors.grey[400],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Gender',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: _buildGenderOption(Gender.male, 'Boy', Icons.boy),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildGenderOption(Gender.female, 'Girl', Icons.girl),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGenderOption(Gender gender, String label, IconData icon) {
    final isSelected = _selectedGender == gender;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedGender = gender;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : null,
          borderRadius: BorderRadius.circular(8),
          border: isSelected ? Border.all(color: AppColors.primary) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? AppColors.primary : Colors.grey[600],
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isSelected ? AppColors.primary : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgeDisplay() {
    if (_selectedDate == null) return const SizedBox.shrink();

    final age = _calculateAge(_selectedDate!);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.cake, color: Colors.blue[600], size: 20),
          const SizedBox(width: 12),
          Text(
            'Current Age: $age ${age == 1 ? 'year' : 'years'} old',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.blue[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChildInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Child Information',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          _buildInfoRow('Child ID', _child!.id),
          _buildInfoRow('Added on', _formatDate(_child!.createdAt)),
          _buildInfoRow('Last updated',
              _formatDate(_child!.updatedAt ?? _child!.createdAt)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getGenderColor(Gender gender) {
    switch (gender) {
      case Gender.male:
        return Colors.blue;
      case Gender.female:
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  int _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  Future<void> _selectImage() async {
    try {
      final ImageSource? source = await _showImageSourceDialog();
      if (source == null) return;

      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
        LoggerService.userAction('child_photo_updated',
            parameters: {'child_id': widget.childId});
      }
    } catch (e) {
      LoggerService.error('Error selecting image', e);
      _showErrorDialog('Failed to select image. Please try again.');
    }
  }

  Future<ImageSource?> _showImageSourceDialog() async {
    return showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Photo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate:
          _selectedDate ?? DateTime.now().subtract(const Duration(days: 365)),
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
      LoggerService.userAction('child_birth_date_updated',
          parameters: {'child_id': widget.childId});
    }
  }

  Future<void> _updateChild() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedDate == null) {
      _showErrorDialog('Please select a date of birth.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Create updated child model
      final updatedChild = _child!.copyWith(
        name: _nameController.text.trim(),
        dateOfBirth: _selectedDate!,
        gender: _selectedGender,
        bloodGroup: _child!.bloodGroup,
        height: _child!.height,
        weight: _child!.weight,
        allergies: _allergiesController.text.trim().isNotEmpty
            ? [_allergiesController.text.trim()]
            : [],
        chronicConditions: _child!.chronicConditions,
        photoUrl: _child!.photoUrl,
      );

      // Update child in user's children list
      await ref.read(authProvider.notifier).updateChild(updatedChild);

      LoggerService.userAction('child_updated_successfully', parameters: {
        'child_id': widget.childId,
        'child_name': updatedChild.name,
      });

      // Show success and navigate back
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('${updatedChild.name}\'s information has been updated!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pop();
      }
    } catch (e) {
      LoggerService.error('Error updating child', e);
      _showErrorDialog('Failed to update child. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showDeleteConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${_child!.name}'),
        content: Text(
          'Are you sure you want to delete ${_child!.name}\'s profile? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteChild();
    }
  }

  Future<void> _deleteChild() async {
    setState(() {
      _isDeleting = true;
    });

    try {
      await ref.read(authProvider.notifier).removeChild(widget.childId);

      LoggerService.userAction('child_deleted_successfully', parameters: {
        'child_id': widget.childId,
        'child_name': _child!.name,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_child!.name} has been deleted'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pop();
      }
    } catch (e) {
      LoggerService.error('Error deleting child', e);
      _showErrorDialog('Failed to delete child. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  void _bookConsultation() {
    LoggerService.userAction('book_consultation_from_edit',
        parameters: {'child_id': widget.childId});
    context.push('/consultation/book', extra: _child);
  }

  void _viewHistory() {
    LoggerService.userAction('view_history_from_edit',
        parameters: {'child_id': widget.childId});
    context.push('/consultation/history', extra: _child);
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
