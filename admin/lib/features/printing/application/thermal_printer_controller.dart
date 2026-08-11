import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_thermal_printer/flutter_thermal_printer.dart';
import 'package:flutter_thermal_printer/network/network_print_result.dart';
import 'package:flutter_thermal_printer/utils/printer.dart';
import 'package:la_favola_admin/features/pos/domain/pos_models.dart';

enum ReceiptPaper { mm58, mm80 }

class ThermalPrinterState {
  const ThermalPrinterState({
    this.printers = const [],
    this.selected,
    this.paper = ReceiptPaper.mm80,
    this.networkHost = '',
    this.networkPort = 9100,
    this.scanning = false,
    this.connecting = false,
    this.printing = false,
    this.message,
  });
  final List<Printer> printers;
  final Printer? selected;
  final ReceiptPaper paper;
  final String networkHost;
  final int networkPort;
  final bool scanning;
  final bool connecting;
  final bool printing;
  final String? message;

  ThermalPrinterState copyWith({
    List<Printer>? printers,
    Printer? selected,
    bool clearSelected = false,
    ReceiptPaper? paper,
    String? networkHost,
    int? networkPort,
    bool? scanning,
    bool? connecting,
    bool? printing,
    String? message,
    bool clearMessage = false,
  }) => ThermalPrinterState(
    printers: printers ?? this.printers,
    selected: clearSelected ? null : selected ?? this.selected,
    paper: paper ?? this.paper,
    networkHost: networkHost ?? this.networkHost,
    networkPort: networkPort ?? this.networkPort,
    scanning: scanning ?? this.scanning,
    connecting: connecting ?? this.connecting,
    printing: printing ?? this.printing,
    message: clearMessage ? null : message ?? this.message,
  );
}

class ThermalPrinterController extends StateNotifier<ThermalPrinterState> {
  ThermalPrinterController({
    FlutterThermalPrinter? plugin,
    FlutterSecureStorage? storage,
  }) : _plugin = plugin ?? FlutterThermalPrinter.instance,
       _storage = storage ?? const FlutterSecureStorage(),
       super(const ThermalPrinterState()) {
    unawaited(_restore());
  }

  static const _settingsKey = 'lafavola_admin_thermal_printer';
  final FlutterThermalPrinter _plugin;
  final FlutterSecureStorage _storage;
  StreamSubscription<List<Printer>>? _subscription;

  Future<void> scan() async {
    state = state.copyWith(scanning: true, clearMessage: true);
    await _subscription?.cancel();
    _subscription = _plugin.devicesStream.listen(
      (devices) => state = state.copyWith(printers: devices),
      onError:
          (_) =>
              state = state.copyWith(
                scanning: false,
                message:
                    'Ricerca stampanti non disponibile. Verifica i permessi.',
              ),
    );
    try {
      await _plugin.getPrinters(
        refreshDuration: const Duration(seconds: 4),
        connectionTypes: const [ConnectionType.USB, ConnectionType.BLE],
      );
    } catch (_) {
      state = state.copyWith(
        message: 'Bluetooth/USB non disponibile su questo dispositivo.',
      );
    } finally {
      state = state.copyWith(scanning: false);
    }
  }

  Future<void> stopScan() async {
    await _plugin.stopScan();
    state = state.copyWith(scanning: false);
  }

  Future<void> select(Printer printer) async {
    state = state.copyWith(connecting: true, clearMessage: true);
    try {
      final connected =
          printer.isConnected == true || await _plugin.connect(printer);
      if (!connected) throw StateError('connect failed');
      state = state.copyWith(selected: printer.copyWith(isConnected: true));
      await _save();
    } catch (_) {
      state = state.copyWith(
        message: 'Connessione alla stampante non riuscita. Riprova.',
      );
    } finally {
      state = state.copyWith(connecting: false);
    }
  }

