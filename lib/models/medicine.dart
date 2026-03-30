class Medicine {
  final String name;
  final String duration;
  final String frequency;
  final String timing;
  final String foodRelation;

  Medicine({
    required this.name,
    required this.duration,
    required this.frequency,
    required this.timing,
    required this.foodRelation,
  });

  factory Medicine.fromJson(Map<String, dynamic> json) {
    return Medicine(
      name: json['medicine_name'] ?? '',
      duration: json['duration'] ?? '',
      frequency: json['frequency'] ?? '',
      timing: json['timing'] ?? '',
      foodRelation: json['food_relation'] ?? '',
    );
  }
}