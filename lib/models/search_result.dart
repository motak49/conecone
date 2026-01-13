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
      // nullなら 0 や 空文字 を入れてクラッシュを防ぐ
      rank: json['rank'] ?? 0,
      
      // 数値型変換の安全策（intがきてもdoubleに変換）
      similarity: (json['similarity'] is num)
          ? (json['similarity'] as num).toDouble()
          : 0.0,
          
      brand: json['brand'] ?? 'Unknown',
      model: json['model'] ?? 'Unknown',
      image: json['image'] ?? '',
    );
  }
}