import 'package:flutter/material.dart';
import 'package:ajjara/core/api/api_handler.dart' as api;
import 'package:ajjara/core/auth/auth_store.dart';
import 'package:ajjara/core/models/contracts/contract.dart';
import 'package:ajjara/core/models/organization/organization_user.dart';
import 'package:ajjara/foundation/ui/app_icons.dart';
import 'package:ajjara/foundation/ui/ui_extras.dart';
import 'package:ajjara/foundation/ui/ui_kit.dart';

import 'contract_details_screen.dart';

// l10n
import 'package:ajjara/l10n/app_localizations.dart';

extension _L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}

class ContractsScreen extends StatefulWidget {
  const ContractsScreen({super.key});
  @override
  State<ContractsScreen> createState() => _ContractsScreenState();
}

class _ContractsScreenState extends State<ContractsScreen> {
  Future<List<ContractModel>>? _future;

  @override
  void initState() {
    super.initState();
    _future = Future.value(<ContractModel>[]); // optional placeholder
    _load();
  }

  Future<int?> _resolveMyOrganizationId() async {
    final u = AuthStore.instance.user.value;
    if (u == null) return null;
    final rows = await api.Api.getOrganizationUsers();
    final me = rows.firstWhere(
      (m) => (m.applicationUserId == u.id) && (m.isActive == true),
      orElse: () => OrganizationUser(),
    );
    return me.organizationId;
  }

  Future<void> _load() async {
    final orgId = await _resolveMyOrganizationId();
    if (!mounted) return;

    if (orgId == null || orgId == 0) {
      setState(() {
        _future = Future.value(<ContractModel>[]);
      });
      AppSnack.info(context, context.l10n.infoCreateActivateOrg);
      return;
    }

    final q =
        'Select * From Contracts Where (VendorId = $orgId Or CustomerId = $orgId)';

    final fut = api.Api.searchContracts(q);
    setState(() {
      _future = fut;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.contractsTitle),
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            tooltip: context.l10n.actionRefresh,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _load(),
        child: FutureBuilder<List<ContractModel>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return ListView(children: const [ShimmerTile(), ShimmerTile()]);
            }
            final items = snap.data ?? [];
            if (items.isEmpty) {
              return ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(context.l10n.noContractsYet),
                  ),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final c = items[i];
                final id = c.contractId ?? 0;
                final no = c.contractNo ?? id;
                final from = (c.fromDate ?? '').split('T').first;
                final to = (c.toDate ?? '').split('T').first;
                return Glass(
                  radius: 16,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: cs.primaryContainer,
                      child: AIcon(
                        AppGlyph.contract,
                        color: cs.onPrimaryContainer,
                      ),
                    ),
                    title: Text(
                      context.l10n.contractNumber('$no'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(context.l10n.dateRangeChip(from, to)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ContractDetailsScreen(contractId: id),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
