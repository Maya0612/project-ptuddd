class FieldItem {
  final String id;
  final String name;
  final String? description;

  const FieldItem({required this.id, required this.name, this.description});

  factory FieldItem.fromJson(Map<String, dynamic> json) {
    return FieldItem(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
    );
  }
}
