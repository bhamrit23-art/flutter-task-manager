import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/app_services.dart';
import 'responsive.dart';

/// Shared frame for the sign-in and sign-up screens: logo, heading and a
/// narrow centred column that becomes a card on tablets and desktops.
class AuthLayout extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;

  const AuthLayout({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final usesFirebase = context.watch<AppServices>().usesFirebase;
    final wide = !isCompact(context);

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: scheme.primary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.check_rounded, color: scheme.onPrimary, size: 28),
          ),
        ),
        const SizedBox(height: 24),
        Text(title, style: theme.textTheme.headlineMedium),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 28),
        ...children,
        if (!usesFirebase) ...[
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Icon(
                  Icons.info_outline,
                  size: 15,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Local mode: accounts and tasks are saved on this device.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(wide ? 32 : 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: wide ? 440 : 400),
              child: wide
                  ? Card(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: content,
                      ),
                    )
                  : content,
            ),
          ),
        ),
      ),
    );
  }
}
