import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Clipboard
import 'package:intl/intl.dart';

// add this if you don’t already import api in this file
import 'package:heavy_new/core/api/api_handler.dart' as api;

class RequestConfirmationScreen extends StatefulWidget {
  const RequestConfirmationScreen({
    super.key,
    required this.requestNo,
    required this.totalSar,
    required this.from,
    required this.to,
    this.statusId, // ← new
  });

  /// Request number returned by the API. May be "—" or empty on some backends.
  final String requestNo;

  /// Total amount (after VAT) in SAR.
  final double totalSar;

  /// Rental period (inclusive).
  final DateTime from;
  final DateTime to;

  /// Status (Domain 12) detail id (e.g. 34). Optional.
  final int? statusId;

  @override
  State<RequestConfirmationScreen> createState() =>
      _RequestConfirmationScreenState();
}

class _RequestConfirmationScreenState extends State<RequestConfirmationScreen> {
  String? _statusLabel; // resolved label from Domain 12
  bool _loadingStatus = false;

  @override
  void initState() {
    super.initState();
    _loadStatusIfNeeded();
  }

  Future<void> _loadStatusIfNeeded() async {
    final id = widget.statusId ?? 0;
    if (id <= 0) return;

    setState(() => _loadingStatus = true);
    try {
      final details = await api.Api.getDomainDetailsByDomainId(12);
      // find the matching detail id
      final d = details.firstWhere((x) => (x.domainDetailId ?? -1) == id);

      String? label;
      final en = (d.detailNameEnglish ?? '').trim();
      final ar = (d.detailNameArabic ?? '').trim();
      label = en.isNotEmpty ? en : (ar.isNotEmpty ? ar : '#$id');

      if (mounted) setState(() => _statusLabel = label);
    } catch (_) {
      if (mounted) setState(() => _statusLabel = '#$id');
    } finally {
      if (mounted) setState(() => _loadingStatus = false);
    }
  }

  String _fmtDate(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  String _fmtSar(num n) => NumberFormat.currency(
    locale: 'en',
    symbol: 'SAR ',
    decimalDigits: 2,
  ).format(n);

  String get _reqNoSafe {
    final v = widget.requestNo.trim();
    if (v.isEmpty || v == '—' || v == '0') return 'Pending';
    return v;
  }

  bool get _isPending =>
      widget.requestNo.trim().isEmpty ||
      widget.requestNo.trim() == '—' ||
      widget.requestNo == '0';

  int get _inclusiveDays {
    final start = widget.from.isBefore(widget.to) ? widget.from : widget.to;
    final end = widget.from.isBefore(widget.to) ? widget.to : widget.from;
    return end.difference(start).inDays + 1;
  }

  String get _rangeHuman =>
      '${_fmtDate(widget.from)} → ${_fmtDate(widget.to)}  (${_inclusiveDays} day${_inclusiveDays == 1 ? '' : 's'})';

  Future<void> _copyDetails(BuildContext context) async {
    final statusText =
        (_statusLabel ??
        (widget.statusId != null && widget.statusId! > 0
            ? '#${widget.statusId}'
            : '—'));
    final text = [
      'Request: $_reqNoSafe',
      'Status: $statusText',
      'Dates: ${_fmtDate(widget.from)} to ${_fmtDate(widget.to)} '
          '(${_inclusiveDays} day${_inclusiveDays == 1 ? '' : 's'})',
      'Total: ${_fmtSar(widget.totalSar)}',
    ].join('\n');

    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Details copied')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final statusText = _loadingStatus
        ? '…'
        : (_statusLabel ??
              (widget.statusId != null && widget.statusId! > 0
                  ? '#${widget.statusId}'
                  : '—'));

    return Scaffold(
      appBar: AppBar(title: const Text('Request submitted')),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.check_circle, size: 48, color: cs.primary),
            const SizedBox(height: 12),

            // Title + pending chip
            Row(
              children: [
                Text(
                  'Success!',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 8),
                if (_isPending)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: cs.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Number pending',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Your request has been submitted.'),

            const SizedBox(height: 16),

            // Details card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cs.surfaceVariant,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  _row(context, 'Request #', _reqNoSafe),
                  _row(context, 'Status', statusText),
                  _row(context, 'Date range', _rangeHuman),
                  _row(
                    context,
                    'Total',
                    _fmtSar(widget.totalSar),
                    isStrong: true,
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _copyDetails(context),
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy details'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () =>
                        Navigator.of(context).popUntil((r) => r.isFirst),
                    child: const Text('Done'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(
    BuildContext context,
    String a,
    String b, {
    bool isStrong = false,
  }) {
    final baseStyle = Theme.of(context).textTheme.bodyMedium!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              a,
              style: baseStyle.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 7,
            child: Text(
              b,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              maxLines: 3,
              style: isStrong
                  ? baseStyle.copyWith(fontWeight: FontWeight.w800)
                  : baseStyle,
            ),
          ),
        ],
      ),
    );
  }
}
