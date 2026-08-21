import '../models/supporting_models.dart';
import '../services/feature_services.dart';

class BlogsRepository {
  BlogsRepository(this._service);
  final BlogsService _service;

  Future<List<BlogModel>> getBlogs() => _service.fetchBlogs();
  Future<List<TestimonialModel>> getTestimonials() => _service.fetchTestimonials();
}

class EnquiryRepository {
  EnquiryRepository(this._service);
  final EnquiryService _service;

  Future<bool> submitEnquiry(EnquiryModel enquiry) => _service.submit(enquiry);
}
