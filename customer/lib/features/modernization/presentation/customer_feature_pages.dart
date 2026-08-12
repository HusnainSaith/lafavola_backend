import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:la_favola/core/api/customer_api_client.dart';
import 'package:la_favola/core/session/customer_session_controller.dart';
import 'package:la_favola/features/modernization/data/customer_feature_repositories.dart';
import 'package:la_favola/week2/week2_models.dart';

final class CustomerCopy {
  const CustomerCopy(this.italian);
  final bool italian;
  static CustomerCopy of(BuildContext context) =>
      CustomerCopy(Localizations.localeOf(context).languageCode == 'it');
  String text(String it, String en) => italian ? it : en;
}

class CustomerRouteFrame extends StatelessWidget {
  const CustomerRouteFrame({
    required this.title,
    required this.child,
    this.actions = const [],
    super.key,
  });
  final String title;
  final Widget child;
  final List<Widget> actions;
  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Scaffold(
      appBar: AppBar(title: Text(title), actions: actions),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: AnimatedSwitcher(
              duration:
                  reduceMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 220),
              transitionBuilder:
                  (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween(
                        begin: const Offset(0, .02),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  ),
              child: Padding(
                key: ValueKey(title),
                padding: const EdgeInsets.all(16),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _localizedApiFailure(CustomerCopy copy, CustomerApiException error) =>
    switch (error.kind) {
      'timeout' => copy.text(
        'Tempo di attesa superato. Riprova.',
        'The request timed out. Try again.',
      ),
      'offline' => copy.text(
        'Servizio non raggiungibile. Controlla la connessione.',
        'The service is unreachable. Check your connection.',
      ),
      'RATE_LIMITED' => copy.text(
        'Troppe richieste. Attendi e riprova.',
        'Too many requests. Wait and try again.',
      ),
      'UNAUTHENTICATED' => copy.text(
        'Accedi per continuare.',
        'Sign in to continue.',
      ),
      _ => copy.text(
        'Operazione non riuscita. Riprova.',
        'The operation failed. Try again.',
      ),
    };

class CustomerStateView<T> extends StatelessWidget {
  const CustomerStateView({
    required this.value,
    required this.emptyMessage,
    required this.data,
    required this.onRetry,
    super.key,
  });
  final AsyncValue<T> value;
  final String emptyMessage;
  final bool Function(T value) isEmpty = _neverEmpty;
  final Widget Function(T value) data;
  final VoidCallback onRetry;
  static bool _neverEmpty(Object? value) => false;
  @override
  Widget build(BuildContext context) => value.when(
    loading:
        () => Center(
          child: Semantics(
            label: CustomerCopy.of(context).text('Caricamento', 'Loading'),
            child: CircularProgressIndicator(),
          ),
        ),
    error: (error, _) {
      final copy = CustomerCopy.of(context);
      final message =
          error is CustomerApiException
              ? _localizedApiFailure(copy, error)
              : copy.text(
                'Impossibile caricare i dati.',
                'Unable to load data.',
              );
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 44),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(copy.text('Riprova', 'Retry')),
            ),
          ],
        ),
      );
    },
    data: data,
  );
}

