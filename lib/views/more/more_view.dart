import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../core/routes/route_names.dart';
import '../../core/utils/launcher_utils.dart';
import '../../models/auth_models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';

/// "More" tab — the fourth bottom-nav destination. Surfaces navigation to
/// every screen that doesn't need its own tab (About, Contact, Legal),
/// plus the theme toggle and quick social/contact links.
class MoreView extends ConsumerWidget {
  const MoreView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeMode themeMode = ref.watch(themeModeProvider);
    final AsyncValue<UserModel?> authState = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: ListView(
        children: <Widget>[
          const SizedBox(height: 8),
          authState.when(
            loading: () => const ListTile(
              leading: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              title: Text('Checking session…'),
            ),
            error: (Object e, StackTrace st) => ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Guest User'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(RouteNames.profile),
            ),
            data: (UserModel? user) {
              if (user == null) {
                // Routes through the Profile screen (not straight to
                // Login) so guests see the dedicated "Guest User / sign in
                // to unlock personalized features" invitation there.
                return ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: const Text('Guest User'),
                  subtitle: const Text('Sign in to unlock personalized features'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(RouteNames.profile),
                );
              }
              return ListTile(
                leading: const Icon(Icons.account_circle_outlined),
                title: Text(user.fullName?.isNotEmpty == true ? user.fullName! : user.username),
                subtitle: const Text('View & edit your profile'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(RouteNames.profile),
              );
            },
          ),
          const Divider(height: 24),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About Kaysan Properties'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(RouteNames.about),
          ),
          ListTile(
            leading: const Icon(Icons.mail_outline),
            title: const Text('Contact Us'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(RouteNames.contact),
          ),
          ListTile(
            leading: const Icon(Icons.article_outlined),
            title: const Text('Blogs & Insights'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(RouteNames.blogs),
          ),
          ListTile(
            leading: const Icon(Icons.map_outlined),
            title: const Text('Explore Areas'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(RouteNames.areas),
          ),
          ListTile(
            leading: const Icon(Icons.calculate_outlined),
            title: const Text('Mortgage & ROI Calculator'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(RouteNames.calculator),
          ),
          const Divider(height: 24),
          ListTile(
            leading: const Icon(Icons.dark_mode_outlined),
            title: const Text('Theme'),
            trailing: SegmentedButton<ThemeMode>(
              segments: const <ButtonSegment<ThemeMode>>[
                ButtonSegment<ThemeMode>(
                    value: ThemeMode.light,
                    icon: Icon(Icons.light_mode, size: 16)),
                ButtonSegment<ThemeMode>(
                    value: ThemeMode.dark,
                    icon: Icon(Icons.dark_mode, size: 16)),
              ],
              selected: <ThemeMode>{themeMode},
              onSelectionChanged: (Set<ThemeMode> selection) => ref
                  .read(themeModeProvider.notifier)
                  .setThemeMode(selection.first),
            ),
          ),
          const Divider(height: 24),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(RouteNames.privacyPolicy),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Terms & Conditions'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(RouteNames.terms),
          ),
          const Divider(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('Follow Us',
                style: Theme.of(context).textTheme.titleMedium),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _socialButton(FontAwesomeIcons.facebook,
                  () => LauncherUtils.openUrl(AppConstants.facebookUrl)),
              _socialButton(FontAwesomeIcons.instagram,
                  () => LauncherUtils.openUrl(AppConstants.instagramUrl)),
              _socialButton(FontAwesomeIcons.linkedin,
                  () => LauncherUtils.openUrl(AppConstants.linkedinUrl)),
              _socialButton(FontAwesomeIcons.tiktok,
                  () => LauncherUtils.openUrl(AppConstants.tiktokUrl)),
              _socialButton(FontAwesomeIcons.youtube,
                  () => LauncherUtils.openUrl(AppConstants.youtubeUrl)),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _socialButton(IconData icon, VoidCallback onTap) {
    return IconButton(icon: FaIcon(icon, size: 20), onPressed: onTap);
  }
}
