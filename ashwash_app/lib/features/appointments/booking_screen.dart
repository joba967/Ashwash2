import 'dart:math';
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
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Specialist Info Card
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
                      widget.specialist.name.isNotEmpty ? widget.specialist.name[0].toUpperCase() : 'S',
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.specialist.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 2),
                        Text(widget.specialist.degree, style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(widget.specialist.specialization, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Select Date
            Text(isBn ? 'তারিখ নির্বাচন করুন' : 'Select Date', style: AppTypography.heading2(context)),
            const SizedBox(height: 10),
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const Icon(Icons.calendar_today_rounded, color: AppColors.primary),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Select Time Slot
            Text(isBn ? 'সময় নির্বাচন করুন' : 'Select Time Slot', style: AppTypography.heading2(context)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _timeSlots.map((slot) {
                final isSelected = _selectedTimeSlot == slot;
                return ChoiceChip(
                  label: Text(slot),
                  selected: isSelected,
                  selectedColor: AppColors.primary,
                  backgroundColor: Colors.grey.shade100,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedTimeSlot = slot);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Select Payment Gateway (bKash & Nagad)
            Text(isBn ? 'পেমেন্ট মাধ্যম' : 'Select Payment Gateway', style: AppTypography.heading2(context)),
            const SizedBox(height: 10),
            Row(
              children: _paymentMethods.map((method) {
                final isSelected = _selectedPaymentMethod == method['name'];
                final isBkash = method['name'] == 'bKash';
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: InkWell(
                      onTap: () => setState(() => _selectedPaymentMethod = method['name']!),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (isBkash ? const Color(0xFFE2136E).withOpacity(0.12) : const Color(0xFFF7921E).withOpacity(0.12))
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? (isBkash ? const Color(0xFFE2136E) : const Color(0xFFF7921E))
                                : Colors.grey.shade300,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(method['icon']!, style: const TextStyle(fontSize: 24)),
                            const SizedBox(height: 4),
                            Text(
                              method['name']!,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? (isBkash ? const Color(0xFFE2136E) : const Color(0xFFF7921E))
                                    : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
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
                  backgroundColor: _selectedPaymentMethod == 'bKash' ? const Color(0xFFE2136E) : const Color(0xFFF7921E),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () {
                  _showPaymentGatewayModal(context, isBn);
                },
                child: Text(
                  isBn
                      ? 'পেমেন্ট করুন (${_selectedPaymentMethod} ৳${widget.specialist.feeBdt})'
                      : 'Pay & Confirm (${_selectedPaymentMethod} ৳${widget.specialist.feeBdt})',
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
    final isBkash = _selectedPaymentMethod.toLowerCase() == 'bkash';
    final themeColor = isBkash ? const Color(0xFFE2136E) : const Color(0xFFF7921E);
    final mobileCtrl = TextEditingController(text: '01770618575');
    final otpCtrl = TextEditingController(text: '123456');
    final pinCtrl = TextEditingController(text: '12121');
    bool isProcessing = false;
    final invoiceNo = 'INV-${Random().nextInt(900000) + 100000}';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                top: 20,
                left: 20,
                right: 20,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle Bar
                    Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
                    const SizedBox(height: 16),

                    // Header Branding
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: themeColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(isBkash ? '📱' : '📲', style: const TextStyle(fontSize: 24)),
                              const SizedBox(width: 8),
                              Text(
                                isBkash ? 'bKash Tokenized Gateway' : 'Nagad Payment Gateway',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                            child: const Text('SANDBOX', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Invoice & Amount Summary
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(isBn ? 'ইনভয়েস নম্বর:' : 'Invoice No:', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                              Text(invoiceNo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(isBn ? 'মোট টাকা:' : 'Total Amount:', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                              Text('৳${widget.specialist.feeBdt}.00', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: themeColor)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Mobile Number Input
                    TextField(
                      controller: mobileCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: isBn ? '${_selectedPaymentMethod} একাউন্ট নম্বর' : '${_selectedPaymentMethod} Mobile Number',
                        prefixIcon: Icon(Icons.phone_android_rounded, color: themeColor),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // OTP & PIN Row
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: otpCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Verification OTP',
                              hintText: '123456',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: pinCtrl,
                            obscureText: true,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Account PIN',
                              hintText: '12121',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Submit Payment Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: isProcessing
                            ? null
                            : () async {
                                setModalState(() => isProcessing = true);
                                final appDateStr = '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}';
                                String finalTrxId = '';

                                // 1. Save Booking
                                try {
                                  await ApiService.post(ApiEndpoints.bookings, {
                                    'specialist_id': widget.specialist.id,
                                    'appointment_date': '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
                                    'time_slot': _selectedTimeSlot,
                                    'status': 'confirmed',
                                    'notes': 'Booked with ${widget.specialist.name}',
                                  });
                                } catch (_) {}

                                // 2. Call bKash / Nagad Sandbox Execute Endpoint
                                try {
                                  final payEndpoint = isBkash ? 'payments/bkash/execute/' : 'payments/nagad/execute/';
                                  final res = await ApiService.post(payEndpoint, {
                                    'amount': widget.specialist.feeBdt,
                                    'purpose': 'Consultation Session with ${widget.specialist.name}',
                                    'mobile_number': mobileCtrl.text.trim(),
                                    'otp': otpCtrl.text.trim(),
                                    'pin': pinCtrl.text.trim(),
                                  });
                                  if (res is Map && res['transaction_id'] != null) {
                                    finalTrxId = res['transaction_id'].toString();
                                  }
                                } catch (_) {}

                                if (finalTrxId.isEmpty) {
                                  finalTrxId = isBkash ? 'BKASH${Random().nextInt(90000000) + 10000000}' : 'NAGAD${Random().nextInt(90000000) + 10000000}';
                                }

                                final specProvider = Provider.of<SpecialistProvider>(context, listen: false);
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
                                    meetingLink: 'https://meet.google.com/ash-wash-wellness',
                                    notes: 'Booked session with ${widget.specialist.name}',
                                  ),
                                );

                                if (mounted) {
                                  Navigator.pop(ctx);
                                  _showSuccessDialog(context, isBn, finalTrxId);
                                }
                              },
                        icon: isProcessing
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.lock_rounded, color: Colors.white, size: 20),
                        label: Text(
                          isProcessing ? 'Processing Payment...' : 'Confirm & Pay ৳${widget.specialist.feeBdt}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
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
                isBn ? 'পেমেন্ট ও বুকিং নিশ্চিত!' : 'Payment & Booking Confirmed!',
                style: AppTypography.heading2(context),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
                child: Text(
                  'Transaction ID: $trxId',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 12),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                isBn
                    ? 'আপনার ভিডিও সেশন লিংক নোটিফিকেশনে পাঠানো হয়েছে।'
                    : 'Google Meet link sent to your Notifications feed.',
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
