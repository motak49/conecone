class SearchResult {
  final int rank;
  final double similarity;
  final String brand;
  final String model;
  final String image;

  SearchResult({
    required this.rank,
    required this.similarity,
    required this.brand,
    required this.model,
    required this.image,
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    return SearchResult(
      rank: json['rank'],
      similarity: (json['similarity'] as num).toDouble(),
      brand: json['brand'],
      model: json['model'],
      image: json['image'],
    );
  }
}
