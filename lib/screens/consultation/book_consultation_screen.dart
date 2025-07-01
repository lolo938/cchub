import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../models/child_model.dart';
import '../../models/consultation_model.dart';
import '../../models/doctor_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/consultation_provider.dart';
import '../../providers/doctor_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';

class BookConsultationScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? extraData;

  const BookConsultationScreen({
    super.key,
    this.extraData,
  });

  @override
  ConsumerState<BookConsultationScreen> createState() =>
      _BookConsultationScreenState();
}

class _BookConsultationScreenState
    extends ConsumerState<BookConsultationScreen> {
  final _formKey = GlobalKey<FormState>();
  Child? _selectedChild;
  Doctor? _doctor;
  DateTime? _selectedDateTime;
  ConsultationType _selectedConsultationType = ConsultationType.instant;
  bool _isLoading = false;

  late TextEditingController _timeController;
  late TextEditingController _dateController;
  late TextEditingController _symptomsController;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    if (widget.extraData != null) {
      _doctor = widget.extraData!['doctor'] as Doctor?;
      _selectedChild = widget.extraData!['child'] as Child?;
    }

    final appUser = ref.read(authControllerProvider).userData;
    if (_selectedChild == null && appUser != null && appUser.children.isNotEmpty) {
      _selectedChild = appUser.children.first;
    }

    _timeController = TextEditingController();
    _dateController = TextEditingController();
    _symptomsController = TextEditingController();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _timeController.dispose();
    _dateController.dispose();
    _symptomsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).userData;
    final allDoctors = ref.watch(allDoctorsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Book Consultation')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (user != null) _buildChildSelection(user.children),
              const SizedBox(height: AppSizes.lg),
              allDoctors.when(
                data: (doctors) => _buildDoctorSelection(doctors),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, st) =>
                    const Center(child: Text('Could not load doctors')),
              ),
              const SizedBox(height: AppSizes.lg),
              _buildDateTimePicker(),
              const SizedBox(height: AppSizes.lg),
              _buildDetailsEntry(),
              const SizedBox(height: AppSizes.xl),
              CustomButton(
                text: 'Confirm & Pay',
                onPressed: _submitConsultation,
                isLoading: _isLoading,
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChildSelection(List<Child> children) {
    if (children.isEmpty) {
      return const Text('Please add a child in your profile first.');
    }
    return DropdownButtonFormField<Child>(
      value: _selectedChild,
      onChanged: (Child? newValue) {
        setState(() {
          _selectedChild = newValue;
        });
      },
      items: children.map<DropdownMenuItem<Child>>((Child child) {
        return DropdownMenuItem<Child>(
          value: child,
          child: Text(child.name),
        );
      }).toList(),
      decoration: const InputDecoration(
        labelText: 'Select Child',
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildDoctorSelection(List<Doctor> doctors) {
    return DropdownButtonFormField<Doctor>(
      value: _doctor,
      onChanged: (Doctor? newValue) {
        setState(() {
          _doctor = newValue;
        });
      },
      items: doctors.map<DropdownMenuItem<Doctor>>((Doctor doctor) {
        return DropdownMenuItem<Doctor>(
          value: doctor,
          child: Text(doctor.name),
        );
      }).toList(),
      decoration: const InputDecoration(
        labelText: 'Select Doctor',
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildDateTimePicker() {
    return Row(
      children: [
        Expanded(
          child: CustomTextField(
            controller: _dateController,
            label: 'Date',
            hint: 'Select Date',
            prefixIcon: Icons.calendar_today,
            readOnly: true,
            onTap: _pickDate,
          ),
        ),
        const SizedBox(width: AppSizes.md),
        Expanded(
          child: CustomTextField(
            controller: _timeController,
            label: 'Time',
            hint: 'Select Time',
            prefixIcon: Icons.access_time,
            readOnly: true,
            onTap: _pickTime,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsEntry() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Consultation Type',
            style: Theme.of(context).textTheme.titleMedium),
        Wrap(
          spacing: AppSizes.sm,
          children: ConsultationType.values.map((type) {
            return ChoiceChip(
              label: Text(type.name),
              selected: _selectedConsultationType == type,
              onSelected: (bool selected) {
                if (selected) {
                  setState(() {
                    _selectedConsultationType = type;
                  });
                }
              },
            );
          }).toList(),
        ),
        const SizedBox(height: AppSizes.lg),
        CustomTextField(
          controller: _symptomsController,
          label: 'Symptoms',
          hint: 'e.g., Fever, Cough (comma separated)',
          validator: (value) => value!.isEmpty ? 'Please enter symptoms' : null,
        ),
        const SizedBox(height: AppSizes.md),
        CustomTextField(
          controller: _notesController,
          label: 'Additional Notes (Optional)',
          hint: 'Any other information for the doctor',
          maxLines: 3,
        ),
      ],
    );
  }

  Future<void> _pickDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (pickedDate != null) {
      setState(() {
        _selectedDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          _selectedDateTime?.hour ?? 0,
          _selectedDateTime?.minute ?? 0,
        );
        _dateController.text = DateFormat.yMMMd().format(pickedDate);
      });
    }
  }

  Future<void> _pickTime() async {
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (pickedTime != null) {
      setState(() {
        _selectedDateTime = DateTime(
          _selectedDateTime?.year ?? DateTime.now().year,
          _selectedDateTime?.month ?? DateTime.now().month,
          _selectedDateTime?.day ?? DateTime.now().day,
          pickedTime.hour,
          pickedTime.minute,
        );
        _timeController.text = pickedTime.format(context);
      });
    }
  }

  void _submitConsultation() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedChild == null ||
        _doctor == null ||
        _selectedDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select a child, doctor, and date/time.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final user = ref.read(authControllerProvider).userData!;
    final consultationFee = _doctor!.consultationFee;

    final currentBalance = ref.read(walletControllerProvider).balance;
    if (currentBalance < consultationFee) {
      _showInsufficientBalanceDialog();
      setState(() => _isLoading = false);
      return;
    }

    final newConsultation = ConsultationRequest(
      id: const Uuid().v4(),
      parentId: user.id,
      doctorId: _doctor!.id,
      childId: _selectedChild!.id,
      childName: _selectedChild!.name,
      childAge: _selectedChild!.ageInYears,
      fee: consultationFee,
      type: _selectedConsultationType,
      status: ConsultationStatus.pending,
      requestedAt: DateTime.now(),
      scheduledTime: _selectedDateTime,
    );

    try {
      final success =
          await ref.read(walletControllerProvider.notifier).deductFromWallet(
                user.id,
                consultationFee,
                'Consultation with ${_doctor!.name}',
                referenceId: newConsultation.id,
              );

      if (success) {
        // Use the appropriate method based on consultation type
        if (_selectedConsultationType == ConsultationType.scheduled && _selectedDateTime != null) {
          await ref
              .read(consultationControllerProvider.notifier)
              .createScheduledConsultation(
                parentId: user.id,
                childId: _selectedChild!.id,
                doctorId: _doctor!.id,
                scheduledTime: _selectedDateTime!,
              );
        } else {
          await ref
              .read(consultationControllerProvider.notifier)
              .createInstantConsultation(
                parentId: user.id,
                childId: _selectedChild!.id,
                preferredDoctorId: _doctor!.id,
              );
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Consultation booked successfully!')),
        );
        if (mounted) context.pop();
      } else {
        throw Exception('Failed to deduct from wallet.');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to book consultation: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showInsufficientBalanceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Insufficient Balance'),
        content: const Text(
            'You do not have enough funds in your wallet. Please recharge.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.push('/wallet/recharge');
            },
            child: const Text('Recharge'),
          ),
        ],
      ),
    );
  }
}
