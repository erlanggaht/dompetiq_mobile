import 'package:flutter/material.dart';

import 'package:flutter_application_1/feat/card/card_service.dart';
import 'package:flutter_application_1/widgets/card_visual.dart';

class CardDetailScreen extends StatefulWidget {
  final Map<String, dynamic> card;
  final int index;
  final List<Map<String, dynamic>> cards;

  const CardDetailScreen({
    super.key,
    required this.card,
    required this.index,
    required this.cards,
  });

  @override
  State<CardDetailScreen> createState() => _CardDetailScreenState();
}

class _CardDetailScreenState extends State<CardDetailScreen> {
  final _service = CardService();
  bool _busy = false;

  Future<void> _closeCard() async {
    if (_busy) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Close card?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Close card'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      var result = await _service.close(widget.card['rekeningUserId'] as int);
      if (result['needTransfer'] == true) {
        if (!mounted) return;
        final targetId = await showModalBottomSheet<int>(
          context: context,
          builder: (context) => SafeArea(
            child: ListView(
              shrinkWrap: true,
              children: [
                const ListTile(title: Text('Move balance to')),
                for (final other in widget.cards.where(
                  (item) =>
                      item['rekeningUserId'] != widget.card['rekeningUserId'],
                ))
                  ListTile(
                    title: Text(other['name'] as String? ?? 'Account'),
                    onTap: () => Navigator.pop(
                      context,
                      (other['rekeningUserId'] as num).toInt(),
                    ),
                  ),
              ],
            ),
          ),
        );
        if (targetId == null) return;
        result = await _service.close(
          widget.card['rekeningUserId'] as int,
          targetRekeningUserId: targetId,
        );
        if (result['needTransfer'] == true) {
          throw Exception('Could not transfer the card balance');
        }
      }
      if (!mounted) return;
      Navigator.pop(context, true);
      messenger.showSnackBar(
        const SnackBar(content: Text('Card closed successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _setActive(bool active) async {
    if (widget.card['name'] == 'Uang Tunai' && !active) return;
    try {
      await _service.setActive(widget.card['rekeningUserId'] as int, active);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  Future<void> _settings() async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.star_outline),
              title: const Text('Make primary'),
              onTap: () async {
                await _service.setPrimary(widget.card['rekeningUserId'] as int);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Primary card updated')),
                  );
                  Navigator.pop(context, true);
                }
              },
            ),
            if (widget.card['name'] != 'Uang Tunai')
              ListTile(
                leading: Icon(
                  widget.card['isActive'] == true
                      ? Icons.block
                      : Icons.check_circle_outline,
                ),
                title: Text(
                  widget.card['isActive'] == true
                      ? 'Disable card'
                      : 'Enable card',
                ),
                onTap: () {
                  Navigator.pop(context);
                  _setActive(widget.card['isActive'] != true);
                },
              ),
            if (widget.card['name'] != 'Uang Tunai')
              ListTile(
                enabled: !_busy,
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Close card'),
                onTap: () {
                  Navigator.pop(context);
                  _closeCard();
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.card['name'] as String? ?? 'Card';
    final last4 = '${widget.card['last4'] ?? ''}';
    final saldo = (widget.card['saldo'] as num?)?.toInt() ?? 0;
    final active = widget.card['isActive'] == true;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.close,
                  color: Color(0xFF1C1C1C),
                  size: 28,
                ),
              ),
            ),
            const SizedBox(height: 12),
            CardVisual(
              name: name,
              last4: last4,
              saldo: saldo,
              isActive: active,
              index: widget.index,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _Action(
                  icon: Icons.visibility_outlined,
                  label: 'Show details',
                  onTap: () => showModalBottomSheet<void>(
                    context: context,
                    builder: (_) => SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Center(
                              child: Container(
                                width: 38,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD0D5DD),
                                  borderRadius: BorderRadius.circular(9),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 18),
                            _DetailRow('Balance', 'Rp $saldo'),
                            _DetailRow('Card number', '•••• $last4'),
                            _DetailRow(
                              'Status',
                              active ? 'Active' : 'Inactive',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                _Action(
                  icon: active ? Icons.block : Icons.check_circle_outline,
                  label: active ? 'Disable' : 'Enable',
                  onTap: widget.card['name'] == 'Uang Tunai'
                      ? null
                      : () => _setActive(!active),
                ),
                _Action(
                  icon: Icons.settings_outlined,
                  label: 'Settings',
                  onTap: _settings,
                ),
              ],
            ),
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFEAECF0)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0D000000),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: const Column(
                children: [
                  Text(
                    'Recent activity',
                    style: TextStyle(
                      color: Color(0xFF1C1C1C),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 28),
                  Text(
                    'No recent activity',
                    style: TextStyle(color: Color(0xFF667085)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        Expanded(
          child: Text(label, style: const TextStyle(color: Color(0xFF667085))),
        ),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    ),
  );
}

class _Action extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _Action({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 92,
    child: Column(
      children: [
        IconButton(
          onPressed: onTap,
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xFFE9EEF9),
            foregroundColor: const Color(0xFF1C1C1C),
            fixedSize: const Size(48, 48),
          ),
          icon: Icon(icon),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF667085), fontSize: 12),
        ),
      ],
    ),
  );
}
