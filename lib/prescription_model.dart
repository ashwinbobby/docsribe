class Prescription {
  final String medicine;
  final String dose;
  final String timing;
  final String duration;

  Prescription({
    required this.medicine,
    required this.dose,
    required this.timing,
    required this.duration,
  });

  factory Prescription.fromJson(Map<String, dynamic> json) {
    return Prescription(
      medicine: json['medicine'] ?? '',
      dose: json['dose'] ?? '',
      timing: json['timing'] ?? '',
      duration: json['duration'] ?? '',
    );
  }
}