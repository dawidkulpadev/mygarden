class Plant {
  final String id;
  final String name;
  final String? species;
  final String sectionId;

  Plant({
    required this.id,
    required this.name,
    required this.sectionId,
    this.species,
  });

  factory Plant.fromJson(Map<String, dynamic> json) {
    return Plant(
      id: json['id'].toString(),
      name: json['name'] as String,
      sectionId: json['section_id'].toString(),
      species: json['species'] as String?,
    );
  }
}