class CustomerHomePage extends StatelessWidget {
  const CustomerHomePage({super.key});
  @override
  Widget build(BuildContext context) {
    final copy = CustomerCopy.of(context);
    final destinations = <(IconData, String, String)>[
      (Icons.restaurant_menu, copy.text('Menu', 'Menu'), '/menu'),
      (Icons.shopping_bag_outlined, copy.text('Carrello', 'Cart'), '/cart'),
      (Icons.receipt_long_outlined, copy.text('Ordini', 'Orders'), '/orders'),
      (
        Icons.favorite_outline,
        copy.text('Preferiti', 'Favorites'),
        '/favorites',
      ),
      (Icons.stars_outlined, copy.text('Premi', 'Rewards'), '/rewards'),
      (
        Icons.notifications_outlined,
        copy.text('Notifiche', 'Notifications'),
        '/notifications',
      ),
      (Icons.support_agent, copy.text('Assistenza', 'Support'), '/support'),
      (Icons.person_outline, copy.text('Account', 'Account'), '/account'),
    ];
    return CustomerRouteFrame(
      title: copy.text('La tua La Favola', 'Your La Favola'),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final largeText = MediaQuery.textScalerOf(context).scale(16) >= 24;
          final columns =
              constraints.maxWidth >= 720 && !largeText
                  ? 3
                  : constraints.maxWidth >= 420 && !largeText
                  ? 2
                  : 1;
          return GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisExtent: largeText ? 112 : 104,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: destinations.length,
            itemBuilder: (context, index) {
              final item = destinations[index];
              return Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => context.push(item.$3),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(item.$1, size: 32),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            item.$2,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class FavoritesPage extends ConsumerWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final copy = CustomerCopy.of(context);
    final value = ref.watch(favoritesProvider);
    return CustomerRouteFrame(
      title: copy.text('Preferiti', 'Favorites'),
      child: CustomerStateView(
        value: value,
        emptyMessage: '',
        onRetry: () => ref.invalidate(favoritesProvider),
        data: (items) {
          if (items.isEmpty) {
            return _Empty(
              icon: Icons.favorite_outline,
              text: copy.text(
                'Non hai ancora preferiti.',
                'You have no favorites yet.',
              ),
              action: () => context.push('/menu'),
              actionLabel: copy.text('Scopri il menu', 'Browse menu'),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(favoritesProvider),
            child: ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = items[index];
                return Card(
                  child: ListTile(
                    title: Text(item.name),
                    subtitle: item.details.isEmpty ? null : Text(item.details),
                    leading: const Icon(Icons.favorite),
                    trailing: PopupMenuButton<String>(
                      onSelected: (action) async {
                        final repo = ref.read(favoritesRepositoryProvider);
                        if (action == 'cart') {
                          await repo.addToCart(item.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  copy.text(
                                    'Aggiunto al carrello',
                                    'Added to cart',
                                  ),
                                ),
                              ),
                            );
                          }
                        } else {
                          await repo.removeFavorite(item.id);
                        }
                        ref.invalidate(favoritesProvider);
                      },
                      itemBuilder:
                          (_) => [
                            PopupMenuItem(
                              value: 'cart',
                              child: Text(
                                copy.text(
                                  'Aggiungi al carrello',
                                  'Add to cart',
                                ),
                              ),
                            ),
                            PopupMenuItem(
                              value: 'remove',
                              child: Text(copy.text('Rimuovi', 'Remove')),
                            ),
                          ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class RewardsPage extends ConsumerWidget {
  const RewardsPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final copy = CustomerCopy.of(context);
    final value = ref.watch(rewardsProvider);
    return CustomerRouteFrame(
      title: copy.text('Premi', 'Rewards'),
      child: CustomerStateView(
        value: value,
        emptyMessage: '',
        onRetry: () => ref.invalidate(rewardsProvider),
        data:
            (snapshot) => ListView(
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Text(
                          '${snapshot.balance}',
                          style: Theme.of(context).textTheme.displaySmall,
                        ),
                        Text(
                          copy.text('punti disponibili', 'available points'),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: null,
                          icon: const Icon(Icons.lock_clock_outlined),
                          label: Text(
                            copy.text(
                              'Riscatto disponibile su un ordine idoneo',
                              'Redemption is available on an eligible order',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  copy.text('Attività', 'Activity'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                if (snapshot.history.isEmpty)
                  _Empty(
                    icon: Icons.stars_outlined,
                    text: copy.text(
                      'Nessuna attività premi.',
                      'No reward activity yet.',
                    ),
                  )
                else
                  for (final item in snapshot.history)
                    ListTile(
                      leading: CircleAvatar(
                        child: Text(
                          item.points >= 0
                              ? '+${item.points}'
                              : '${item.points}',
                        ),
                      ),
                      title: Text(item.title),
                      subtitle: Text(item.subtitle),
                    ),
              ],
            ),
      ),
    );
  }
}

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final copy = CustomerCopy.of(context);
    final value = ref.watch(notificationsProvider);
    return CustomerRouteFrame(
      title: copy.text('Notifiche', 'Notifications'),
      child: CustomerStateView(
        value: value,
        emptyMessage: '',
        onRetry: () => ref.invalidate(notificationsProvider),
        data:
            (items) =>
                items.isEmpty
                    ? _Empty(
                      icon: Icons.notifications_none,
                      text: copy.text('Nessuna notifica.', 'No notifications.'),
                    )
                    : RefreshIndicator(
                      onRefresh:
                          () async => ref.invalidate(notificationsProvider),
                      child: ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return Card(
                            child: ListTile(
                              leading: Icon(
                                item.read
                                    ? Icons.drafts_outlined
                                    : Icons.mark_email_unread_outlined,
                              ),
                              title: Text(item.title),
                              subtitle: Text(item.body),
                              onTap:
                                  item.read
                                      ? null
                                      : () async {
                                        await ref
                                            .read(
                                              notificationsRepositoryProvider,
                                            )
                                            .markRead(item.id);
                                        ref.invalidate(notificationsProvider);
                                      },
                            ),
                          );
                        },
                      ),
                    ),
      ),
    );
  }
}

class SupportPage extends ConsumerWidget {
  const SupportPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final copy = CustomerCopy.of(context);
    final value = ref.watch(supportTicketsProvider);
    return CustomerRouteFrame(
      title: copy.text('Assistenza', 'Support'),
      actions: [
        IconButton(
          tooltip: copy.text('Nuova richiesta', 'New request'),
          onPressed: () => _create(context, ref),
          icon: const Icon(Icons.add_comment_outlined),
        ),
      ],
      child: CustomerStateView(
        value: value,
        emptyMessage: '',
        onRetry: () => ref.invalidate(supportTicketsProvider),
        data:
            (items) =>
                items.isEmpty
                    ? _Empty(
                      icon: Icons.support_agent,
                      text: copy.text(
                        'Nessuna richiesta di assistenza.',
                        'No support requests.',
                      ),
                      action: () => _create(context, ref),
                      actionLabel: copy.text('Nuova richiesta', 'New request'),
                    )
                    : ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return Card(
                          child: ListTile(
                            title: Text(item.subject),
                            subtitle: Text(item.preview),
                            trailing: Chip(label: Text(item.status)),
                            onTap:
                                () => context.push(
                                  '/support/${item.id}',
                                  extra: item.subject,
                                ),
                          ),
                        );
                      },
                    ),
      ),
    );
  }

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final copy = CustomerCopy.of(context);
    final subject = TextEditingController();
    final message = TextEditingController();
    var category = 'general';
    final submit = await showDialog<bool>(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  title: Text(copy.text('Nuova richiesta', 'New request')),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DropdownButtonFormField<String>(
                          value: category,
                          decoration: InputDecoration(
                            labelText: copy.text('Categoria', 'Category'),
                          ),
                          items: [
                            DropdownMenuItem(
                              value: 'general',
                              child: Text(copy.text('Generale', 'General')),
                            ),
                            DropdownMenuItem(
                              value: 'order_issue',
                              child: Text(
                                copy.text('Problema ordine', 'Order issue'),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'payment_issue',
                              child: Text(
                                copy.text(
                                  'Problema pagamento',
                                  'Payment issue',
                                ),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'delivery_issue',
                              child: Text(
                                copy.text(
                                  'Problema consegna',
                                  'Delivery issue',
                                ),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'refund_request',
                              child: Text(
                                copy.text(
                                  'Richiesta rimborso',
                                  'Refund request',
                                ),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'complaint',
                              child: Text(copy.text('Reclamo', 'Complaint')),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setDialogState(() => category = value);
                            }
                          },
                        ),
                        TextField(
                          controller: subject,
                          maxLength: 200,
                          decoration: InputDecoration(
                            labelText: copy.text('Oggetto', 'Subject'),
                          ),
                        ),
                        TextField(
                          controller: message,
                          minLines: 3,
                          maxLines: 5,
                          maxLength: 5000,
                          decoration: InputDecoration(
                            labelText: copy.text('Messaggio', 'Message'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(copy.text('Annulla', 'Cancel')),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(copy.text('Invia', 'Send')),
                    ),
                  ],
                ),
          ),
    );
    if (submit == true &&
        subject.text.trim().isNotEmpty &&
        message.text.trim().isNotEmpty) {
      await ref
          .read(supportRepositoryProvider)
          .create(
            category: category,
            subject: subject.text.trim(),
            message: message.text.trim(),
          );
      ref.invalidate(supportTicketsProvider);
    }
    subject.dispose();
    message.dispose();
  }
}

class SupportConversationPage extends ConsumerStatefulWidget {
  const SupportConversationPage({
    required this.ticketId,
    required this.subject,
    super.key,
  });
  final String ticketId;
  final String subject;
  @override
  ConsumerState<SupportConversationPage> createState() =>
      _SupportConversationPageState();
}

class _SupportConversationPageState
    extends ConsumerState<SupportConversationPage> {
  late Future<List<String>> messages;
  final input = TextEditingController();
  @override
  void initState() {
    super.initState();
    messages = ref.read(supportRepositoryProvider).messages(widget.ticketId);
  }

  @override
  void dispose() {
    input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final copy = CustomerCopy.of(context);
    return CustomerRouteFrame(
      title: widget.subject,
      child: Column(
        children: [
          Expanded(
            child: FutureBuilder<List<String>>(
              future: messages,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return _Failure(
                    error: snapshot.error,
                    retry:
                        () => setState(
                          () =>
                              messages = ref
                                  .read(supportRepositoryProvider)
                                  .messages(widget.ticketId),
                        ),
                  );
                }
                final values = snapshot.data ?? const [];
                return values.isEmpty
                    ? _Empty(
                      icon: Icons.forum_outlined,
                      text: copy.text(
                        'Inizia la conversazione.',
                        'Start the conversation.',
                      ),
                    )
                    : ListView.builder(
                      itemCount: values.length,
                      itemBuilder:
                          (_, index) => Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(values[index]),
                            ),
                          ),
                    );
              },
            ),
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: input,
                  decoration: InputDecoration(
                    labelText: copy.text('Messaggio', 'Message'),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                tooltip: copy.text('Invia', 'Send'),
                onPressed: () async {
                  final value = input.text.trim();
                  if (value.isEmpty) return;
                  await ref
                      .read(supportRepositoryProvider)
                      .sendMessage(widget.ticketId, value);
                  input.clear();
                  setState(
                    () =>
                        messages = ref
                            .read(supportRepositoryProvider)
                            .messages(widget.ticketId),
                  );
                },
                icon: const Icon(Icons.send),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class FaqPage extends ConsumerStatefulWidget {
  const FaqPage({super.key});
  @override
  ConsumerState<FaqPage> createState() => _FaqPageState();
}

class _FaqPageState extends ConsumerState<FaqPage> {
  String search = '';
  @override
  Widget build(BuildContext context) {
    final copy = CustomerCopy.of(context);
    final value = ref.watch(faqProvider(search));
    return CustomerRouteFrame(
      title: copy.text('Domande frequenti', 'Frequently asked questions'),
      child: Column(
        children: [
          SearchBar(
            hintText: copy.text('Cerca una risposta', 'Search for an answer'),
            leading: const Icon(Icons.search),
            onChanged: (value) => setState(() => search = value),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: CustomerStateView(
              value: value,
              emptyMessage: '',
              onRetry: () => ref.invalidate(faqProvider(search)),
              data:
                  (items) =>
                      items.isEmpty
                          ? _Empty(
                            icon: Icons.help_outline,
                            text: copy.text(
                              'Nessuna risposta trovata.',
                              'No answers found.',
                            ),
                          )
                          : ListView.builder(
                            itemCount: items.length,
                            itemBuilder: (_, index) {
                              final item = items[index];
                              return Card(
                                child: ExpansionTile(
                                  title: Text(item.question),
                                  subtitle:
                                      item.category.isEmpty
                                          ? null
                                          : Text(item.category),
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        16,
                                        0,
                                        16,
                                        16,
                                      ),
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(item.answer),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
            ),
          ),
        ],
      ),
    );
  }
}

class PaymentMethodsPage extends ConsumerWidget {
  const PaymentMethodsPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final copy = CustomerCopy.of(context);
    final value = ref.watch(paymentMethodsProvider);
    return CustomerRouteFrame(
      title: copy.text('Metodi di pagamento', 'Payment methods'),
      child: CustomerStateView(
        value: value,
        emptyMessage: '',
        onRetry: () => ref.invalidate(paymentMethodsProvider),
        data:
            (items) =>
                items.isEmpty
                    ? _Empty(
                      icon: Icons.credit_card_off_outlined,
                      text: copy.text(
                        'Nessun metodo salvato.',
                        'No saved payment methods.',
                      ),
                    )
                    : ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (_, index) {
                        final item = items[index];
                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.credit_card),
                            title: Text(item.label),
                            subtitle: Text(item.expiry),
                            trailing:
                                item.isDefault
                                    ? Chip(
                                      label: Text(
                                        copy.text('Predefinito', 'Default'),
                                      ),
                                    )
                                    : PopupMenuButton<String>(
                                      onSelected: (action) async {
                                        final repo = ref.read(
                                          paymentMethodsRepositoryProvider,
                                        );
                                        if (action == 'default') {
                                          await repo.makeDefault(item.id);
                                        }
                                        if (action == 'remove') {
                                          await repo.removePaymentMethod(
                                            item.id,
                                          );
                                        }
                                        ref.invalidate(paymentMethodsProvider);
                                      },
                                      itemBuilder:
                                          (_) => [
                                            PopupMenuItem(
                                              value: 'default',
                                              child: Text(
                                                copy.text(
                                                  'Imposta predefinito',
                                                  'Make default',
                                                ),
                                              ),
                                            ),
                                            PopupMenuItem(
                                              value: 'remove',
                                              child: Text(
                                                copy.text('Rimuovi', 'Remove'),
                                              ),
                                            ),
                                          ],
                                    ),
                          ),
                        );
                      },
                    ),
      ),
    );
  }
}

class CartPage extends ConsumerWidget {
  const CartPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final copy = CustomerCopy.of(context);
    final value = ref.watch(cartProvider);
    return CustomerRouteFrame(
      title: copy.text('Carrello', 'Cart'),
      child: CustomerStateView(
        value: value,
        emptyMessage: '',
        onRetry: () => ref.invalidate(cartProvider),
        data:
            (cart) =>
                cart.isEmpty
                    ? _Empty(
                      icon: Icons.shopping_bag_outlined,
                      text: copy.text(
                        'Il carrello è vuoto.',
                        'Your cart is empty.',
                      ),
                      action: () => context.push('/menu'),
                      actionLabel: copy.text('Vai al menu', 'Browse menu'),
                    )
                    : Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            itemCount: cart.lines.length,
                            itemBuilder: (_, index) {
                              final line = cart.lines[index];
                              return Card(
                                child: ListTile(
                                  title: Text(line.name),
                                  subtitle: Text(
                                    '${copy.text('Quantità', 'Quantity')}: ${line.quantity}',
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        tooltip: copy.text(
                                          'Riduci quantità',
                                          'Decrease quantity',
                                        ),
                                        onPressed: () async {
                                          final repo = ref.read(
                                            cartRepositoryProvider,
                                          );
                                          if (line.quantity <= 1) {
                                            await repo.removeLine(line.id);
                                          } else {
                                            await repo.updateLine(
                                              line.id,
                                              line.quantity - 1,
                                            );
                                          }
                                          ref.invalidate(cartProvider);
                                        },
                                        icon: const Icon(
                                          Icons.remove_circle_outline,
                                        ),
                                      ),
                                      Semantics(
                                        label: copy.text(
                                          'Quantità',
                                          'Quantity',
                                        ),
                                        value: '${line.quantity}',
                                        child: Text('${line.quantity}'),
                                      ),
                                      IconButton(
                                        tooltip: copy.text(
                                          'Aumenta quantità',
                                          'Increase quantity',
                                        ),
                                        onPressed: () async {
                                          await ref
                                              .read(cartRepositoryProvider)
                                              .updateLine(
                                                line.id,
                                                line.quantity + 1,
                                              );
                                          ref.invalidate(cartProvider);
                                        },
                                        icon: const Icon(
                                          Icons.add_circle_outline,
                                        ),
                                      ),
                                      IconButton(
                                        tooltip: copy.text(
                                          'Rimuovi articolo',
                                          'Remove item',
                                        ),
                                        onPressed: () async {
                                          await ref
                                              .read(cartRepositoryProvider)
                                              .removeLine(line.id);
                                          ref.invalidate(cartProvider);
                                        },
                                        icon: const Icon(Icons.delete_outline),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    copy.text(
                                      'Totale indicativo',
                                      'Current total',
                                    ),
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                  ),
                                ),
                                Text(
                                  _money(cart.totalMinor, cart.currency),
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            TextButton(
                              onPressed: () async {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder:
                                      (_) => AlertDialog(
                                        title: Text(
                                          copy.text(
                                            'Svuotare il carrello?',
                                            'Clear cart?',
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed:
                                                () => Navigator.pop(
                                                  context,
                                                  false,
                                                ),
                                            child: Text(
                                              copy.text('Annulla', 'Cancel'),
                                            ),
                                          ),
                                          FilledButton(
                                            onPressed:
                                                () => Navigator.pop(
                                                  context,
                                                  true,
                                                ),
                                            child: Text(
                                              copy.text('Svuota', 'Clear'),
                                            ),
                                          ),
                                        ],
                                      ),
                                );
                                if (confirmed == true) {
                                  await ref
                                      .read(cartRepositoryProvider)
                                      .clear();
                                  ref.invalidate(cartProvider);
                                }
                              },
                              child: Text(copy.text('Svuota', 'Clear')),
                            ),
                            const Spacer(),
                            FilledButton.icon(
                              onPressed: () => context.push('/checkout'),
                              icon: const Icon(Icons.lock_outline),
                              label: Text(copy.text('Continua', 'Continue')),
                            ),
                          ],
                        ),
                      ],
                    ),
      ),
    );
  }
}

class CheckoutRoutePage extends ConsumerStatefulWidget {
  const CheckoutRoutePage({super.key});
  @override
  ConsumerState<CheckoutRoutePage> createState() => _CheckoutRoutePageState();
}

class _CheckoutRoutePageState extends ConsumerState<CheckoutRoutePage> {
  FulfillmentType type = FulfillmentType.pickup;
  List<CustomerAddress> addresses = const [];
  FulfillmentAvailability? availability;
  String? addressId;
  String? scheduledFor;
  bool loadingOptions = true;
  bool submitting = false;
  Object? failure;
  String? _idempotencyKey;

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  Future<void> _loadOptions() async {
    setState(() {
      loadingOptions = true;
      failure = null;
    });
    try {
      final gateway = ref.read(customerGatewayProvider);
      final results = await Future.wait<Object>([
        gateway.getFulfillmentAvailability(type: type),
        if (type == FulfillmentType.delivery) gateway.getAddresses(),
      ]);
      availability = results.first as FulfillmentAvailability;
      addresses =
          type == FulfillmentType.delivery
              ? results[1] as List<CustomerAddress>
              : const [];
      addressId =
          addresses
              .where((value) => value.archivedAt == null)
              .map((value) => value.id)
              .cast<String?>()
              .firstOrNull;
      scheduledFor =
          availability!.asapAvailable
              ? null
              : availability!.slots.firstOrNull?.scheduledFor;
    } catch (error) {
      failure = error;
    } finally {
      if (mounted) setState(() => loadingOptions = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final copy = CustomerCopy.of(context);
    final cartValue = ref.watch(cartProvider);
    return CustomerRouteFrame(
      title: copy.text('Checkout', 'Checkout'),
      child: CustomerStateView(
        value: cartValue,
        emptyMessage: '',
        onRetry: () => ref.invalidate(cartProvider),
        data: (cart) {
          if (cart.isEmpty) {
            return _Empty(
              icon: Icons.remove_shopping_cart_outlined,
              text: copy.text(
                'Aggiungi articoli prima del checkout.',
                'Add items before checkout.',
              ),
              action: () => context.push('/menu'),
              actionLabel: copy.text('Vai al menu', 'Browse menu'),
            );
          }
          return ListView(
            children: [
              SegmentedButton<FulfillmentType>(
                segments: [
                  ButtonSegment(
                    value: FulfillmentType.pickup,
                    icon: const Icon(Icons.storefront),
                    label: Text(copy.text('Ritiro', 'Pickup')),
                  ),
                  ButtonSegment(
                    value: FulfillmentType.delivery,
                    icon: const Icon(Icons.delivery_dining),
                    label: Text(copy.text('Consegna', 'Delivery')),
                  ),
                ],
                selected: {type},
                onSelectionChanged: (value) {
                  setState(() => type = value.single);
                  _loadOptions();
                },
              ),
              const SizedBox(height: 16),
              if (loadingOptions)
                const Center(child: CircularProgressIndicator())
              else if (failure != null)
                _Failure(error: failure, retry: _loadOptions)
              else ...[
                if (type == FulfillmentType.delivery)
                  DropdownButtonFormField<String>(
                    value: addressId,
                    decoration: InputDecoration(
                      labelText: copy.text(
                        'Indirizzo di consegna',
                        'Delivery address',
                      ),
                    ),
                    items: [
                      for (final address in addresses.where(
                        (value) => value.archivedAt == null,
                      ))
                        DropdownMenuItem(
                          value: address.id,
                          child: Text(
                            '${address.label} — ${address.addressLine}',
                          ),
                        ),
                    ],
                    onChanged: (value) => setState(() => addressId = value),
                  ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  value: scheduledFor,
                  decoration: InputDecoration(
                    labelText: copy.text('Orario', 'Time'),
                  ),
                  items: [
                    if (availability!.asapAvailable)
                      DropdownMenuItem(
                        value: null,
                        child: Text(
                          copy.text('Prima possibile', 'As soon as possible'),
                        ),
                      ),
                    for (final slot in availability!.slots)
                      DropdownMenuItem(
                        value: slot.scheduledFor,
                        child: Text(slot.localTime),
                      ),
                  ],
                  onChanged: (value) => setState(() => scheduledFor = value),
                ),
                const SizedBox(height: 16),
                for (final line in cart.lines)
                  ListTile(
                    title: Text(line.name),
                    subtitle: Text('× ${line.quantity}'),
                    trailing: Text(_money(line.totalMinor, cart.currency)),
                  ),
                const Divider(),
                ListTile(
                  title: Text(
                    copy.text(
                      'Totale verificato al checkout',
                      'Total verified at checkout',
                    ),
                  ),
                  trailing: Text(_money(cart.totalMinor, cart.currency)),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 56,
                  child: FilledButton.icon(
                    onPressed:
                        submitting ||
                                cart.id.isEmpty ||
                                (type == FulfillmentType.delivery &&
                                    addressId == null)
                            ? null
                            : () => _submit(cart),
                    icon: const Icon(Icons.lock_outline),
                    label: Text(
                      copy.text(
                        'Invia ordine con pagamento in contanti',
                        'Place cash order',
                      ),
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _submit(CartSnapshot cart) async {
    final copy = CustomerCopy.of(context);
    setState(() {
      submitting = true;
      failure = null;
    });
    try {
      final key =
          _idempotencyKey ??=
              'customer-${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}';
      final result = await ref
          .read(cartRepositoryProvider)
          .checkout(
            cartId: cart.id,
            orderType: type.name,
            deliveryAddressId:
                type == FulfillmentType.delivery ? addressId : null,
            paymentMethod: 'cash',
            scheduledFor: scheduledFor,
            idempotencyKey: key,
          );
      _idempotencyKey = null;
      ref.invalidate(cartProvider);
      if (mounted) {
        final reference = result['orderNumber']?.toString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              copy.text(
                'Ordine ${reference ?? ''} inviato.',
                'Order ${reference ?? ''} placed.',
              ),
            ),
          ),
        );
        context.go('/orders');
      }
    } catch (error) {
      if (mounted) {
        setState(() => failure = error);
        SemanticsService.announce(
          copy.text(
            'Ordine non inviato. Riprova.',
            'Order was not placed. Try again.',
          ),
          TextDirection.ltr,
        );
      }
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }
}

class AccountHubPage extends ConsumerWidget {
  const AccountHubPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final copy = CustomerCopy.of(context);
    final rows = [
      (
        Icons.person_outline,
        copy.text('Profilo', 'Profile'),
        '/account/profile',
      ),
      (
        Icons.location_on_outlined,
        copy.text('Indirizzi', 'Addresses'),
        '/account/addresses',
      ),
      (
        Icons.tune,
        copy.text('Preferenze e sicurezza', 'Preferences and security'),
        '/account/preferences',
      ),
      (
        Icons.privacy_tip_outlined,
        copy.text('Privacy', 'Privacy'),
        '/account/privacy',
      ),
      (
        Icons.credit_card,
        copy.text('Metodi di pagamento', 'Payment methods'),
        '/payment-methods',
      ),
      (Icons.help_outline, copy.text('Domande frequenti', 'FAQ'), '/faq'),
    ];
    return CustomerRouteFrame(
      title: copy.text('Account', 'Account'),
      child: ListView(
        children: [
          for (final row in rows)
            Card(
              child: ListTile(
                minVerticalPadding: 16,
                leading: Icon(row.$1),
                title: Text(row.$2),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(row.$3),
              ),
            ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed:
                () => ref.read(customerSessionProvider.notifier).signOut(),
            icon: const Icon(Icons.logout),
            label: Text(copy.text('Esci', 'Sign out')),
          ),
        ],
      ),
    );
  }
}

class OrderDetailRoutePage extends ConsumerStatefulWidget {
  const OrderDetailRoutePage({required this.orderId, super.key});
  final String orderId;
  @override
  ConsumerState<OrderDetailRoutePage> createState() =>
      _OrderDetailRoutePageState();
}

class _OrderDetailRoutePageState extends ConsumerState<OrderDetailRoutePage> {
  late Future<OrderReceipt> order;
  @override
  void initState() {
    super.initState();
    order = ref.read(customerGatewayProvider).getOrder(widget.orderId);
  }

  @override
  Widget build(BuildContext context) {
    final copy = CustomerCopy.of(context);
    return CustomerRouteFrame(
      title: copy.text('Dettaglio ordine', 'Order detail'),
      child: FutureBuilder<OrderReceipt>(
        future: order,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _Failure(
              error: snapshot.error,
              retry:
                  () => setState(
                    () =>
                        order = ref
                            .read(customerGatewayProvider)
                            .getOrder(widget.orderId),
                  ),
            );
          }
          final value = snapshot.data!;
          return ListView(
            children: [
              Card(
                child: ListTile(
                  leading: const Icon(Icons.receipt_long),
                  title: Text(value.reference),
                  subtitle: Text(value.status),
                  trailing: Text(_money(value.totalMinor, value.currency)),
                ),
              ),
              if (value.etaMinutes != null)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.schedule),
                    title: Text(copy.text('Tempo stimato', 'Estimated time')),
                    subtitle: Text('${value.etaMinutes} min'),
                  ),
                ),
              for (final event in value.timeline)
                ListTile(
                  leading: const Icon(Icons.check_circle_outline),
                  title: Text(event.nextStatus ?? event.type),
                  subtitle: Text(event.occurredAt),
                ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _receipt(context),
                    icon: const Icon(Icons.description_outlined),
                    label: Text(copy.text('Ricevuta', 'Receipt')),
                  ),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await ref
                          .read(cartRepositoryProvider)
                          .reorder(widget.orderId);
                      if (context.mounted) context.push('/cart');
                    },
                    icon: const Icon(Icons.replay),
                    label: Text(copy.text('Riordina', 'Reorder')),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: () => _cancel(context, value),
                    icon: const Icon(Icons.cancel_outlined),
                    label: Text(copy.text('Annulla ordine', 'Cancel order')),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _receipt(BuildContext context) async {
    final copy = CustomerCopy.of(context);
    final receipt = await ref
        .read(customerGatewayProvider)
        .getOrderReceipt(widget.orderId);
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text(copy.text('Ricevuta ordine', 'Order receipt')),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    receipt.restaurant.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(receipt.notice),
                  const Divider(),
                  for (final item in receipt.order.items)
                    Text('${item.quantity} × ${item.name}'),
                  const Divider(),
                  Text(
                    _money(
                      receipt.order.totals.grandTotalMinor,
                      receipt.order.currency,
                    ),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(copy.text('Chiudi', 'Close')),
              ),
            ],
          ),
    );
  }

  Future<void> _cancel(BuildContext context, OrderReceipt value) async {
    final copy = CustomerCopy.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text(
              copy.text('Annullare questo ordine?', 'Cancel this order?'),
            ),
            content: Text(
              copy.text(
                'La possibilità di annullamento sarà verificata dal ristorante.',
                'Cancellation eligibility will be verified by the restaurant.',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(copy.text('Indietro', 'Back')),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  copy.text('Richiedi annullamento', 'Request cancellation'),
                ),
              ),
            ],
          ),
    );
    if (confirmed == true) {
      await ref
          .read(customerGatewayProvider)
          .requestOrderCancellation(
            orderId: widget.orderId,
            expectedVersion: value.version,
            reason: 'customer_request',
          );
      setState(
        () =>
            order = ref.read(customerGatewayProvider).getOrder(widget.orderId),
      );
    }
  }
}

class _Empty extends StatelessWidget {
  const _Empty({
    required this.icon,
    required this.text,
    this.action,
    this.actionLabel,
  });
  final IconData icon;
  final String text;
  final VoidCallback? action;
  final String? actionLabel;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48),
          const SizedBox(height: 12),
          Text(text, textAlign: TextAlign.center),
          if (action != null) ...[
            const SizedBox(height: 16),
            FilledButton(
              onPressed: action,
              child: Text(actionLabel ?? 'Continue'),
            ),
          ],
        ],
      ),
    ),
  );
}

class _Failure extends StatelessWidget {
  const _Failure({required this.error, required this.retry});
  final Object? error;
  final VoidCallback retry;
  @override
  Widget build(BuildContext context) {
    final copy = CustomerCopy.of(context);
    return _Empty(
      icon: Icons.cloud_off_outlined,
      text:
          error is CustomerApiException
              ? (error as CustomerApiException).message
              : copy.text(
                'Operazione non disponibile.',
                'Operation unavailable.',
              ),
      action: retry,
      actionLabel: copy.text('Riprova', 'Retry'),
    );
  }
}

String _money(int minor, String currency) =>
    '${(minor / 100).toStringAsFixed(2)} $currency';
