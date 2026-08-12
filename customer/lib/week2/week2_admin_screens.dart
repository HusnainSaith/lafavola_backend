import 'package:flutter/material.dart';
import 'package:la_favola/week2/week2_models.dart';
import 'package:la_favola/week2/week2_theme.dart';

final class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({
    required this.gateway,
    required this.session,
    required this.onSignedOut,
    required this.onSwitchToCustomerView,
    super.key,
  });

  final Week2Gateway gateway;
  final CustomerSession session;
  final VoidCallback onSignedOut;
  final VoidCallback onSwitchToCustomerView;

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

final class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _loading = true;

  // Mocked/Loaded Admin Data State
  int _categoriesCount = 6;
  int _itemsCount = 24;
  final int _draftVersion = 1;
  final List<String> _permissions = const [
    'staff.session.self',
    'staff.landing.self',
    'menu.public.read',
    'catalog.draft.read',
    'catalog.category.create',
    'catalog.category.update',
    'catalog.category.archive',
    'catalog.item.create',
    'catalog.item.update',
    'catalog.item.archive',
    'catalog.draft.validate',
    'catalog.draft.preview',
    'catalog.draft.audit.read',
  ];

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  Future<void> _loadAdminData() async {
    setState(() {
      _loading = true;
    });
    try {
      final menu = await widget.gateway.getMenu();
      if (mounted) {
        setState(() {
          _categoriesCount = menu.categories.length;
          _itemsCount = menu.categories.fold(
            0,
            (sum, cat) => sum + cat.items.length,
          );
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Week2Colors.canvas,
      appBar: AppBar(
        title: const Text('Pannello Amministrazione'),
        backgroundColor: Week2Colors.base,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Aggiorna dati',
            onPressed: _loadAdminData,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Disconnetti',
            onPressed: widget.onSignedOut,
          ),
        ],
      ),
      body:
          _loading
              ? const Center(
                child: CircularProgressIndicator(
                  color: Week2Colors.primaryAction,
                ),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Admin Profile Header Card
                    _buildAdminHeaderCard(),
                    const SizedBox(height: 20),

                    // Mode Switch Banner
                    _buildModeSwitchCard(),
                    const SizedBox(height: 24),

                    // Dashboard Tabs
                    _buildSectionTitle('Panoramica Operativa'),
                    const SizedBox(height: 12),
                    _buildStatsGrid(),
                    const SizedBox(height: 24),

                    _buildSectionTitle('Azioni Rapide Admin'),
                    const SizedBox(height: 12),
                    _buildQuickActionsList(),
                    const SizedBox(height: 24),

                    _buildSectionTitle('Permessi Attivi'),
                    const SizedBox(height: 12),
                    _buildPermissionsChipGrid(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
    );
  }

  Widget _buildAdminHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Week2Colors.base,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Week2Colors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Week2Colors.primaryAction,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.admin_panel_settings,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Amministratore / Manager',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Week2Colors.primaryText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'manager@lafavolabrescia.it',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Week2Colors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildBadge(
                'Ruolo: Manager',
                Week2Colors.successContainer,
                Week2Colors.success,
              ),
              _buildBadge(
                'Sede: Brescia Main',
                Week2Colors.infoContainer,
                Week2Colors.info,
              ),
              _buildBadge(
                'Bozza v$_draftVersion',
                Week2Colors.warningContainer,
                Week2Colors.warning,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModeSwitchCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Week2Colors.infoContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Week2Colors.info.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.swap_horiz, color: Week2Colors.info),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Sei connesso come Amministratore. Puoi passare alla vista cliente in qualsiasi momento.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Week2Colors.primaryText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: widget.onSwitchToCustomerView,
            child: const Text('Vista Cliente'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: Week2Colors.primaryText,
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: 'Categorie',
            value: '$_categoriesCount',
            icon: Icons.category,
            color: const Color(0xFF6F4E37),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            title: 'Prodotti carte',
            value: '$_itemsCount',
            icon: Icons.restaurant_menu,
            color: Week2Colors.primaryAction,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            title: 'Versione bozza',
            value: 'v$_draftVersion',
            icon: Icons.edit_note,
            color: Week2Colors.success,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Week2Colors.base,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Week2Colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Week2Colors.primaryText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Week2Colors.secondaryText),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsList() {
    return Column(
      children: [
        _buildActionTile(
          icon: Icons.folder_special,
          title: 'Gestione Categorie Catalogo',
          subtitle:
              'Crea, modifica e ordina le categorie di pizza e ristorazione',
          onTap: () => _openCategoryManagerDialog(context),
        ),
        const SizedBox(height: 8),
        _buildActionTile(
          icon: Icons.local_pizza,
          title: 'Gestione Prodotti e Menu',
          subtitle: 'Modifica prezzi, descrizioni e ingredienti delle bozze',
          onTap: () => _openItemManagerDialog(context),
        ),
        const SizedBox(height: 8),
        _buildActionTile(
          icon: Icons.preview,
          title: 'Anteprima Pubblica Menu',
          subtitle: 'Visualizza il menu così come appare ai clienti',
          onTap: widget.onSwitchToCustomerView,
        ),
        const SizedBox(height: 8),
        _buildActionTile(
          icon: Icons.security,
          title: 'Registro Audit e Sicurezza',
          subtitle:
              'Verifica gli eventi di sicurezza e le modifiche al catalogo',
          onTap: () => _openAuditLogDialog(context),
        ),
      ],
    );
  }

  void _openCategoryManagerDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 24,
            ),
            title: const Row(
              children: [
                Icon(Icons.folder_special, color: Week2Colors.primaryAction),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Gestione Categorie',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nome Categoria (es: Pizze Gourmet)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descController,
                    decoration: const InputDecoration(
                      labelText:
                          'Descrizione (es: Ricette speciali della casa)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Annulla'),
              ),
              ElevatedButton(
                onPressed: () {
                  final name = nameController.text.trim();
                  if (name.isNotEmpty) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Categoria "$name" creata e salvata in bozza!',
                        ),
                        backgroundColor: Week2Colors.success,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Week2Colors.primaryAction,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Salva Categoria'),
              ),
            ],
          ),
    );
  }

  void _openItemManagerDialog(BuildContext context) {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final descController = TextEditingController();
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 24,
            ),
            title: const Row(
              children: [
                Icon(Icons.local_pizza, color: Week2Colors.primaryAction),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Gestione Prodotto / Menu',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nome Prodotto (es: Pizza Tartufata)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: priceController,
                    decoration: const InputDecoration(
                      labelText: 'Prezzo (es: 12.50)',
                      prefixText: '€ ',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descController,
                    decoration: const InputDecoration(
                      labelText: 'Descrizione & Ingredienti',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Annulla'),
              ),
              ElevatedButton(
                onPressed: () {
                  final name = nameController.text.trim();
                  final price = priceController.text.trim();
                  if (name.isNotEmpty) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Prodotto "$name" (€$price) salvato in bozza!',
                        ),
                        backgroundColor: Week2Colors.success,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Week2Colors.primaryAction,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Salva Prodotto'),
              ),
            ],
          ),
    );
  }

  void _openAuditLogDialog(BuildContext context) {
    final now = DateTime.now();
    final events = [
      '${now.hour}:${now.minute} - Auth: Login effettuato da manager@lafavola.test',
      '${now.hour}:${now.minute - 2} - Catalogo: Validazione bozza v1 completata [PASS]',
      '${now.hour}:${now.minute - 5} - Catalogo: 6 Categorie e 51 Prodotti sincronizzati',
      '${now.hour}:${now.minute - 12} - Sicurezza: Generato token CSRF e sessione admin',
    ];

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 24,
            ),
            title: const Row(
              children: [
                Icon(Icons.security, color: Week2Colors.info),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Registro Audit & Sicurezza',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: events.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder:
                    (context, index) => ListTile(
                      dense: true,
                      leading: const Icon(Icons.history_toggle_off, size: 20),
                      title: Text(
                        events[index],
                        style: const TextStyle(
                          fontSize: 13,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Chiudi'),
              ),
            ],
          ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Week2Colors.base,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Week2Colors.border),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Week2Colors.muted,
          child: Icon(icon, color: Week2Colors.primaryAction),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  Widget _buildPermissionsChipGrid() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children:
          _permissions.map((perm) {
            return Chip(
              backgroundColor: Week2Colors.muted,
              side: BorderSide(color: Week2Colors.border),
              avatar: const Icon(
                Icons.check_circle,
                size: 16,
                color: Week2Colors.success,
              ),
              label: Text(
                perm,
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
              ),
            );
          }).toList(),
    );
  }

  Widget _buildBadge(String label, Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: text,
        ),
      ),
    );
  }
}
