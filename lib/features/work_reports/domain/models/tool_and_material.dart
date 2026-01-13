class MaterialItem {
  final String id;
  final String name;
  final String unit;
  final int quantity;

  const MaterialItem({
    required this.id,
    required this.name,
    required this.unit,
    required this.quantity,
  });

  Map<String, String> toJson(bool isTool) {
    return {
      isTool ? 'herramienta' : 'material': name,
      'unidad': unit,
      'cantidad': quantity.toString(),
    };
  }

  MaterialItem copyWith({String? name, String? unit, int? quantity}) {
    return MaterialItem(
      id: id,
      name: name ?? this.name,
      unit: unit ?? this.unit,
      quantity: quantity ?? this.quantity,
    );
  }
}
