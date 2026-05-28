import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/region_service.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  final String plan;
  final bool isAnnual;

  const CheckoutScreen({
    super.key,
    required this.plan,
    required this.isAnnual,
  });

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  late bool _isMonthly;
  bool _agreedToTerms = false;
  bool _isSubmitting = false;
  bool _useDifferentName = false;
  String _country = 'US';

  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _address2Controller = TextEditingController();
  final _postalController = TextEditingController();
  final _emailController = TextEditingController();
  final _cardController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvcController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _isMonthly = !widget.isAnnual;
    _loadRegion();
  }

  Future<void> _loadRegion() async {
    final country = await RegionService.getRegion();
    if (mounted) setState(() => _country = country);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _address2Controller.dispose();
    _postalController.dispose();
    _emailController.dispose();
    _cardController.dispose();
    _expiryController.dispose();
    _cvcController.dispose();
    super.dispose();
  }

  String get _planDisplayName {
    switch (widget.plan) {
      case 'pro':
        return 'Pro plan';
      case 'max':
        return 'Max plan';
      default:
        return 'Pro plan';
    }
  }

  String get _planPrice {
    if (widget.plan == 'pro') {
      return RegionService.getPriceDisplay(_country, 'basic', !_isMonthly);
    }
    return RegionService.getPriceDisplay(_country, 'pro', !_isMonthly);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    final borderColor = isDark ? AppColors.darkBorderDefault : AppColors.borderDefault;
    final cardBg = isDark ? AppColors.darkBgSecondary : Colors.white;
    final inputBg = isDark ? AppColors.darkInputBg : AppColors.inputBg;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBgPrimary : AppColors.bgPrimary,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Back button
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: IconButton(
                        icon: Icon(Icons.arrow_back, color: textPrimary, size: 22),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Plan title
                    Text(_planDisplayName, style: GoogleFonts.dmSerifDisplay(fontSize: 28, color: textPrimary)),
                    const SizedBox(height: 20),
                    // Billing period selector
                    _buildBillingSelector(isDark, cardBg, borderColor, textPrimary, textMuted),
                    const SizedBox(height: 20),
                    // Order details
                    _buildOrderDetails(isDark, cardBg, borderColor, textPrimary, textMuted),
                    const SizedBox(height: 16),
                    // Auto-renewal notice
                    _buildRenewalNotice(isDark, cardBg, borderColor, textPrimary, textMuted),
                    const SizedBox(height: 24),
                    // Payment method
                    _buildPaymentForm(isDark, cardBg, borderColor, textPrimary, textMuted, inputBg),
                    const SizedBox(height: 24),
                    // Terms checkbox
                    _buildTermsCheckbox(textPrimary, textMuted),
                    const SizedBox(height: 16),
                    // Subscribe button
                    _buildSubscribeButton(isDark, textPrimary),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBillingSelector(bool isDark, Color cardBg, Color borderColor, Color textPrimary, Color textMuted) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _isMonthly = true),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isMonthly ? (isDark ? AppColors.darkBgTertiary : const Color(0xFFE8F0FE)) : cardBg,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
                border: Border.all(
                  color: _isMonthly ? const Color(0xFF4285F4) : borderColor,
                  width: _isMonthly ? 2 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _isMonthly ? Icons.radio_button_checked : Icons.radio_button_off,
                        size: 18,
                        color: _isMonthly ? const Color(0xFF4285F4) : textMuted,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Monthly', style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w600, color: textPrimary)),
                  Text(_planPrice, style: GoogleFonts.dmSans(fontSize: 13, color: textMuted)),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _isMonthly = false),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: !_isMonthly ? (isDark ? AppColors.darkBgTertiary : const Color(0xFFE8F0FE)) : cardBg,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                border: Border.all(
                  color: !_isMonthly ? const Color(0xFF4285F4) : borderColor,
                  width: !_isMonthly ? 2 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        !_isMonthly ? Icons.radio_button_checked : Icons.radio_button_off,
                        size: 18,
                        color: !_isMonthly ? const Color(0xFF4285F4) : textMuted,
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.persian.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('Save 17%', style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.persian)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Yearly', style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w600, color: textPrimary)),
                  Text(
                    RegionService.getPriceDisplay(_country, widget.plan == 'pro' ? 'basic' : 'pro', true),
                    style: GoogleFonts.dmSans(fontSize: 13, color: textMuted),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderDetails(bool isDark, Color cardBg, Color borderColor, Color textPrimary, Color textMuted) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Order details', style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary)),
          const SizedBox(height: 16),
          _orderRow(_planDisplayName, _planPrice, textPrimary, textMuted, subtitle: _isMonthly ? 'Monthly' : 'Yearly'),
          Divider(color: borderColor, height: 24),
          _orderRow('Subtotal', _planPrice, textPrimary, textMuted),
          const SizedBox(height: 4),
          _orderRow('Tax', 'Calculated at checkout', textMuted, textMuted),
          Divider(color: borderColor, height: 24),
          _orderRow('Total due today', _planPrice, textPrimary, textMuted, isBold: true),
        ],
      ),
    );
  }

  Widget _orderRow(String label, String value, Color labelColor, Color valueColor, {String? subtitle, bool isBold = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
                color: labelColor,
              )),
              if (subtitle != null)
                Text(subtitle, style: GoogleFonts.dmSans(fontSize: 12, color: valueColor)),
            ],
          ),
        ),
        Text(value, style: GoogleFonts.dmSans(
          fontSize: 14,
          fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
          color: labelColor,
        )),
      ],
    );
  }

  Widget _buildRenewalNotice(bool isDark, Color cardBg, Color borderColor, Color textPrimary, Color textMuted) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 18, color: textMuted),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Your subscription will auto renew ${_isMonthly ? "monthly" : "yearly"}. You will be charged $_planPrice (includes applicable tax).',
              style: GoogleFonts.dmSans(fontSize: 13, color: textMuted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentForm(bool isDark, Color cardBg, Color borderColor, Color textPrimary, Color textMuted, Color inputBg) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Payment method', style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary)),
          const SizedBox(height: 20),
          // Full name
          _fieldLabel('Full name', textPrimary),
          _textField(_nameController, 'Sam Lee', borderColor, inputBg, textPrimary, textMuted),
          const SizedBox(height: 16),
          // Country
          _fieldLabel('Country or region', textPrimary),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: inputBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _country,
                isExpanded: true,
                icon: Icon(Icons.keyboard_arrow_down, color: textMuted, size: 20),
                dropdownColor: cardBg,
                style: GoogleFonts.dmSans(fontSize: 14, color: textPrimary),
                items: const [
                  DropdownMenuItem(value: 'US', child: Text('United States')),
                  DropdownMenuItem(value: 'IN', child: Text('India')),
                  DropdownMenuItem(value: 'GB', child: Text('United Kingdom')),
                  DropdownMenuItem(value: 'SG', child: Text('Singapore')),
                  DropdownMenuItem(value: 'DE', child: Text('Germany')),
                  DropdownMenuItem(value: 'JP', child: Text('Japan')),
                  DropdownMenuItem(value: 'AU', child: Text('Australia')),
                  DropdownMenuItem(value: 'CA', child: Text('Canada')),
                  DropdownMenuItem(value: 'BR', child: Text('Brazil')),
                  DropdownMenuItem(value: 'FR', child: Text('France')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _country = val);
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Address
          _fieldLabel('Address', textPrimary),
          _textField(_addressController, 'Street address', borderColor, inputBg, textPrimary, textMuted),
          const SizedBox(height: 12),
          _fieldLabel('Address line 2', textPrimary),
          _textField(_address2Controller, 'Apartment, suite, etc.', borderColor, inputBg, textPrimary, textMuted),
          const SizedBox(height: 12),
          _fieldLabel('Postal code', textPrimary),
          _textField(_postalController, 'Postal code', borderColor, inputBg, textPrimary, textMuted),
          const SizedBox(height: 20),
          // Email
          _fieldLabel('Email', textPrimary),
          _textField(_emailController, 'you@example.com', borderColor, inputBg, textPrimary, textMuted),
          const SizedBox(height: 20),
          // Card number
          _fieldLabel('Card number', textPrimary),
          TextField(
            controller: _cardController,
            style: GoogleFonts.dmSans(fontSize: 14, color: textPrimary),
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: '1234 1234 1234 1234',
              hintStyle: GoogleFonts.dmSans(fontSize: 13, color: textMuted.withValues(alpha: 0.6)),
              filled: true,
              fillColor: inputBg,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderColor)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderColor)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.persian, width: 1.5)),
              suffixIcon: Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _cardBrand('VISA', const Color(0xFF1A1F71)),
                    const SizedBox(width: 4),
                    _cardBrand('MC', const Color(0xFFEB001B)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Expiry + CVC
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fieldLabel('Expiration date', textPrimary),
                    _textField(_expiryController, 'MM / YY', borderColor, inputBg, textPrimary, textMuted),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fieldLabel('Security code', textPrimary),
                    _textField(_cvcController, 'CVC', borderColor, inputBg, textPrimary, textMuted),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Different name on invoices
          Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: Checkbox(
                  value: _useDifferentName,
                  onChanged: (val) => setState(() => _useDifferentName = val ?? false),
                  activeColor: AppColors.persian,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  side: BorderSide(color: borderColor, width: 1.5),
                ),
              ),
              const SizedBox(width: 10),
              Text('Use a different name on invoices', style: GoogleFonts.dmSans(fontSize: 13, color: textPrimary)),
            ],
          ),
          const SizedBox(height: 16),
          // Business tax ID
          _fieldLabel('Business tax ID (Optional)', textPrimary),
          Text(
            'If you provide a tax ID, the "Full name" above should be your business\'s name.',
            style: GoogleFonts.dmSans(fontSize: 12, color: textMuted),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: inputBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: null,
                hint: Text('Select tax ID type', style: GoogleFonts.dmSans(fontSize: 14, color: textMuted)),
                isExpanded: true,
                icon: Icon(Icons.keyboard_arrow_down, color: textMuted, size: 20),
                dropdownColor: cardBg,
                items: const [
                  DropdownMenuItem(value: 'vat', child: Text('VAT')),
                  DropdownMenuItem(value: 'gst', child: Text('GST')),
                  DropdownMenuItem(value: 'ein', child: Text('EIN')),
                ],
                onChanged: (_) {},
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldLabel(String label, Color textPrimary) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(label, style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500, color: textPrimary)),
    );
  }

  Widget _textField(TextEditingController controller, String hint, Color borderColor, Color inputBg, Color textPrimary, Color textMuted) {
    return TextField(
      controller: controller,
      style: GoogleFonts.dmSans(fontSize: 14, color: textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.dmSans(fontSize: 13, color: textMuted.withValues(alpha: 0.6)),
        filled: true,
        fillColor: inputBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderColor)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderColor)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.persian, width: 1.5)),
      ),
    );
  }

  Widget _cardBrand(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(label, style: GoogleFonts.dmSans(fontSize: 8, fontWeight: FontWeight.w700, color: Colors.white)),
    );
  }

  Widget _buildTermsCheckbox(Color textPrimary, Color textMuted) {
    final borderColor = Theme.of(context).brightness == Brightness.dark ? AppColors.darkBorderDefault : AppColors.borderDefault;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 20,
          height: 20,
          child: Checkbox(
            value: _agreedToTerms,
            onChanged: (val) => setState(() => _agreedToTerms = val ?? false),
            activeColor: AppColors.persian,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            side: BorderSide(color: borderColor, width: 1.5),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'You agree that Mio will charge your card in the amount above now and on a recurring ${_isMonthly ? "monthly" : "yearly"} basis until you cancel in accordance with our ',
                  style: GoogleFonts.dmSans(fontSize: 13, color: textMuted),
                ),
                TextSpan(
                  text: 'terms',
                  style: GoogleFonts.dmSans(fontSize: 13, color: textPrimary, decoration: TextDecoration.underline),
                ),
                TextSpan(
                  text: '. You can cancel at any time in your account settings.',
                  style: GoogleFonts.dmSans(fontSize: 13, color: textMuted),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubscribeButton(bool isDark, Color textPrimary) {
    final isEnabled = _agreedToTerms && !_isSubmitting;

    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: isEnabled ? _handleSubscribe : null,
        style: FilledButton.styleFrom(
          backgroundColor: isEnabled
              ? (isDark ? Colors.white : const Color(0xFF1A1A1A))
              : (isDark ? const Color(0xFF333333) : const Color(0xFFCCCCCC)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: _isSubmitting
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: isDark ? Colors.black : Colors.white,
                ),
              )
            : Text(
                'Subscribe',
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isEnabled
                      ? (isDark ? Colors.black : Colors.white)
                      : (isDark ? const Color(0xFF666666) : const Color(0xFF999999)),
                ),
              ),
      ),
    );
  }

  Future<void> _handleSubscribe() async {
    setState(() => _isSubmitting = true);

    // Simulate payment processing
    await Future<void>.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    setState(() => _isSubmitting = false);

    context.go('/settings/subscription/welcome?plan=${widget.plan}');
  }
}
