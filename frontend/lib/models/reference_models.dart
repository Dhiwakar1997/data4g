class DatabaseReference {
  const DatabaseReference({
    required this.id,
    required this.name,
    required this.category,
  });

  final String id;
  final String name;
  final String category;

  factory DatabaseReference.fromJson(Map<String, dynamic> json) {
    return DatabaseReference(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      category: json['category'] as String? ?? '',
    );
  }
}

class ReferenceOption {
  const ReferenceOption({required this.id, required this.name});

  final String id;
  final String name;

  factory ReferenceOption.fromJson(Map<String, dynamic> json) {
    return ReferenceOption(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
    );
  }
}
