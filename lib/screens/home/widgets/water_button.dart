import 'package:flutter/material.dart';

class WaterButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isPrimary;

  const WaterButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.isPrimary = false,
  });

  @override
  State<WaterButton> createState() => _WaterButtonState();
}

class _WaterButtonState extends State<WaterButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.onPressed == null) return;
    _controller.forward().then((_) {
      _controller.reverse();
    });
    widget.onPressed!();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.isPrimary ? 72.0 : 56.0;

    return ScaleTransition(
      scale: _scale,
      child: SizedBox(
        width: size,
        height: size,
        child: ElevatedButton(
          onPressed: widget.onPressed != null ? _handleTap : null,
          style: ElevatedButton.styleFrom(
            shape: const CircleBorder(),
            padding: EdgeInsets.zero,
            backgroundColor:
                widget.isPrimary ? Theme.of(context).colorScheme.primary : Theme.of(context).cardTheme.color,
            foregroundColor:
                widget.isPrimary ? Colors.white : Theme.of(context).colorScheme.primary,
            elevation: widget.isPrimary ? 4 : 1,
            disabledBackgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            disabledForegroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          child: Icon(widget.icon, size: widget.isPrimary ? 36 : 28),
        ),
      ),
    );
  }
}
