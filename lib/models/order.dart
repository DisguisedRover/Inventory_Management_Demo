class Order {
  final int id;
  final int itemId;
  final String name;
  final String contact;
  final String address;
  final String title;
  final double price;

  Order({
    required this.id,
    required this.itemId,
    required this.name,
    required this.contact,
    required this.address,
    required this.title,
    required this.price,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    try {
      print('Processing JSON: $json'); // Debug print

      // Handle id
      final id =
          json['id'] is String ? int.parse(json['id']) : json['id'] as int;

      // Handle item_id
      final itemId = json['item_id'] is String
          ? int.parse(json['item_id'])
          : json['item_id'] as int;

      // Handle price
      double price;
      var priceValue = json['price'];
      if (priceValue is int) {
        price = priceValue.toDouble();
      } else if (priceValue is String) {
        price = double.parse(priceValue);
      } else if (priceValue is double) {
        price = priceValue;
      } else {
        throw FormatException('Invalid price format: $priceValue');
      }

      return Order(
        id: id,
        itemId: itemId,
        name: json['name']?.toString() ?? '',
        contact: json['contact']?.toString() ?? '',
        address: json['address']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        price: price,
      );
    } catch (e, stackTrace) {
      print('Error parsing Order JSON: $e');
      print('Stack trace: $stackTrace');
      print('Problematic JSON: $json');
      rethrow;
    }
  }

  @override
  String toString() {
    return 'Order(id: $id, itemId: $itemId, name: $name, contact: $contact, address: $address, title: $title, price: $price)';
  }
}
