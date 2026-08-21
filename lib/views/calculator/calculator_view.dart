import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';

/// Mortgage & ROI Calculator — a standalone tool accessible from the
/// "More" menu, and pre-filled with a property's starting price when
/// opened from Property Details.
///
/// Two tabs:
///  - Mortgage: monthly payment / total interest for a given loan.
///  - ROI: gross & net rental yield, and cash-on-cash return.
///
/// All math runs locally (no network); results recompute live as the
/// user types.
class CalculatorView extends StatelessWidget {
  const CalculatorView({super.key, this.initialPrice});

  /// Optional starting property price, passed in via `extra` when pushed
  /// from Property Details so the fields aren't empty.
  final double? initialPrice;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mortgage & ROI Calculator'),
          bottom: const TabBar(
            labelColor: AppColors.primaryNavy,
            tabs: <Widget>[
              Tab(text: 'Mortgage'),
              Tab(text: 'ROI'),
            ],
          ),
        ),
        body: TabBarView(
          children: <Widget>[
            _MortgageTab(initialPrice: initialPrice),
            _RoiTab(initialPrice: initialPrice),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared bits
// ---------------------------------------------------------------------------

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.label,
    required this.controller,
    this.suffixText,
    this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final String? suffixText;
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: (_) => onChanged?.call(),
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffixText,
      ),
    );
  }
}

class _ResultsCard extends StatelessWidget {
  const _ResultsCard({required this.rows});

  /// Ordered label/value pairs. The first row is rendered as the
  /// headline figure; the rest as a supporting breakdown.
  final List<MapEntry<String, String>> rows;

