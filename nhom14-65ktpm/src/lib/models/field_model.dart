/// Model đại diện cho một lĩnh vực đồ án từ bảng `public.fields`.
class FieldModel {
  final String id;
  final String name;

  const FieldModel({
    required this.id,
    required this.name,
  });

  factory FieldModel.fromJson(Map<String, dynamic> json) {
    return FieldModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? json['title']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}
