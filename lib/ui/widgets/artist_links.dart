import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../services/app_state.dart';

/// Renders a list of artist names as clickable links separated by commas.
/// Tapping a name navigates to the artist detail page.
class ArtistLinks extends StatelessWidget {
  final List<Artist> artists;
  final TextStyle? style;
  final TextStyle? linkStyle;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow overflow;

  const ArtistLinks({
    super.key,
    required this.artists,
    this.style,
    this.linkStyle,
    this.textAlign,
    this.maxLines,
    this.overflow = TextOverflow.ellipsis,
  });

  @override
  Widget build(BuildContext context) {
    if (artists.isEmpty) {
      return Text('Unknown Artist', style: style);
    }
    final state = context.read<AppState>();
    final baseStyle = style ?? Theme.of(context).textTheme.bodySmall;
    final hyper = (linkStyle ?? baseStyle)?.copyWith(
      decoration: TextDecoration.underline,
      decorationColor: Colors.transparent,
    );

    final spans = <InlineSpan>[];
    for (var i = 0; i < artists.length; i++) {
      if (i > 0) {
        spans.add(TextSpan(text: ', ', style: baseStyle));
      }
      final artist = artists[i];
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: _HoverableArtistName(
            name: artist.name,
            style: hyper,
            onTap: () => state.selectArtist(artist),
          ),
        ),
      );
    }

    return RichText(
      text: TextSpan(style: baseStyle, children: spans),
      textAlign: textAlign ?? TextAlign.start,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

class _HoverableArtistName extends StatefulWidget {
  final String name;
  final TextStyle? style;
  final VoidCallback onTap;

  const _HoverableArtistName({
    required this.name,
    required this.style,
    required this.onTap,
  });

  @override
  State<_HoverableArtistName> createState() => _HoverableArtistNameState();
}

class _HoverableArtistNameState extends State<_HoverableArtistName> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final base = widget.style ?? const TextStyle();
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Text(
          widget.name,
          style: base.copyWith(
            decoration:
                _hovering ? TextDecoration.underline : TextDecoration.none,
          ),
        ),
      ),
    );
  }
}
