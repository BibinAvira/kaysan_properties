import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/formatters.dart';
import '../../models/supporting_models.dart';
import '../../providers/content_providers.dart';
import '../../widgets/common_widgets.dart';

/// Blogs listing — Kaysan Properties' investment-insights articles.
class BlogsView extends ConsumerWidget {
  const BlogsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<BlogModel>> blogs = ref.watch(blogsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Blogs & Insights')),
      body: blogs.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object e, StackTrace st) => EmptyStateView(
          icon: Icons.error_outline,
          title: 'Could not load blogs',
          message: 'Please check your connection and try again.',
          actionLabel: 'Retry',
          onActionTap: () => ref.invalidate(blogsProvider),
        ),
        data: (List<BlogModel> list) {
          if (list.isEmpty) {
            return const EmptyStateView(icon: Icons.article_outlined, title: 'No blogs yet', message: 'Check back soon.');
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (BuildContext context, int index) => const SizedBox(height: 16),
            itemBuilder: (BuildContext context, int index) {
              final BlogModel blog = list[index];
              return InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (BuildContext context) => BlogDetailsView(blogId: blog.id)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: SizedBox(height: 160, child: AppNetworkImage(url: blog.coverImage)),
                    ),
                    const SizedBox(height: 8),
                    Text(blog.title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      '${Formatters.fullDate(blog.publishedAt)} • ${blog.readMinutes} Min Read',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// Blog Details — full article view.
class BlogDetailsView extends ConsumerWidget {
  const BlogDetailsView({super.key, required this.blogId});
  final int blogId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<BlogModel>> blogsAsync = ref.watch(blogsProvider);

    return blogsAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (Object e, StackTrace st) => const Scaffold(
        body: EmptyStateView(icon: Icons.error_outline, title: 'Article not found', message: 'Please go back and try again.'),
      ),
      data: (List<BlogModel> blogs) {
        final BlogModel blog = blogs.firstWhere((BlogModel b) => b.id == blogId, orElse: () => blogs.first);
        return Scaffold(
          appBar: AppBar(title: const Text('Article')),
          body: ListView(
            children: <Widget>[
              SizedBox(height: 220, child: AppNetworkImage(url: blog.coverImage)),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(blog.title, style: Theme.of(context).textTheme.displayMedium),
                    const SizedBox(height: 6),
                    Text(
                      '${Formatters.fullDate(blog.publishedAt)} • ${blog.readMinutes} Min Read',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    const SizedBox(height: 16),
                    Text(blog.content, style: Theme.of(context).textTheme.bodyLarge),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
