import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Clipboard
import 'package:intl/intl.dart';
import 'package:Ajjara/l10n/app_localizations.dart';
import 'package:Ajjara/core/api/api_handler.dart' as api;

extension _L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}

class RequestConfirmationScreen extends StatefulWidget {
  const RequestConfirmationScreen({
    super.key,
    required this.requestNo,
    required this.totalSar,
    required this.from,
    required this.to,
    this.statusId,
  });

  final String requestNo;
  final double totalSar;
  final DateTime from;
  final DateTime to;
  final int? statusId;

  @override
  State<RequestConfirmationScreen> createState() =>
      _RequestConfirmationScreenState();
}

class _RequestConfirmationScreenState extends State<RequestConfirmationScreen> {
  String? _statusLabel;
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
      final d = details.firstWhere((x) => (x.domainDetailId ?? -1) == id);

      final en = (d.detailNameEnglish ?? '').trim();
      final ar = (d.detailNameArabic ?? '').trim();
      final label = en.isNotEmpty ? en : (ar.isNotEmpty ? ar : '#$id');

      if (mounted) setState(() => _statusLabel = label);
    } catch (_) {
      if (mounted) setState(() => _statusLabel = '#$id');
    } finally {
      if (mounted) setState(() => _loadingStatus = false);
    }
  }

  String _fmtDate(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  String _fmtSar(num n) => NumberFormat.currency(
    // keep numeric formatting the same, localize the symbol
    locale: 'en',
    symbol: '${context.l10n.currencySar} ',
    decimalDigits: 2,
  ).format(n);

  String get _reqNoSafe {
    final v = widget.requestNo.trim();
    if (v.isEmpty || v == '—' || v == '0') return context.l10n.pending;
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
      '${_fmtDate(widget.from)} → ${_fmtDate(widget.to)}  ($_inclusiveDays ${_inclusiveDays == 1 ? context.l10n.daySingular : context.l10n.daysSuffix})';

  Future<void> _copyDetails(BuildContext context) async {
    final statusText =
        (_statusLabel ??
        (widget.statusId != null && widget.statusId! > 0
            ? '#${widget.statusId}'
            : '—'));

    final text = [
      '${context.l10n.requestLabel} $_reqNoSafe',
      '${context.l10n.statusLabel} $statusText',
      '${context.l10n.dateRangeLabel} ${_fmtDate(widget.from)} ${context.l10n.toDateSep} ${_fmtDate(widget.to)} '
          '($_inclusiveDays ${_inclusiveDays == 1 ? context.l10n.daySingular : context.l10n.daysSuffix})',
      '${context.l10n.totalLabel} ${_fmtSar(widget.totalSar)}',
    ].join('\n');

    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.detailsCopied)));
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
      appBar: AppBar(title: Text(context.l10n.requestSubmittedTitle)),
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
                  context.l10n.successTitle,
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
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      context.l10n.numberPendingChip,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(context.l10n.requestSubmittedBody),

            const SizedBox(height: 16),

            // Details card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  _row(
                    context,
                    '${context.l10n.requestHashPrefix} ',
                    _reqNoSafe,
                  ),
                  _row(context, context.l10n.statusLabel, statusText),
                  _row(context, context.l10n.dateRangeLabel, _rangeHuman),
                  _row(
                    context,
                    context.l10n.totalLabel,
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
                    label: Text(context.l10n.actionCopyDetails),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () =>
                        Navigator.of(context).popUntil((r) => r.isFirst),
                    child: Text(context.l10n.actionDone),
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