  @override
  Widget build(BuildContext context) {
    final MapEntry<String, String> headline = rows.first;
    final String headlineLabel = headline.key;
    final String headlineValue = headline.value;
    final List<MapEntry<String, String>> rest = rows.skip(1).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryNavy,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            headlineLabel,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            headlineValue,
            style: const TextStyle(
              color: AppColors.goldLight,
              fontSize: 26,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (rest.isNotEmpty) ...<Widget>[
            const SizedBox(height: 14),
            const Divider(color: Colors.white24, height: 1),
            const SizedBox(height: 12),
            ...rest.map(
              (record) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(record.key,
                        style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    Text(record.value,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Mortgage tab
// ---------------------------------------------------------------------------

class _MortgageTab extends StatefulWidget {
  const _MortgageTab({this.initialPrice});
  final double? initialPrice;

  @override
  State<_MortgageTab> createState() => _MortgageTabState();
}

class _MortgageTabState extends State<_MortgageTab> {
  late final TextEditingController _price = TextEditingController(
    text: widget.initialPrice != null ? widget.initialPrice!.toStringAsFixed(0) : '',
  );
  final TextEditingController _downPaymentPct = TextEditingController(text: '20');
  final TextEditingController _rate = TextEditingController(text: '4.5');
  final TextEditingController _years = TextEditingController(text: '25');

  @override
  void dispose() {
    _price.dispose();
    _downPaymentPct.dispose();
    _rate.dispose();
    _years.dispose();
    super.dispose();
  }

  double _num(TextEditingController c) => double.tryParse(c.text.trim()) ?? 0;

  @override
  Widget build(BuildContext context) {
    final double price = _num(_price);
    final double downPct = _num(_downPaymentPct).clamp(0, 100);
    final double annualRate = _num(_rate);
    final int years = _num(_years).round().clamp(1, 50);

    final double downPayment = price * downPct / 100;
    final double principal = math.max(0, price - downPayment);
    final double monthlyRate = annualRate / 100 / 12;
    final int months = years * 12;

    double monthlyPayment;
    if (monthlyRate == 0) {
      monthlyPayment = months > 0 ? principal / months : 0;
    } else {
      final double factor = math.pow(1 + monthlyRate, months).toDouble();
      monthlyPayment = principal * (monthlyRate * factor) / (factor - 1);
    }
    if (monthlyPayment.isNaN || monthlyPayment.isInfinite) monthlyPayment = 0;

    final double totalPaid = monthlyPayment * months;
    final double totalInterest = math.max(0, totalPaid - principal);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        _NumberField(label: 'Property Price', controller: _price, suffixText: 'AED', onChanged: () => setState(() {})),
        const SizedBox(height: 12),
        _NumberField(label: 'Down Payment', controller: _downPaymentPct, suffixText: '%', onChanged: () => setState(() {})),
        const SizedBox(height: 12),
        _NumberField(label: 'Interest Rate', controller: _rate, suffixText: '% / yr', onChanged: () => setState(() {})),
        const SizedBox(height: 12),
        _NumberField(label: 'Loan Term', controller: _years, suffixText: 'years', onChanged: () => setState(() {})),
        const SizedBox(height: 20),
        _ResultsCard(rows: <MapEntry<String, String>>[
          MapEntry('Estimated Monthly Payment', Formatters.price(monthlyPayment)),
          MapEntry('Down Payment', Formatters.price(downPayment)),
          MapEntry('Loan Amount', Formatters.price(principal)),
          MapEntry('Total Interest', Formatters.price(totalInterest)),
          MapEntry('Total Repaid', Formatters.price(totalPaid)),
        ]),
        const SizedBox(height: 12),
        const Text(
          'Estimate only — actual bank offers vary by lender, eligibility and fees.',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// ROI tab
// ---------------------------------------------------------------------------

class _RoiTab extends StatefulWidget {
  const _RoiTab({this.initialPrice});
  final double? initialPrice;

  @override
  State<_RoiTab> createState() => _RoiTabState();
}

class _RoiTabState extends State<_RoiTab> {
  late final TextEditingController _price = TextEditingController(
    text: widget.initialPrice != null ? widget.initialPrice!.toStringAsFixed(0) : '',
  );
  final TextEditingController _downPaymentPct = TextEditingController(text: '20');
  final TextEditingController _annualRent = TextEditingController();
  final TextEditingController _annualExpenses = TextEditingController(text: '0');

  @override
  void dispose() {
    _price.dispose();
    _downPaymentPct.dispose();
    _annualRent.dispose();
    _annualExpenses.dispose();
    super.dispose();
  }

  double _num(TextEditingController c) => double.tryParse(c.text.trim()) ?? 0;

  @override
  Widget build(BuildContext context) {
    final double price = _num(_price);
    final double downPct = _num(_downPaymentPct).clamp(0, 100);
    final double annualRent = _num(_annualRent);
    final double annualExpenses = _num(_annualExpenses);

    final double investment = price * downPct / 100;
    final double netAnnualIncome = annualRent - annualExpenses;

    final double grossYield = price > 0 ? (annualRent / price) * 100 : 0;
    final double netYield = price > 0 ? (netAnnualIncome / price) * 100 : 0;
    final double cashOnCash = investment > 0 ? (netAnnualIncome / investment) * 100 : 0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        _NumberField(label: 'Property Price', controller: _price, suffixText: 'AED', onChanged: () => setState(() {})),
        const SizedBox(height: 12),
        _NumberField(label: 'Down Payment', controller: _downPaymentPct, suffixText: '%', onChanged: () => setState(() {})),
        const SizedBox(height: 12),
        _NumberField(label: 'Expected Annual Rent', controller: _annualRent, suffixText: 'AED', onChanged: () => setState(() {})),
        const SizedBox(height: 12),
        _NumberField(label: 'Annual Service Charges & Costs', controller: _annualExpenses, suffixText: 'AED', onChanged: () => setState(() {})),
        const SizedBox(height: 20),
        _ResultsCard(rows: <MapEntry<String, String>>[
          MapEntry('Net Rental Yield', '${netYield.toStringAsFixed(2)}%'),
          MapEntry('Gross Rental Yield', '${grossYield.toStringAsFixed(2)}%'),
          MapEntry('Cash-on-Cash Return', '${cashOnCash.toStringAsFixed(2)}%'),
          MapEntry('Your Investment (Down Payment)', Formatters.price(investment)),
          MapEntry('Net Annual Income', Formatters.price(netAnnualIncome)),
        ]),
        const SizedBox(height: 12),
        const Text(
          'Estimate only — actual returns depend on occupancy, market conditions and financing terms.',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
        ),
      ],
    );
  }
}
