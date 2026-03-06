class News {
  final String id;
  final String title;
  final String description;
  final String content;
  final String source;
  final String sourceId;
  final String time;
  final int timestamp;
  final String? imageUrl;
  final int likes;
  final int comments;
  final String category;
  final String? url;

  News({
    required this.id,
    required this.title,
    required this.description,
    required this.content,
    required this.source,
    required this.sourceId,
    required this.time,
    required this.timestamp,
    this.imageUrl,
    required this.likes,
    required this.comments,
    required this.category,
    this.url,
  });

  factory News.fromJson(Map<String, dynamic> json) {
    return News(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      content: json['content'] ?? '',
      source: json['source'] ?? '',
      sourceId: json['sourceId'] ?? json['source_id'] ?? '',
      time: json['time'] ?? '',
      timestamp: json['timestamp'] ?? 0,
      imageUrl: json['image_url'],
      likes: json['likes'] ?? 0,
      comments: json['comments'] ?? 0,
      category: json['category'] ?? 'hot',
      url: json['url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'content': content,
      'source': source,
      'source_id': sourceId,
      'time': time,
      'timestamp': timestamp,
      'image_url': imageUrl,
      'likes': likes,
      'comments': comments,
      'category': category,
      'url': url,
    };
  }

  News copyWith({
    String? id,
    String? title,
    String? description,
    String? content,
    String? source,
    String? sourceId,
    String? time,
    int? timestamp,
    String? imageUrl,
    int? likes,
    int? comments,
    String? category,
    String? url,
  }) {
    return News(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      content: content ?? this.content,
      source: source ?? this.source,
      sourceId: sourceId ?? this.sourceId,
      time: time ?? this.time,
      timestamp: timestamp ?? this.timestamp,
      imageUrl: imageUrl ?? this.imageUrl,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      category: category ?? this.category,
      url: url ?? this.url,
    );
  }

  String get formattedLikes {
    if (likes >= 10000) {
      return '${(likes / 10000).toStringAsFixed(1)}万';
    }
    return likes.toString();
  }

  String get formattedComments {
    if (comments >= 10000) {
      return '${(comments / 10000).toStringAsFixed(1)}万';
    }
    return comments.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  // Adapt from external API NewsItem-like payloads
  factory News.fromExternal(Map<String, dynamic> json) {
    return News(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? json['hover'] ?? json['title'] ?? '',
      content: json['content'] ?? json['title'] ?? '',
      source: json['source'] ?? 'Unknown',
      sourceId: json['source_id'] ?? 'unknown',
      time: json['time'] ?? (json['pubDate'] ?? ''),
      timestamp: json['timestamp'] ?? 0,
      imageUrl: json['image_url'],
      likes: json['likes'] ?? 0,
      comments: json['comments'] ?? 0,
      category: json['category'] ?? 'hot',
      url: json['url'] ?? json['link'],
    );
  }
}
