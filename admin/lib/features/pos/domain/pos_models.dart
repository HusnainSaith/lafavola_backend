class PosCatalog {
  const PosCatalog({
    required this.restaurantId,
    required this.categories,
    required this.items,
  });

  factory PosCatalog.fromJson(Map<String, dynamic> json) => PosCatalog(
    restaurantId: json['restaurantId']?.toString() ?? '',
    categories: _maps(json['categories']).map(PosCategory.fromJson).toList(),
    items: _maps(json['items']).map(PosMenuItem.fromJson).toList(),
  );

  final String restaurantId;
  final List<PosCategory> categories;
  final List<PosMenuItem> items;
}

class PosCategory {
  const PosCategory({required this.id, required this.name});
  factory PosCategory.fromJson(Map<String, dynamic> json) => PosCategory(
    id: json['id']?.toString() ?? '',
    name: json['name']?.toString() ?? 'Categoria',
  );
  final String id;
  final String name;
}

class PosMenuItem {
  const PosMenuItem({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.description,
    required this.sizes,
    required this.optionGroups,
  });
  factory PosMenuItem.fromJson(Map<String, dynamic> json) => PosMenuItem(
    id: json['id']?.toString() ?? '',
    categoryId: json['categoryId']?.toString(),
    name: json['name']?.toString() ?? 'Prodotto',
    description: json['description']?.toString(),
    sizes: _maps(json['sizes']).map(PosMenuSize.fromJson).toList(),
    optionGroups:
        _maps(json['optionGroups']).map(PosOptionGroup.fromJson).toList(),
  );
  final String id;
  final String? categoryId;
  final String name;
  final String? description;
  final List<PosMenuSize> sizes;
  final List<PosOptionGroup> optionGroups;
}

class PosMenuSize {
  const PosMenuSize({
    required this.id,
    required this.name,
    required this.priceMinor,
  });
  factory PosMenuSize.fromJson(Map<String, dynamic> json) => PosMenuSize(
    id: json['id']?.toString() ?? '',
    name: json['displayName']?.toString() ?? 'Standard',
    priceMinor: _int(json['basePriceMinor']),
  );
  final String id;
  final String name;
  final int priceMinor;
}

class PosOptionGroup {
  const PosOptionGroup({
    required this.id,
    required this.name,
    required this.minSelect,
    required this.maxSelect,
    required this.required,
    required this.choices,
  });
  factory PosOptionGroup.fromJson(Map<String, dynamic> json) => PosOptionGroup(
    id: json['id']?.toString() ?? '',
    name: json['name']?.toString() ?? 'Opzioni',
    minSelect: _int(json['minSelect']),
    maxSelect: json['maxSelect'] == null ? null : _int(json['maxSelect']),
    required: json['isRequired'] == true,
    choices: _maps(json['choices']).map(PosOptionChoice.fromJson).toList(),
  );
  final String id;
  final String name;
  final int minSelect;
  final int? maxSelect;
  final bool required;
  final List<PosOptionChoice> choices;
}

class PosOptionChoice {
  const PosOptionChoice({
    required this.id,
    required this.groupId,
    required this.name,
    required this.priceMinor,
    required this.isDefault,
  });
  factory PosOptionChoice.fromJson(Map<String, dynamic> json) =>
      PosOptionChoice(
        id: json['id']?.toString() ?? '',
        groupId: json['optionGroupId']?.toString() ?? '',
        name: json['name']?.toString() ?? 'Opzione',
        priceMinor: _int(json['priceAdjustmentMinor']),
        isDefault: json['isDefault'] == true,
      );
  final String id;
  final String groupId;
  final String name;
  final int priceMinor;
  final bool isDefault;
}

class PosCartLine {
  const PosCartLine({
    required this.key,
    required this.item,
    required this.size,
    required this.quantity,
    required this.options,
    this.instructions,
  });
  final String key;
  final PosMenuItem item;
  final PosMenuSize size;
  final int quantity;
  final List<PosOptionChoice> options;
  final String? instructions;

  int get unitPriceMinor =>
      size.priceMinor +
      options.fold(0, (sum, option) => sum + option.priceMinor);
  int get lineTotalMinor => unitPriceMinor * quantity;

  PosCartLine copyWith({int? quantity}) => PosCartLine(
    key: key,
    item: item,
    size: size,
    quantity: quantity ?? this.quantity,
    options: options,
    instructions: instructions,
  );

  Map<String, Object?> toRequest() => {
    'menuItemId': item.id,
    'sizeId': size.id,
    'quantity': quantity,
    'options': [
      for (final option in options)
        {
          'optionGroupId': option.groupId,
          'optionChoiceId': option.id,
          'action': 'add',
          'quantity': 1,
        },
    ],
    if (instructions?.trim().isNotEmpty == true)
      'specialInstructions': instructions!.trim(),
  };
}

class PrintableReceipt {
  const PrintableReceipt({
    required this.documentType,
    required this.documentNumber,
    required this.issuedAt,
    required this.fiscalNotice,
    required this.restaurant,
    required this.order,
    required this.items,
  });
  factory PrintableReceipt.fromJson(
    Map<String, dynamic> json,
  ) => PrintableReceipt(
    documentType: json['documentType']?.toString() ?? 'order_ticket',
    documentNumber: json['documentNumber']?.toString() ?? '',
    issuedAt:
        DateTime.tryParse(json['issuedAt']?.toString() ?? '') ?? DateTime.now(),
    fiscalNotice:
        json['fiscalNotice']?.toString() ?? 'COPIA DI CORTESIA - NON FISCALE',
    restaurant: _map(json['restaurant']),
    order: _map(json['order']),
    items: _maps(json['items']),
  );
  final String documentType;
  final String documentNumber;
  final DateTime issuedAt;
  final String fiscalNotice;
  final Map<String, dynamic> restaurant;
  final Map<String, dynamic> order;
  final List<Map<String, dynamic>> items;

  bool get isPaid => documentType == 'payment_receipt';
  int get totalMinor => _int(order['grandTotalMinor']);
}

Map<String, dynamic> _map(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};
List<Map<String, dynamic>> _maps(Object? value) =>
    value is List ? value.whereType<Map>().map(_map).toList() : const [];
int _int(Object? value) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? 0;
