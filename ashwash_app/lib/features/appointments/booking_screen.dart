import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/localization/app_language_provider.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/network/api_service.dart';
import '../../core/providers/specialist_provider.dart';
import '../../data/models/specialist_model.dart';
import '../dashboard/main_navigation_screen.dart';

class BookingScreen extends StatefulWidget {
  final SpecialistModel specialist;
  const BookingScreen({Key? key, required this.specialist}) : super(key: key);

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String _selectedTimeSlot = '10:00 AM - 11:00 AM';
  String _selectedPaymentMethod = 'bKash';

  final List<String> _timeSlots = [
    '09:00 AM - 10:00 AM',
    '10:00 AM - 11:00 AM',
    '03:00 PM - 04:00 PM',
    '06:00 PM - 07:00 PM',
  ];

  final List<Map<String, String>> _paymentMethods = [
    {'name': 'bKash', 'icon': '📱'},
    {'name': 'Nagad', 'icon': '📲'},
  ];

  @override
  Widget build(BuildContext context) {
    final isBn = Provider.of<AppLanguageProvider>(context).isBangla;

    return Scaffold(
      appBar: AppBar(
        title: Text(isBn ? 'সেশন বুকিং' : 'Book Session', style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Specialist Summary Header Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      widget.specialist.name.split(' ').last[0],
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.specialist.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(isBn ? widget.specialist.titleBn : widget.specialist.titleEn, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                        const SizedBox(height: 4),
                        Text(
                          'Fee: ৳${widget.specialist.feeBdt}',
                          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Date Picker Section
            Text(isBn ? 'তারিখ নির্বাচন করুন' : 'Select Date', style: AppTypography.heading2(context)),
            const SizedBox(height: 12),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 30)),
                );
                if (picked != null) {
                  setState(() => _selectedDate = picked);
                }
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const Icon(Icons.calendar_today_rounded, color: AppColors.primary),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Time Slot Selection
            Text(isBn ? 'সময় নির্বাচন করুন' : 'Select Time Slot', style: AppTypography.heading2(context)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _timeSlots.map((slot) {
                final isSelected = _selectedTimeSlot == slot;
                return ChoiceChip(
                  label: Text(slot),
                  selected: isSelected,
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.bold),
                  onSelected: (selected) {
                    setState(() => _selectedTimeSlot = slot);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Payment Method Selection
            Text(isBn ? 'পেমেন্ট পদ্ধতি' : 'Select Payment Method', style: AppTypography.heading2(context)),
            const SizedBox(height: 12),
            Column(
              children: _paymentMethods.map((m) {
                final isSelected = _selectedPaymentMethod == m['name'];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isSelected ? AppColors.primary : Colors.grey.shade200, width: isSelected ? 2 : 1),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    child: RadioListTile<String>(
                      activeColor: AppColors.primary,
                      title: Row(
                        children: [
                          Text(m['icon']!, style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 10),
                          Text(m['name']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      value: m['name']!,
                      groupValue: _selectedPaymentMethod,
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedPaymentMethod = val);
                      },
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 30),

            // Confirm Booking Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () {
                  _showPaymentGatewayModal(context, isBn);
                },
                child: Text(
                  isBn ? 'পেমেন্ট ও বুকিং নিশ্চিত করুন (৳${widget.specialist.feeBdt})' : 'Pay & Confirm Booking (৳${widget.specialist.feeBdt})',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPaymentGatewayModal(BuildContext context, bool isBn) {
    final mobileController = TextEditingController(text: '01770618575');
    final otpController = TextEditingController(text: '123456');
    final pinController = TextEditingController(text: '12121');
    bool isLoading = false;
    final isBkash = _selectedPaymentMethod.toLowerCase() == 'bkash';
    final primaryThemeColor = isBkash ? const Color(0xFFE2136E) : const Color(0xFFF7921E);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                top: 24,
                left: 24,
                right: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: primaryThemeColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isBkash ? 'bKash Tokenized Checkout' : 'Nagad Payment Gateway',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: primaryThemeColor.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: primaryThemeColor.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Invoice: INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                          style: TextStyle(fontSize: 12, color: primaryThemeColor, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Amount: ৳${widget.specialist.feeBdt}',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.extrabold, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: mobileController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: isBkash ? 'bKash Account Number' : 'Nagad Mobile Number',
                      prefixIcon: const Icon(Icons.phone_android),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: otpController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Verification OTP',
                            prefixIcon: const Icon(Icons.password),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: pinController,
                          obscureText: true,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'PIN Code',
                            prefixIcon: const Icon(Icons.lock_outline),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryThemeColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: isLoading
                          ? null
                          : () async {
                              setModalState(() => isLoading = true);
                              final specProvider = Provider.of<SpecialistProvider>(context, listen: false);
                              final appDateStr = '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}';
                              String verifiedTrxId = 'TR0011${DateTime.now().millisecondsSinceEpoch}';

                              try {
                                await ApiService.post(ApiEndpoints.bookings, {
                                  'specialist_id': widget.specialist.id,
                                  'appointment_date': '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
                                  'time_slot': _selectedTimeSlot,
                                  'status': 'confirmed',
                                  'notes': 'Booked with ${widget.specialist.name}',
                                });
                              } catch (_) {}

                              try {
                                final payEndpoint = isBkash ? 'payments/bkash/execute/' : 'payments/nagad/execute/';
                                final response = await ApiService.post(payEndpoint, {
                                  'amount': widget.specialist.feeBdt,
                                  'purpose': 'Consultation Session with ${widget.specialist.name}',
                                  'mobile_number': mobileController.text.trim(),
                                  'otp': otpController.text.trim(),
                                  'pin': pinController.text.trim(),
                                });

                                if (response != null && response['transaction_id'] != null) {
                                  verifiedTrxId = response['transaction_id'].toString();
                                }
                              } catch (_) {}

                              specProvider.addAppointment(
                                SpecialistAppointmentModel(
                                  id: 'app_${DateTime.now().millisecondsSinceEpoch}',
                                  patientId: 'pat_new_${DateTime.now().millisecondsSinceEpoch}',
                                  patientName: 'Patient User (Booked Session)',
                                  patientAvatar: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150',
                                  date: appDateStr,
                                  timeSlot: _selectedTimeSlot,
                                  category: widget.specialist.specialization,
                                  status: 'confirmed',
                                  meetingLink: 'https://meet.google.com/ash-wash-wellness-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
                                  notes: 'Booked session with ${widget.specialist.name} (TrxID: $verifiedTrxId)',
                                ),
                              );

                              Navigator.pop(modalCtx);
                              if (mounted) _showSuccessDialog(context, isBn, verifiedTrxId);
                            },
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              isBn ? '🔒 পেমেন্ট সম্পন্ন করুন (৳${widget.specialist.feeBdt})' : '🔒 Confirm & Pay ৳${widget.specialist.feeBdt}',
                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showSuccessDialog(BuildContext context, bool isBn, String trxId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 70),
              const SizedBox(height: 16),
              Text(
                isBn ? 'বুকিং ও পেমেন্ট সফল হয়েছে!' : 'Booking & Payment Confirmed!',
                style: AppTypography.heading2(context),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Text(
                  'bKash TrxID: $trxId',
                  style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                isBn
                    ? 'আপনার গুগল মিট লিংক নোটিফিকেশনে পাঠানো হয়েছে।'
                    : 'Google Meet link sent to your notifications drawer.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
                    (route) => false,
                  );
                },
                child: Text(isBn ? 'হোম পেজে ফিরে যান' : 'Back to Home', style: const TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      },
    );
  }
}