  Future<void> setPaper(ReceiptPaper paper) async {
    state = state.copyWith(paper: paper);
    await _save();
  }

  Future<void> setNetwork(String host, int port) async {
    state = state.copyWith(
      networkHost: host.trim(),
      networkPort: port,
      clearMessage: true,
    );
    await _save();
  }

  Future<bool> printReceipt(PrintableReceipt receipt) async {
    state = state.copyWith(printing: true, clearMessage: true);
    try {
      final bytes = await _receiptBytes(receipt, state.paper);
      if (state.networkHost.isNotEmpty) {
        final service = FlutterThermalPrinterNetwork(
          state.networkHost,
          port: state.networkPort,
        );
        final connection = await service.connect();
        if (connection != NetworkPrintResult.success) {
          throw StateError('network connect');
        }
        final result = await service.printTicket(bytes);
        await service.disconnect();
        if (result != NetworkPrintResult.success) {
          throw StateError('network print');
        }
      } else {
        final printer = state.selected;
        if (printer == null) {
          state = state.copyWith(
            message: 'Seleziona una stampante Bluetooth/USB o inserisci un IP.',
          );
          return false;
        }
        if (printer.isConnected != true && !await _plugin.connect(printer)) {
          throw StateError('connect failed');
        }
        await _plugin.printData(printer, bytes, longData: true);
      }
      state = state.copyWith(message: 'Ricevuta inviata alla stampante.');
      return true;
    } catch (_) {
      state = state.copyWith(
        message:
            'Stampa non riuscita. Il pagamento resta registrato: puoi ristampare.',
      );
      return false;
    } finally {
      state = state.copyWith(printing: false);
    }
  }

  Future<void> disposePrinter() async {
    await _subscription?.cancel();
    await _plugin.stopScan();
  }

