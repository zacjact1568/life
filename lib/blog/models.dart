class Post {
  final title;
  final excerpt;
  final createdAt;
  final updatedAt;
  final label;

  Post({
    this.title,
    this.excerpt,
    this.createdAt,
    this.updatedAt,
    this.label
  });

  // JSON 反序列化后为 Map<String, dynamic>
  factory Post.fromMap(Map<String, dynamic> map) {
    return Post(
      title: map['title'],
      excerpt: map['excerpt'],
      createdAt: map['created_at'],
      updatedAt: map['updated_at'],
      label: map['label'],
    );
  }
}