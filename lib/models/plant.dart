class Plant {
  final String id;
  final String name;          // np. "Monstera deliciosa"
  final String? species;      // opcjonalnie gatunek, np. "Monstera"
  final String sectionId;     // do której sekcji należy

  Plant({
    required this.id,
    required this.name,
    required this.sectionId,
    this.species,
  });
}