  Future<List<int>> _receiptBytes(
    PrintableReceipt receipt,
    ReceiptPaper paper,
  ) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(
      paper == ReceiptPaper.mm58 ? PaperSize.mm58 : PaperSize.mm80,
      profile,
    );
    final order = receipt.order;
    final restaurant = receipt.restaurant;
    final bytes = <int>[];
    bytes.addAll(
      generator.text(
        _safe(restaurant['name']?.toString() ?? 'LA FAVOLA'),
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ),
      ),
    );
    for (final line in [
      restaurant['addressLine1'],
      [
        restaurant['postalCode'],
        restaurant['city'],
      ].where((value) => value != null && '$value'.isNotEmpty).join(' '),
      restaurant['phone'],
      if (restaurant['vatNumber'] != null) 'P.IVA ${restaurant['vatNumber']}',
    ]) {
      if (line != null && '$line'.trim().isNotEmpty) {
        bytes.addAll(
          generator.text(
            _safe('$line'),
            styles: const PosStyles(align: PosAlign.center),
          ),
        );
      }
    }
    bytes.addAll(generator.hr());
    bytes.addAll(generator.text('Documento: ${_safe(receipt.documentNumber)}'));
    bytes.addAll(generator.text('Ordine: ${_safe('${order['orderNumber']}')}'));
    bytes.addAll(
      generator.text(
        order['orderType'] == 'dine_in'
            ? 'Servizio: Sala - Tavolo ${_safe('${order['tableLabel']}')}'
            : 'Servizio: Asporto',
      ),
    );
    bytes.addAll(
      generator.text(
        'Data: ${receipt.issuedAt.toLocal().toIso8601String().replaceFirst('T', ' ').substring(0, 16)}',
      ),
    );
    bytes.addAll(generator.hr());
    for (final item in receipt.items) {
      final quantity = _int(item['quantity']);
      final name = _safe(
        '${item['name']}${item['size'] == null ? '' : ' (${item['size']})'}',
      );
      bytes.addAll(
        generator.row([
          PosColumn(text: '$quantity x $name', width: 8),
          PosColumn(
            text: _money(_int(item['lineTotalMinor'])),
            width: 4,
            styles: const PosStyles(align: PosAlign.right),
          ),
        ]),
      );
      final options = item['options'];
      if (options is List) {
        for (final raw in options.whereType<Map>()) {
          bytes.addAll(generator.text('  + ${_safe('${raw['name']}')}'));
        }
      }
      if ('${item['specialInstructions'] ?? ''}'.trim().isNotEmpty) {
        bytes.addAll(
          generator.text('  Nota: ${_safe('${item['specialInstructions']}')}'),
        );
      }
    }
    bytes.addAll(generator.hr());
    bytes.addAll(
      _totalRow(generator, 'Subtotale', _int(order['subtotalMinor'])),
    );
    if (_int(order['optionChargesMinor']) != 0) {
      bytes.addAll(
        _totalRow(generator, 'Opzioni', _int(order['optionChargesMinor'])),
      );
    }
    if (_int(order['discountMinor']) != 0) {
      bytes.addAll(
        _totalRow(generator, 'Sconto', -_int(order['discountMinor'])),
      );
    }
    bytes.addAll(_totalRow(generator, 'IVA', _int(order['taxMinor'])));
    bytes.addAll(
      generator.row([
        PosColumn(
          text: 'TOTALE',
          width: 6,
          styles: const PosStyles(bold: true),
        ),
        PosColumn(
          text: _money(receipt.totalMinor),
          width: 6,
          styles: const PosStyles(align: PosAlign.right, bold: true),
        ),
      ]),
    );
    bytes.addAll(
      generator.text(
        order['paymentMethod'] == 'cash'
            ? 'Pagamento: Contanti'
            : 'Pagamento: Carta / terminale',
      ),
    );
    bytes.addAll(generator.feed(1));
    bytes.addAll(
      generator.text(
        _safe(receipt.fiscalNotice),
        styles: const PosStyles(align: PosAlign.center, bold: true),
      ),
    );
    bytes.addAll(
      generator.text(
        'Grazie e buona appetito!',
        styles: const PosStyles(align: PosAlign.center),
      ),
    );
    bytes.addAll(generator.feed(2));
    bytes.addAll(generator.cut());
    return bytes;
  }

  List<int> _totalRow(Generator generator, String label, int value) =>
      generator.row([
        PosColumn(text: label, width: 6),
        PosColumn(
          text: _money(value),
          width: 6,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);

  Future<void> _restore() async {
    final raw = await _storage.read(key: _settingsKey);
    if (raw == null) return;
    try {
      final json = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      state = state.copyWith(
        selected:
            json['printer'] is Map
                ? Printer.fromJson(
                  Map<String, dynamic>.from(json['printer'] as Map),
                )
                : null,
        paper: json['paper'] == 'mm58' ? ReceiptPaper.mm58 : ReceiptPaper.mm80,
        networkHost: json['networkHost']?.toString() ?? '',
        networkPort:
            _int(json['networkPort']) == 0 ? 9100 : _int(json['networkPort']),
      );
    } catch (_) {
      await _storage.delete(key: _settingsKey);
    }
  }

  Future<void> _save() => _storage.write(
    key: _settingsKey,
    value: jsonEncode({
      'printer': state.selected?.toJson(),
      'paper': state.paper.name,
      'networkHost': state.networkHost,
      'networkPort': state.networkPort,
    }),
  );

  String _safe(String value) => value
      .replaceAll('à', 'a')
      .replaceAll('è', 'e')
      .replaceAll('é', 'e')
      .replaceAll('ì', 'i')
      .replaceAll('ò', 'o')
      .replaceAll('ù', 'u')
      .replaceAll(RegExp(r'[^\x20-\x7E]'), '?');
  String _money(int value) => '${(value / 100).toStringAsFixed(2)} EUR';
  int _int(Object? value) =>
      value is num ? value.toInt() : int.tryParse('$value') ?? 0;
}
