// lib/ui/router/transitions.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

CustomTransitionPage<T> fadeThroughPage<T>({required Widget child}) {
  return CustomTransitionPage<T>(
    child: child,
    transitionsBuilder: (context, animation, secondary, child) {
      final fadeIn = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      final fadeOut = CurvedAnimation(
        parent: secondary,
        curve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: fadeIn,
        child: FadeTransition(opacity: ReverseAnimation(fadeOut), child: child),
      );
    },
    transitionDuration: const Duration(milliseconds: 260),
  );
}

CustomTransitionPage<T> sharedAxisX<T>({required Widget child}) {
  return CustomTransitionPage<T>(
    child: child,
    transitionsBuilder: (context, anim, sec, child) {
      final slide =
          Tween<Offset>(begin: const Offset(0.08, 0), end: Offset.zero).animate(
            CurvedAnimation(
              parent: anim,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            ),
          );
      final fade = CurvedAnimation(parent: anim, curve: Curves.easeOut);
      return SlideTransition(
        position: slide,
        child: FadeTransition(opacity: fade, child: child),
      );
    },
    transitionDuration: const Duration(milliseconds: 260),
  );
}
