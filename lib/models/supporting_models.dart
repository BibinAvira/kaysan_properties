import 'project_model.dart';

/// An investment-area summary, **derived client-side** by grouping the
/// live property list by `district` — the API has no standalone
/// "areas" endpoint. Because it's derived from whatever pages have been
/// fetched so far, [projectCount] reflects loaded data, not the true
/// district-wide total; the UI labels this accordingly.
class AreaModel {
  const AreaModel({
    required this.districtId,
    required this.name,
    required this.projectCount,
    required this.coverImage,
  });

  final int districtId;
  final String name;
  final int projectCount;

  /// Cover photo borrowed from one of the area's properties (there's no
  /// dedicated area image in the API).
  final String coverImage;

  /// Groups already-loaded [projects] by district into area summaries,
  /// sorted by project count descending (busiest areas first).
  static List<AreaModel> fromProjects(List<ProjectModel> projects) {
    final Map<int, List<ProjectModel>> byDistrict = <int, List<ProjectModel>>{};
    for (final ProjectModel p in projects) {
      byDistrict.putIfAbsent(p.district.id, () => <ProjectModel>[]).add(p);
    }
    final List<AreaModel> areas = byDistrict.entries.map((MapEntry<int, List<ProjectModel>> entry) {
      final List<ProjectModel> group = entry.value;
      return AreaModel(
        districtId: entry.key,
        name: group.first.district.name.display,
        projectCount: group.length,
        coverImage: group.firstWhere((ProjectModel p) => p.cover.isNotEmpty, orElse: () => group.first).cover,
      );
    }).toList();
    areas.sort((AreaModel a, AreaModel b) => b.projectCount.compareTo(a.projectCount));
    return areas;
  }
}

/// A blog/insight article. No live endpoint exists for this yet, so it
/// remains backed by `services/mock/mock_data.dart`.
class BlogModel {
  const BlogModel({
    required this.id,
    required this.title,
    required this.coverImage,
    required this.publishedAt,
    required this.readMinutes,
    required this.summary,
    required this.content,
  });

  final int id;
  final String title;
  final String coverImage;
  final DateTime publishedAt;
  final int readMinutes;
  final String summary;
  final String content;

  factory BlogModel.fromJson(Map<String, dynamic> json) {
    return BlogModel(
      id: json['id'] as int,
      title: json['title'] as String,
      coverImage: json['cover_image'] as String,
      publishedAt: DateTime.parse(json['published_at'] as String),
      readMinutes: json['read_minutes'] as int? ?? 5,
      summary: json['summary'] as String? ?? '',
      content: json['content'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'title': title,
        'cover_image': coverImage,
        'published_at': publishedAt.toIso8601String(),
        'read_minutes': readMinutes,
        'summary': summary,
        'content': content,
      };
}

/// A client testimonial. No live endpoint exists for this yet, so it
/// remains backed by `services/mock/mock_data.dart`.
class TestimonialModel {
  const TestimonialModel({
    required this.id,
    required this.author,
    required this.rating,
    required this.review,
    required this.postedAgo,
  });

  final int id;
  final String author;
  final int rating;
  final String review;
  final String postedAgo;

  factory TestimonialModel.fromJson(Map<String, dynamic> json) {
    return TestimonialModel(
      id: json['id'] as int,
      author: json['author'] as String,
      rating: json['rating'] as int? ?? 5,
      review: json['review'] as String,
      postedAgo: json['posted_ago'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'author': author,
        'rating': rating,
        'review': review,
        'posted_ago': postedAgo,
      };
}

/// A "Register Interest" / Contact form submission.
class EnquiryModel {
  const EnquiryModel({
    required this.name,
    required this.email,
    required this.phone,
    this.message = '',
    this.propertyId,
    this.propertyTitle,
  });

  final String name;
  final String email;
  final String phone;
  final String message;
  final int? propertyId;
  final String? propertyTitle;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'name': name,
        'email': email,
        'phone': phone,
        'message': message,
        if (propertyId != null) 'property_id': propertyId,
        if (propertyTitle != null) 'property_title': propertyTitle,
      };
}
