class SearchResultModel {
  final String title;
  final String url;
  final String snippet;

  const SearchResultModel({
    required this.title,
    required this.url,
    required this.snippet,
  });

  factory SearchResultModel.fromJson(Map<String, dynamic> json) {
    return SearchResultModel(
      title: json['title'] as String? ?? '',
      url: json['url'] as String? ?? '',
      snippet: json['snippet'] as String? ?? '',
    );
  }
}
