class Post {
  final int id;
  final String title;
  final String content;
  final String excerpt;
  final String slug;
  final String status;
  final String type;
  final DateTime date;
  final DateTime modified;
  final Author author;
  final FeaturedImage? featuredImage;
  final String? firstContentImage;
  final List<Category> categories;
  final List<Tag> tags;
  final String url;
  final int commentCount;
  final List<Comment>? comments;

  Post({
    required this.id,
    required this.title,
    required this.content,
    required this.excerpt,
    required this.slug,
    required this.status,
    required this.type,
    required this.date,
    required this.modified,
    required this.author,
    this.featuredImage,
    this.firstContentImage,
    required this.categories,
    required this.tags,
    required this.url,
    required this.commentCount,
    this.comments,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      excerpt: json['excerpt']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      type: json['type']?.toString() ?? 'post',
      date: DateTime.parse(json['date'] ?? DateTime.now().toString()),
      modified: DateTime.parse(json['modified'] ?? DateTime.now().toString()),
      author: Author.fromJson(json['author'] ?? {}),
      featuredImage: json['featured_image'] != null
          ? FeaturedImage.fromJson(json['featured_image'])
          : null,
      firstContentImage: json['first_content_image']?.toString(),
      categories: (json['categories'] as List?)
              ?.map((cat) => Category.fromJson(cat))
              .toList() ??
          [],
      tags: (json['tags'] as List?)?.map((tag) => Tag.fromJson(tag)).toList() ??
          [],
      url: json['url']?.toString() ?? '',
      commentCount: json['comment_count'] is int ? json['comment_count'] : int.tryParse(json['comment_count']?.toString() ?? '0') ?? 0,
      comments: json['comments'] != null
          ? (json['comments'] as List)
              .map((comment) => Comment.fromJson(comment))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'excerpt': excerpt,
      'slug': slug,
      'status': status,
      'type': type,
      'date': date.toIso8601String(),
      'modified': modified.toIso8601String(),
      'author': author.toJson(),
      'featured_image': featuredImage?.toJson(),
      'first_content_image': firstContentImage,
      'categories': categories.map((c) => c.toJson()).toList(),
      'tags': tags.map((t) => t.toJson()).toList(),
      'url': url,
      'comment_count': commentCount,
      'comments': comments?.map((c) => c.toJson()).toList(),
    };
  }
}

class Author {
  final int id;
  final String name;
  final String avatar;

  Author({
    required this.id,
    required this.name,
    required this.avatar,
  });

  factory Author.fromJson(Map<String, dynamic> json) {
    return Author(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? 'Unknown',
      avatar: json['avatar']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatar': avatar,
    };
  }
}

class FeaturedImage {
  final String full;
  final String thumbnail;
  final String medium;
  final String large;

  FeaturedImage({
    required this.full,
    required this.thumbnail,
    required this.medium,
    required this.large,
  });

  factory FeaturedImage.fromJson(Map<String, dynamic> json) {
    return FeaturedImage(
      full: json['full'] ?? '',
      thumbnail: json['thumbnail'] ?? '',
      medium: json['medium'] ?? '',
      large: json['large'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'full': full,
      'thumbnail': thumbnail,
      'medium': medium,
      'large': large,
    };
  }
}

class Category {
  final int id;
  final String name;
  final String slug;
  final String? description;
  final int? count;
  final int? parent;

  Category({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.count,
    this.parent,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      description: json['description']?.toString(),
      count: json['count'] is int ? json['count'] : int.tryParse(json['count']?.toString() ?? '0'),
      parent: json['parent'] is int ? json['parent'] : int.tryParse(json['parent']?.toString() ?? '0'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'description': description,
      'count': count,
      'parent': parent,
    };
  }
}

class Tag {
  final int id;
  final String name;
  final String slug;

  Tag({
    required this.id,
    required this.name,
    required this.slug,
  });

  factory Tag.fromJson(Map<String, dynamic> json) {
    return Tag(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
    };
  }
}

class Comment {
  final int id;
  final int? postId;
  final String? postTitle;
  final String author;
  final String email;
  final String content;
  final DateTime date;
  final String avatar;

  Comment({
    required this.id,
    this.postId,
    this.postTitle,
    required this.author,
    required this.email,
    required this.content,
    required this.date,
    required this.avatar,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] ?? 0,
      postId: json['post_id'],
      postTitle: json['post_title'],
      author: json['author'] ?? 'Anonymous',
      email: json['email'] ?? '',
      content: json['content'] ?? '',
      date: DateTime.parse(json['date'] ?? DateTime.now().toString()),
      avatar: json['avatar'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'post_id': postId,
      'post_title': postTitle,
      'author': author,
      'email': email,
      'content': content,
      'date': date.toIso8601String(),
      'avatar': avatar,
    };
  }
}

class MenuItem {
  final int id;
  final String title;
  final String url;
  final String target;
  final int parent;
  final int order;
  final int objectId;
  final String type;

  MenuItem({
    required this.id,
    required this.title,
    required this.url,
    required this.target,
    required this.parent,
    required this.order,
    required this.objectId,
    required this.type,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      url: json['url'] ?? '',
      target: json['target'] ?? '',
      parent: json['parent'] ?? 0,
      order: json['order'] ?? 0,
      objectId: json['object_id'] ?? 0,
      type: json['type'] ?? '',
    );
  }
}

class Menu {
  final int id;
  final String name;
  final String slug;
  final List<MenuItem> items;

  Menu({
    required this.id,
    required this.name,
    required this.slug,
    required this.items,
  });

  factory Menu.fromJson(Map<String, dynamic> json) {
    return Menu(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      items: (json['items'] as List?)
              ?.map((item) => MenuItem.fromJson(item))
              .toList() ??
          [],
    );
  }
}

class Media {
  final int id;
  final String title;
  final String caption;
  final String description;
  final String url;
  final String thumbnail;
  final String medium;
  final String large;
  final DateTime date;
  final String mimeType;

  Media({
    required this.id,
    required this.title,
    required this.caption,
    required this.description,
    required this.url,
    required this.thumbnail,
    required this.medium,
    required this.large,
    required this.date,
    required this.mimeType,
  });

  factory Media.fromJson(Map<String, dynamic> json) {
    return Media(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      caption: json['caption'] ?? '',
      description: json['description'] ?? '',
      url: json['url'] ?? '',
      thumbnail: json['thumbnail'] ?? '',
      medium: json['medium'] ?? '',
      large: json['large'] ?? '',
      date: DateTime.parse(json['date'] ?? DateTime.now().toString()),
      mimeType: json['mime_type'] ?? '',
    );
  }
}

class SiteInfo {
  final String name;
  final String description;
  final String url;
  final String adminEmail;
  final String language;
  final String charset;
  final String version;
  final String theme;
  final String timezone;

  SiteInfo({
    required this.name,
    required this.description,
    required this.url,
    required this.adminEmail,
    required this.language,
    required this.charset,
    required this.version,
    required this.theme,
    required this.timezone,
  });

  factory SiteInfo.fromJson(Map<String, dynamic> json) {
    return SiteInfo(
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      url: json['url'] ?? '',
      adminEmail: json['admin_email'] ?? '',
      language: json['language'] ?? '',
      charset: json['charset'] ?? '',
      version: json['version'] ?? '',
      theme: json['theme'] ?? '',
      timezone: json['timezone'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'url': url,
      'admin_email': adminEmail,
      'language': language,
      'charset': charset,
      'version': version,
      'theme': theme,
      'timezone': timezone,
    };
  }
}
