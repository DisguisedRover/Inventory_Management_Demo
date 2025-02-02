class InventoryItem {
  final int id;
  final String title;
  final double price;
  final int quantity;

  InventoryItem({
    required this.id,
    required this.title,
    required this.price,
    required this.quantity,
  });

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    double parsePrice(dynamic value) {
      if (value is int) return value.toDouble();
      if (value is double) return value;
      if (value is String) {
        return double.tryParse(value.replaceAll(',', '')) ?? 0.0;
      }
      return 0.0;
    }

    return InventoryItem(
      id: json['id'],
      title: json['title'],
      price: parsePrice(json['price']),
      quantity: int.tryParse(json['quantity'].toString()) ?? 0,
    );
  }
}
