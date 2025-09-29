import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class FallbackNetworkImage extends StatefulWidget {
  const FallbackNetworkImage({
    super.key,
    required this.candidates,
    this.headers,
    this.placeholderColor,
    this.fit = BoxFit.cover,
  });

  final List<String> candidates;
  final Map<String, String>? headers;
  final Color? placeholderColor;
  final BoxFit fit;

  @override
  State<FallbackNetworkImage> createState() => _FallbackNetworkImageState();
}

class _FallbackNetworkImageState extends State<FallbackNetworkImage> {
  int _i = 0;

  @override
  Widget build(BuildContext context) {
    final bg =
        widget.placeholderColor ?? Theme.of(context).colorScheme.surfaceContainerHighest;
    if (widget.candidates.isEmpty) {
      return Container(color: bg, child: const Icon(Icons.broken_image));
    }
    final url = widget.candidates[_i];
    return CachedNetworkImage(
      imageUrl: url,
      httpHeaders: widget.headers,
      fit: widget.fit,
      placeholder: (_, __) => Container(color: bg),
      errorWidget: (_, __, ___) {
        if (_i + 1 < widget.candidates.length) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _i += 1);
          });
          return Container(color: bg);
        }
        return Container(color: bg, child: const Icon(Icons.broken_image));
      },
    );
  }
}
