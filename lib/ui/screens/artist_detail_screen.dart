import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../services/app_state.dart';
import '../widgets/album_grid.dart';
import '../widgets/track_list.dart';

class ArtistDetailScreen extends StatelessWidget {
  const ArtistDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final artist = state.selectedArtist;
    if (artist == null) return const SizedBox.shrink();

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _ArtistHero(artist: artist),

        if (state.contentLoading && state.selectedArtistTopTracks.isEmpty)
          const Padding(
            padding: EdgeInsets.all(40),
            child: Center(child: CircularProgressIndicator()),
          )
        else
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (state.selectedArtistTopTracks.isNotEmpty) ...[
                  const _SectionTitle('Popular'),
                  const SizedBox(height: 8),
                  TrackList(
                    tracks: state.selectedArtistTopTracks.take(5).toList(),
                    onTap: (track, index) => state.playTrack(
                      track,
                      trackList: state.selectedArtistTopTracks,
                      index: index,
                    ),
                  ),
                  const SizedBox(height: 32),
                ],

                if (state.selectedArtistBio != null &&
                    state.selectedArtistBio!.plainText.trim().isNotEmpty) ...[
                  const _SectionTitle('About'),
                  const SizedBox(height: 12),
                  _BioBlock(bio: state.selectedArtistBio!),
                  const SizedBox(height: 32),
                ],

                if (state.selectedArtistAlbums.isNotEmpty) ...[
                  const _SectionTitle('Albums'),
                  const SizedBox(height: 12),
                  AlbumGrid(
                    albums: state.selectedArtistAlbums,
                    onTap: (album) => state.selectAlbum(album),
                  ),
                  const SizedBox(height: 32),
                ],

                if (state.selectedArtistEpsAndSingles.isNotEmpty) ...[
                  const _SectionTitle('Singles & EPs'),
                  const SizedBox(height: 12),
                  AlbumGrid(
                    albums: state.selectedArtistEpsAndSingles,
                    onTap: (album) => state.selectAlbum(album),
                  ),
                  const SizedBox(height: 32),
                ],

                if (state.selectedArtistCompilations.isNotEmpty) ...[
                  const _SectionTitle('Appears On'),
                  const SizedBox(height: 12),
                  AlbumGrid(
                    albums: state.selectedArtistCompilations,
                    onTap: (album) => state.selectAlbum(album),
                  ),
                  const SizedBox(height: 32),
                ],

                if (state.selectedArtistSimilar.isNotEmpty) ...[
                  const _SectionTitle('Fans Also Like'),
                  const SizedBox(height: 12),
                  _SimilarArtistsRow(artists: state.selectedArtistSimilar),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _ArtistHero extends StatelessWidget {
  final Artist artist;
  const _ArtistHero({required this.artist});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final hasImage = artist.imageUrl.isNotEmpty;

    return SizedBox(
      height: 360,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Crisp artist photo as backdrop.
          if (hasImage)
            Image.network(
              artist.heroImageUrl.isNotEmpty
                  ? artist.heroImageUrl
                  : artist.imageUrl,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              errorBuilder: (_, __, ___) =>
                  Container(color: const Color(0xFF1A1A1A)),
            )
          else
            Container(color: const Color(0xFF1A1A1A)),

          // Bottom fade for text legibility + side fade for buttons row.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Color(0x80000000),
                  Color(0xFF0A0A0A),
                ],
                stops: [0.35, 0.75, 1.0],
              ),
            ),
          ),

          // Foreground: name + actions at bottom-left.
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 24, 32, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'ARTIST',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        letterSpacing: 1.4,
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  artist.name,
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.6),
                            blurRadius: 14,
                          ),
                        ],
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    FilledButton.icon(
                      onPressed: state.selectedArtistTopTracks.isNotEmpty
                          ? () => state.playTrack(
                                state.selectedArtistTopTracks.first,
                                trackList: state.selectedArtistTopTracks,
                                index: 0,
                              )
                          : null,
                      icon: const Icon(Icons.play_arrow_rounded, size: 22),
                      label: const Text('Play'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 22, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _FollowButton(artist: artist),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.headlineMedium,
    );
  }
}

class _BioBlock extends StatefulWidget {
  final ArtistBio bio;
  const _BioBlock({required this.bio});

  @override
  State<_BioBlock> createState() => _BioBlockState();
}

class _BioBlockState extends State<_BioBlock> {
  bool _expanded = false;
  static const _collapsedLines = 6;

  @override
  Widget build(BuildContext context) {
    final text = widget.bio.plainText.trim();
    final isLong = text.length > 380;
    final source = widget.bio.source;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.55,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
            maxLines: _expanded ? null : _collapsedLines,
            overflow:
                _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
          ),
          if (isLong) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => setState(() => _expanded = !_expanded),
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  foregroundColor: Theme.of(context).colorScheme.primary,
                ),
                child: Text(_expanded ? 'Show less' : 'Read more'),
              ),
            ),
          ],
          if (source != null && source.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Bio via $source',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white38,
                    fontStyle: FontStyle.italic,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SimilarArtistsRow extends StatelessWidget {
  final List<Artist> artists;
  const _SimilarArtistsRow({required this.artists});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: artists.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final artist = artists[index];
          return _SimilarArtistCard(artist: artist);
        },
      ),
    );
  }
}

class _SimilarArtistCard extends StatefulWidget {
  final Artist artist;
  const _SimilarArtistCard({required this.artist});

  @override
  State<_SimilarArtistCard> createState() => _SimilarArtistCardState();
}

class _SimilarArtistCardState extends State<_SimilarArtistCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: () => context.read<AppState>().selectArtist(widget.artist),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          transform: _hover
              ? (Matrix4.identity()..scale(1.04, 1.04, 1.0))
              : Matrix4.identity(),
          child: SizedBox(
            width: 110,
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white10,
                  backgroundImage: widget.artist.imageUrl.isNotEmpty
                      ? NetworkImage(widget.artist.imageUrl)
                      : null,
                  child: widget.artist.imageUrl.isEmpty
                      ? const Icon(Icons.person, size: 36)
                      : null,
                ),
                const SizedBox(height: 8),
                Text(
                  widget.artist.name,
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FollowButton extends StatefulWidget {
  final Artist artist;
  const _FollowButton({required this.artist});

  @override
  State<_FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends State<_FollowButton> {
  bool _hover = false;
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final following = state.isArtistFavorited(widget.artist.id);

    final fg = following ? Colors.white : Colors.white.withValues(alpha: 0.85);
    final bg = following
        ? Colors.white.withValues(alpha: _hover ? 0.18 : 0.12)
        : (_hover
            ? Colors.white.withValues(alpha: 0.10)
            : Colors.transparent);
    final border = following
        ? Colors.white.withValues(alpha: 0.30)
        : Colors.white.withValues(alpha: 0.55);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: _busy
            ? null
            : () async {
                setState(() => _busy = true);
                final messenger = ScaffoldMessenger.of(context);
                try {
                  await context
                      .read<AppState>()
                      .toggleFavoriteArtist(widget.artist);
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: Colors.red.shade900,
                      content: Text('Failed: $e'),
                    ),
                  );
                } finally {
                  if (mounted) setState(() => _busy = false);
                }
              },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
          decoration: BoxDecoration(
            color: bg,
            border: Border.all(color: border, width: 1.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                following ? Icons.check_rounded : Icons.add_rounded,
                size: 18,
                color: fg,
              ),
              const SizedBox(width: 6),
              Text(
                following ? 'Following' : 'Follow',
                style: TextStyle(
                  color: fg,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
