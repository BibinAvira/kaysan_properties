import '../../models/supporting_models.dart';

/// In-memory dataset for the two content types that have no live endpoint
/// yet: Blogs/Insights and client Testimonials. Projects, Areas and
/// Developers are now served live from the x-opp microservice — see
/// `services/projects_service.dart` and `AreaModel.fromProjects`.
class MockData {
  MockData._();

  static final List<BlogModel> blogs = <BlogModel>[
    BlogModel(
      id: 30,
      title: 'Why Choose Off-Plan Properties in Dubai for Investment',
      coverImage: 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?q=80&w=1200',
      publishedAt: DateTime(2026, 7, 14),
      readMinutes: 6,
      summary:
          'A look at why off-plan developments are drawing investor attention in the current '
          'Dubai market cycle.',
      content:
          'Off-plan investment continues to be a preferred entry point for both first-time and '
          'seasoned investors in Dubai. Leading developers have built a reputation for '
          'delivering on schedule while offering flexible payment plans that lower the barrier '
          'to entry for international buyers.\n\n'
          'This article walks through common payment structures, expected rental yields, and '
          'the communities currently seeing the most launch activity, helping investors weigh '
          'the opportunity against the broader market.',
    ),
    BlogModel(
      id: 29,
      title: 'Off-Plan Property Agents in Dubai for Smart Property Buyers',
      coverImage: 'https://images.unsplash.com/photo-1493809842364-78817add7ffb?q=80&w=1200',
      publishedAt: DateTime(2026, 7, 14),
      readMinutes: 6,
      summary:
          'What separates a reliable off-plan agent from the rest — and the questions every '
          'buyer should ask before signing.',
      content:
          'Choosing the right agent can materially change the outcome of an off-plan purchase, '
          'from negotiated payment plans to post-handover support. This piece outlines the '
          'due-diligence checklist smart buyers use before committing to a project or an agent.',
    ),
    BlogModel(
      id: 28,
      title: 'Dubai Property Investment for Foreigners',
      coverImage: 'https://images.unsplash.com/photo-1512453979798-5ea266f8880c?q=80&w=1200',
      publishedAt: DateTime(2026, 7, 14),
      readMinutes: 6,
      summary:
          'A practical overview of ownership rules, freehold zones, and the process for '
          'international buyers entering the Dubai market.',
      content:
          'Dubai\'s freehold ownership laws allow foreign nationals to fully own property in '
          'designated zones. This guide covers eligibility, the golden visa pathway tied to '
          'property investment, financing options for non-residents, and the step-by-step '
          'purchase process from reservation to title deed transfer.',
    ),
  ];

  static final List<TestimonialModel> testimonials = <TestimonialModel>[
    const TestimonialModel(
      id: 1,
      author: 'MAB Properties',
      rating: 5,
      postedAgo: '2 months ago',
      review:
          'Working with the team was one of the best decisions we made while investing in '
          'Dubai real estate. Extremely knowledgeable, transparent, and helpful at every step.',
    ),
    const TestimonialModel(
      id: 2,
      author: 'Sadiya Rassul',
      rating: 5,
      postedAgo: '2 months ago',
      review:
          'Highly professional team with deep understanding of the Dubai property market. They '
          'helped us identify the right investment opportunity based on our budget and long-term '
          'goals.',
    ),
    const TestimonialModel(
      id: 3,
      author: 'Kal Hawary',
      rating: 5,
      postedAgo: '3 months ago',
      review:
          'The team truly stands out for their customer-first approach. They listened carefully '
          'to our requirements and provided options that perfectly matched our needs.',
    ),
    const TestimonialModel(
      id: 4,
      author: 'Vivian Rong',
      rating: 5,
      postedAgo: '4 months ago',
      review:
          'We had an excellent experience from start to finish. The team was responsive, '
          'professional, and always available to answer our questions.',
    ),
    const TestimonialModel(
      id: 5,
      author: 'Ahmed Khan',
      rating: 5,
      postedAgo: '1 month ago',
      review:
          'From the first consultation to final handover, the service exceeded our '
          'expectations. Highly recommended for anyone looking to invest in Dubai.',
    ),
  ];
}
