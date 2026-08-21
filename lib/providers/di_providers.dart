import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/auth_repository.dart';
import '../repositories/favorites_repository.dart';
import '../repositories/feature_repositories.dart';
import '../repositories/projects_repository.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/feature_services.dart';
import '../services/network_service.dart';
import '../services/projects_service.dart';
import '../services/token_storage.dart';

/// Root dependency-injection graph. Every service/repository is exposed as
/// a provider so views/controllers never `new` them up directly, keeping
/// the graph swappable in tests via `overrideWithValue`.
final Provider<ApiService> apiServiceProvider = Provider<ApiService>((Ref ref) => ApiService());

final Provider<NetworkService> networkServiceProvider =
    Provider<NetworkService>((Ref ref) => NetworkService());

final Provider<ProjectsService> projectsServiceProvider =
    Provider<ProjectsService>((Ref ref) => ProjectsService(ref.watch(apiServiceProvider)));

final Provider<BlogsService> blogsServiceProvider =
    Provider<BlogsService>((Ref ref) => BlogsService(ref.watch(apiServiceProvider)));

final Provider<EnquiryService> enquiryServiceProvider =
    Provider<EnquiryService>((Ref ref) => EnquiryService(ref.watch(apiServiceProvider)));

final Provider<ProjectsRepository> projectsRepositoryProvider =
    Provider<ProjectsRepository>((Ref ref) => ProjectsRepository(ref.watch(projectsServiceProvider)));

final Provider<BlogsRepository> blogsRepositoryProvider =
    Provider<BlogsRepository>((Ref ref) => BlogsRepository(ref.watch(blogsServiceProvider)));

final Provider<EnquiryRepository> enquiryRepositoryProvider =
    Provider<EnquiryRepository>((Ref ref) => EnquiryRepository(ref.watch(enquiryServiceProvider)));

final Provider<FavoritesRepository> favoritesRepositoryProvider =
    Provider<FavoritesRepository>((Ref ref) => FavoritesRepository());

final Provider<TokenStorage> tokenStorageProvider =
    Provider<TokenStorage>((Ref ref) => TokenStorage());

final Provider<AuthService> authServiceProvider =
    Provider<AuthService>((Ref ref) => AuthService(ref.watch(tokenStorageProvider)));

final Provider<AuthRepository> authRepositoryProvider =
    Provider<AuthRepository>((Ref ref) => AuthRepository(ref.watch(authServiceProvider)));
