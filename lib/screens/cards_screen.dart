import 'package:flutter/material.dart';
import 'package:flutter_application_1/feat/card/card_service.dart';
import 'package:flutter_application_1/screens/card_detail_screen.dart';
import 'package:flutter_application_1/widgets/app_bottom_nav.dart';
import 'package:flutter_application_1/widgets/card_visual.dart';
import 'package:flutter_application_1/widgets/app_section_header.dart';

class CardsScreen extends StatefulWidget {
  final VoidCallback? onOpenMenu;
  final VoidCallback? onOpenNotifications;
  final bool hasUnreadNotifications;
  final bool showBottomNav;

  const CardsScreen({
    super.key,
    this.onOpenMenu,
    this.onOpenNotifications,
    this.hasUnreadNotifications = false,
    this.showBottomNav = false,
  });

  @override
  State<CardsScreen> createState() => _CardsScreenState();
}

class _CardsScreenState extends State<CardsScreen> {
  final _service = CardService();
  List<Map<String, dynamic>> _cards = [];
  List<Map<String, dynamic>> _accounts = [];
  int? _primaryId;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _service.load();
      final primaryData = await _service.load(isPrimary: true);
      final raw = data['cardInfomation'];
      final cards = raw is List
          ? raw.cast<Map<String, dynamic>>()
          : raw is Map
          ? [raw.cast<String, dynamic>()]
          : <Map<String, dynamic>>[];
      if (!mounted) return;
      setState(() {
        _cards = cards;
        final primary = primaryData['cardInfomation'];
        _primaryId = primary is Map
            ? (primary['rekeningUserId'] as num?)?.toInt()
            : null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _addCard() async {
    try {
      _accounts = await _service.availableAccounts();
      final existing = _cards.map((e) => e['name']).toSet();
      final choices = _accounts
          .where((e) => !existing.contains(e['name']))
          .toList();
      if (!mounted) return;
      final selected = await showModalBottomSheet<Map<String, dynamic>>(
        context: context,
        builder: (context) => SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              const ListTile(
                title: Text(
                  'Add card',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              for (final account in choices)
                ListTile(
                  title: Text(account['name'] as String? ?? ''),
                  onTap: () => Navigator.pop(context, account),
                ),
              if (choices.isEmpty)
                const ListTile(title: Text('No available cards')),
            ],
          ),
        ),
      );
      if (selected == null) return;
      await _service.add(
        accountId: selected['id'] as int,
        name: selected['name'] as String,
      );
      await _load();
    } catch (e) {
      _message(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      bottomNavigationBar: widget.showBottomNav
          ? AppBottomNav(onHome: () => Navigator.pop(context))
          : null,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                AppSectionHeader(
                  title: 'Cards',
                  onOpenMenu: widget.onOpenMenu,
                  onOpenNotifications: widget.onOpenNotifications,
                  hasUnreadNotifications: widget.hasUnreadNotifications,
                ),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _error != null
                      ? Center(child: Text(_error!))
                      : _cards.isEmpty
                      ? const Center(child: Text('No cards yet'))
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
                            itemCount: _cards.length,
                            itemBuilder: (context, index) {
                              final card = _cards[index];
                              final primary =
                                  card['rekeningUserId'] == _primaryId;
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFFEAECF0),
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x0D000000),
                                      blurRadius: 12,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => CardDetailScreen(
                                            card: card,
                                            index: index,
                                          ),
                                        ),
                                      );
                                      _load();
                                    },
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: CardVisual(
                                            name:
                                                card['name'] as String? ??
                                                'Card',
                                            last4: '${card['last4'] ?? ''}',
                                            saldo:
                                                (card['saldo'] as num?)
                                                    ?.toInt() ??
                                                0,
                                            isActive: card['isActive'] == true,
                                            index: index,
                                            compact: true,
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                            16,
                                            0,
                                            16,
                                            14,
                                          ),
                                          child: Row(
                                            children: [
                                              Text(
                                                card['isActive'] == true
                                                    ? 'Active'
                                                    : 'Inactive',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Color(0xFF667085),
                                                ),
                                              ),
                                              if (primary) ...[
                                                const SizedBox(width: 8),
                                                const Text(
                                                  'Primary',
                                                  style: TextStyle(
                                                    color: Color(0xFF3B62FF),
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
          ),
          if (!_loading && _error == null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 104,
              child: Center(
                child: FilledButton.icon(
                  onPressed: _addCard,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add card'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF3B62FF),
                    foregroundColor: Colors.white,
                    elevation: 5,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    minimumSize: const Size(0, 40),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: const StadiumBorder(),
                    textStyle: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
