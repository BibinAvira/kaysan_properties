import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../models/project_model.dart';
import 'common_widgets.dart';

/// A developer card — used by Home's "Developers We Work With" and the
/// Developers screen: the developer's logo from the
/// `/developers` directory above their name, or their initial when the
/// directory has no logo for them.
class DeveloperTile extends StatelessWidget {
  const DeveloperTile(
      {super.key, required this.developer, required this.onTap});

  final DeveloperModel developer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Material(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(6, 8, 6, 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            children: <Widget>[
              Expanded(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: developer.logo.isNotEmpty
                        ? AppNetworkImage(
                            url: developer.logo, fit: BoxFit.contain)
                        : Container(
                            color: AppColors.divider,
                            alignment: Alignment.center,
                            child: Text(
                              developer.name.isNotEmpty
                                  ? developer.name[0].toUpperCase()
                                  : '?',
                              style: theme.textTheme.headlineSmall,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                developer.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelLarge?.copyWith(fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
