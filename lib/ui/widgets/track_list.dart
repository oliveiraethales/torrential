import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../services/app_state.dart';
import 'add_to_playlist_menu.dart';
import 'artist_links.dart';

class TrackList extends StatelessWidget {
  final List<Track> tracks;
  final void Function(Track track, int index) onTap;
  final bool showTrackNumber;
  final bool showAlbum;

  const TrackList({
    super.key,
    required this.tracks,
    required this.onTap,
    this.showTrackNumber = false,
    this.showAlbum = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < tracks.length; i++)
          _TrackRow(
            track: tracks[i],
            index: i,
            onTap: () => onTap(tracks[i], i),
            showTrackNumber: showTrackNumber,
            showAlbum: showAlbum,
          ),
      ],
    );
  }
}

class _TrackRow extends StatefulWidget {
  final Track track;
  final int index;
  final VoidCallback onTap;
  final bool showTrackNumber;
  final bool showAlbum;

  const _TrackRow({
    required this.track,
    required this.index,
    required this.onTap,
    required this.showTrackNumber,
    required this.showAlbum,
  });

  @override
  State<_TrackRow> createState() => _TrackRowState();
}

class _TrackRowState extends State<_TrackRow> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: _hovering ? Colors.white.withValues(alpha: 0.05) : null,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              // Track number or play icon
              SizedBox(
                width: 32,
                child: _hovering
                    ? const Icon(Icons.play_arrow_rounded,
                        size: 18, color: Colors.white)
                    : Text(
                        widget.showTrackNumber
                            ? '${widget.track.trackNumber}'
                            : '${widget.index + 1}',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
              ),

              // Cover art (if not showing track numbers from album)
              if (!widget.showTrackNumber && widget.track.imageUrl.isNotEmpty) ...[
                const SizedBox(width: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.network(
                    widget.track.imageUrl,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 40,
                      height: 40,
                      color: Colors.white10,
                    ),
                  ),
                ),
              ],

              const SizedBox(width: 12),

              // Title and artist
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            widget.track.displayTitle,
                            style: Theme.of(context).textTheme.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (widget.track.explicit) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.white30),
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: const Text(
                              'E',
                              style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.white38,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    DefaultTextStyle.merge(
                      style: Theme.of(context).textTheme.bodySmall ??
                          const TextStyle(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      child: Row(
                        children: [
                          Flexible(
                            child: ArtistLinks(
                              artists: widget.track.artists,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                          if (widget.showAlbum && widget.track.album != null) ...[
                            Text(
                              ' · ',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Flexible(
                              child: _AlbumLink(album: widget.track.album!),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Quality indicator
              if (widget.track.isDolbyAtmos)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8A2BE2), Color(0xFF00B4D8)],
                      ),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: const Text(
                      'ATMOS',
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                )
              else if (widget.track.audioQuality == 'HI_RES_LOSSLESS' ||
                  widget.track.audioQuality == 'HI_RES')
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      'Hi-Res',
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

              // Add-to-playlist (visible on hover)
              SizedBox(
                width: 32,
                child: _hovering
                    ? Builder(
                        builder: (btnContext) => IconButton(
                          tooltip: 'Add to playlist',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                              minWidth: 28, minHeight: 28),
                          iconSize: 18,
                          color: Colors.white70,
                          icon: const Icon(Icons.playlist_add_rounded),
                          onPressed: () => showAddToPlaylistMenuFor(
                            anchorContext: btnContext,
                            track: widget.track,
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 8),

              // Favorite heart
              _FavoriteHeart(track: widget.track, hovering: _hovering),
              const SizedBox(width: 8),

              // Duration
              Text(
                widget.track.durationFormatted,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FavoriteHeart extends StatelessWidget {
  final Track track;
  final bool hovering;
  const _FavoriteHeart({required this.track, required this.hovering});

  static const _likedColor = Color(0xFFFF4D6A);

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final liked = state.isTrackFavorited(track.id);
    if (!liked && !hovering) {
      return const SizedBox(width: 22);
    }
    return SizedBox(
      width: 22,
      child: IconButton(
        tooltip: liked ? 'Unlike' : 'Like',
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
        iconSize: 16,
        icon: Icon(
          liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          color: liked ? _likedColor : Colors.white38,
        ),
        onPressed: () async {
          final messenger = ScaffoldMessenger.of(context);
          try {
            await state.toggleFavoriteTrack(track);
          } catch (e) {
            messenger.showSnackBar(
              SnackBar(
                behavior: SnackBarBehavior.floating,
                backgroundColor: Colors.red.shade900,
                content: Text('Failed: $e'),
              ),
            );
          }
        },
      ),
    );
  }
}

class _AlbumLink extends StatefulWidget {
  final Album album;
  const _AlbumLink({required this.album});

  @override
  State<_AlbumLink> createState() => _AlbumLinkState();
}

class _AlbumLinkState extends State<_AlbumLink> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: () => context.read<AppState>().selectAlbum(widget.album),
        child: Text(
          widget.album.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                decoration:
                    _hover ? TextDecoration.underline : TextDecoration.none,
              ),
        ),
      ),
    );
  }
}
