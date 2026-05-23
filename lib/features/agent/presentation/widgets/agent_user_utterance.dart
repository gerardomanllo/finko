import 'package:flutter/material.dart';

class AgentUserUtterance extends StatelessWidget {
  const AgentUserUtterance({
    super.key,
    required this.text,
    this.sending = false,
    this.animate = true,
  });

  final String text;
  final bool sending;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final bubble = Align(
      alignment: Alignment.centerRight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (sending) ...[
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.colorScheme.primary.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width * 0.78,
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.primary.withValues(alpha: 0.88),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(6),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.22),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Text(
                    text,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      height: 1.35,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (!animate) return bubble;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 24, end: 0),
      duration: const Duration(milliseconds: 340),
      curve: Curves.easeOutCubic,
      builder: (context, dy, child) => Transform.translate(
        offset: Offset(0, dy),
        child: Opacity(opacity: (24 - dy) / 24, child: child),
      ),
      child: bubble,
    );
  }
}
