import '../core/config/app_config.dart';
import '../models/supporting_models.dart';
import 'api_service.dart';
import 'mock/mock_data.dart';

class BlogsService {
  BlogsService(this._api);
  final ApiService _api;

  Future<List<BlogModel>> fetchBlogs() async {
    if (AppConfig.useMockContent) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      return MockData.blogs;
    }
    final Map<String, dynamic> json = await _api.get('/blogs');
    return (json['data'] as List<dynamic>)
        .map((dynamic e) => BlogModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<TestimonialModel>> fetchTestimonials() async {
    if (AppConfig.useMockContent) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      return MockData.testimonials;
    }
    final Map<String, dynamic> json = await _api.get('/testimonials');
    return (json['data'] as List<dynamic>)
        .map((dynamic e) => TestimonialModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

class EnquiryService {
  EnquiryService(this._api);
  final ApiService _api;

  Future<bool> submit(EnquiryModel enquiry) async {
    if (AppConfig.useMockContent) {
      await Future<void>.delayed(const Duration(milliseconds: 700));
      return true; // simulate success
    }
    final Map<String, dynamic> json = await _api.post('/enquiries', data: enquiry.toJson());
    return json['success'] as bool? ?? true;
  }
}
