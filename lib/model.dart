// models/poem.dart
class Poem {
  final String id;
  final String title;
  final String content;
  final int authorId;
  final String authorAddress;
  final String authorName;
  final String authorUsername;
  final String authorAvatar;
  final String poemHash;
  final List<BigInt> liked;
  int likes;
  int rewards;
  bool isLiked;
  final DateTime createdAt;

  Poem({
    required this.id,
    required this.title,
    required this.content,
    required this.authorId,
    required this.authorName,
    required this.authorUsername,
    required this.authorAvatar,
    required this.likes,
    required this.rewards,
    required this.isLiked,
    required this.authorAddress,
    required this.createdAt,
    required this.poemHash,
    required this.liked,
  });

  factory Poem.fromJson(Map<String, dynamic> json) {
    return Poem(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      authorAddress: json['authorAddress'],
      authorId: json['authorId'],
      authorName: json['authorName'],
      authorUsername: json['authorUsername'],
      authorAvatar: json['authorAvatar'],
      likes: json['likes'],
      rewards: json['rewards'],
      isLiked: json['isLiked'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      liked: List<BigInt>.from(json['liked']),
      poemHash: json['poemHash'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'authorId': authorId,
      'authorName': authorName,
      'authorUsername': authorUsername,
      'authorAvatar': authorAvatar,
      'likes': likes,
      'authorAddress': authorAddress,
      'rewards': rewards,
      'isLiked': isLiked,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  Poem copyWith({
    String? id,
    String? title,
    String? content,
    int? authorId,
    String? authorName,
    String? authorUsername,
    String? authorAvatar,
    int? likes,
    int? rewards,
    bool? isLiked,
    DateTime? createdAt,
    List<BigInt>? liked,
    String? poemHash,
    String? authorAddress,

  }) {
    return Poem(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      authorId: authorId ?? this.authorId,
      authorAddress: authorAddress ?? this.authorAddress,
      authorName: authorName ?? this.authorName,
      authorUsername: authorUsername ?? this.authorUsername,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      likes: likes ?? this.likes,
      rewards: rewards ?? this.rewards,
      isLiked: isLiked ?? this.isLiked,
      createdAt: createdAt ?? this.createdAt,
      liked: liked ?? this.liked,
      poemHash: poemHash ?? this.poemHash,
    );
  }
}

// models/user.dart
class User {
  final String id;
  final String username;
  final String email;
  final String avatar;
  final List<String> followers;
  final List<String> following;
  int totalPoems;
  int totalRewards;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.avatar,
    required this.followers,
    required this.following,
    required this.totalPoems,
    required this.totalRewards,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      avatar: json['avatar'],
      followers: List<String>.from(json['followers']),
      following: List<String>.from(json['following']),
      totalPoems: json['totalPoems'],
      totalRewards: json['totalRewards'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'avatar': avatar,
      'followers': followers,
      'following': following,
      'totalPoems': totalPoems,
      'totalRewards': totalRewards,
    };
  }

  User copyWith({
    String? id,
    String? username,
    String? email,
    String? avatar,
    List<String>? followers,
    List<String>? following,
    int? totalPoems,
    int? totalRewards,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      avatar: avatar ?? this.avatar,
      followers: followers ?? this.followers,
      following: following ?? this.following,
      totalPoems: totalPoems ?? this.totalPoems,
      totalRewards: totalRewards ?? this.totalRewards,
    );
  }
}
class Comment {
  final String id;
  final String author;
  final String content;
  final DateTime timestamp;

  Comment({
    required this.id,
    required this.author,
    required this.content,
    required this.timestamp,
  });

  // Add toJson and fromJson methods if needed
}