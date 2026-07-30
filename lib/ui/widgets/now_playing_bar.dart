import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/app_state.dart';
import 'add_to_playlist_menu.dart';
import 'artist_links.dart';

class NowPlayingBar extends StatelessWidget {
  final VoidCallback? onArtTap;

  const NowPlayingBar({super.key, this.onArtTap});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final track = state.currentTrack;
    if (track == null) return const SizedBox.shrink();

    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: const Color(0xFF181818),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),
      child: Column(
        children: [
          // Seekable progress bar
          SizedBox(
            height: 3,
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 0),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 0),
                activeTrackColor: Theme.of(context).colorScheme.primary,
                inactiveTrackColor: Colors.white10,
              ),
              child: Slider(
                value: state.totalDuration.inMilliseconds > 0
                    ? (state.position.inMilliseconds /
                            state.totalDuration.inMilliseconds)
                        .clamp(0.0, 1.0)
                    : 0.0,
                onChanged: (value) {
                  final pos = Duration(
                      milliseconds:
                          (value * state.totalDuration.inMilliseconds).round());
                  state.seekTo(pos);
                },
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  // Track info
                  if (track.imageUrl.isNotEmpty)
                    MouseRegion(
                      cursor: onArtTap != null
                          ? SystemMouseCursors.click
                          : SystemMouseCursors.basic,
                      child: GestureDetector(
                        onTap: onArtTap,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.network(
                            track.imageUrl,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 48,
                              height: 48,
                              color: Colors.white10,
                            ),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          track.displayTitle,
                          style: Theme.of(context).textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        ArtistLinks(
                          artists: track.artists,
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),

                  // Playback controls
                  Expanded(
                    flex: 2,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          tooltip: state.shuffle ? 'Shuffle on' : 'Shuffle off',
                          icon: const Icon(Icons.shuffle_rounded),
                          onPressed: () => state.toggleShuffle(),
                          iconSize: 18,
                          color: state.shuffle
                              ? Theme.of(context).colorScheme.primary
                              : Colors.white54,
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(Icons.skip_previous_rounded),
                          onPressed: () => state.playPrevious(),
                          iconSize: 28,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(
                            state.isPlaying
                                ? Icons.pause_circle_filled_rounded
                                : Icons.play_circle_filled_rounded,
                          ),
                          onPressed: () => state.togglePlayPause(),
                          iconSize: 42,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.skip_next_rounded),
                          onPressed: () => state.playNext(),
                          iconSize: 28,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          tooltip: switch (state.repeat) {
                            PlayerRepeatMode.off => 'Repeat off',
                            PlayerRepeatMode.all => 'Repeat all',
                            PlayerRepeatMode.one => 'Repeat one',
                          },
                          icon: Icon(
                            state.repeat == PlayerRepeatMode.one
                                ? Icons.repeat_one_rounded
                                : Icons.repeat_rounded,
                          ),
                          onPressed: () => state.cycleRepeat(),
                          iconSize: 18,
                          color: state.repeat == PlayerRepeatMode.off
                              ? Colors.white54
                              : Theme.of(context).colorScheme.primary,
                        ),
                      ],
                    ),
                  ),

                  // Quality info & volume
                  Expanded(
                    flex: 2,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Builder(
                          builder: (btnContext) => IconButton(
                            tooltip: 'Add to playlist',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                                minWidth: 32, minHeight: 32),
                            iconSize: 20,
                            color: Colors.white54,
                            icon: const Icon(Icons.playlist_add_rounded),
                            onPressed: () => showAddToPlaylistMenuFor(
                              anchorContext: btnContext,
                              track: track,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          tooltip: state.isTrackFavorited(track.id)
                              ? 'Unlike'
                              : 'Like',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                              minWidth: 32, minHeight: 32),
                          iconSize: 20,
                          icon: Icon(
                            state.isTrackFavorited(track.id)
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: state.isTrackFavorited(track.id)
                                ? const Color(0xFFFF4D6A)
                                : Colors.white54,
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
                        const SizedBox(width: 8),
                        if (state.currentPlaybackInfo != null)
                          Tooltip(
                            message: state.enableDolbyAtmos
                                ? 'Dolby Atmos enabled (click to toggle)'
                                : 'Dolby Atmos disabled (click to toggle)',
                            child: InkWell(
                              borderRadius: BorderRadius.circular(4),
                              onTap: () => state.toggleDolbyAtmos(),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  gradient: state.currentPlaybackInfo!.isDolbyAtmos
                                      ? const LinearGradient(
                                          colors: [Color(0xFF8A2BE2), Color(0xFF00B4D8)],
                                        )
                                      : null,
                                  color: state.currentPlaybackInfo!.isDolbyAtmos
                                      ? null
                                      : Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (state.currentPlaybackInfo!.isDolbyAtmos) ...[
                                      const Icon(Icons.spatial_audio_rounded,
                                          size: 12, color: Colors.white),
                                      const SizedBox(width: 4),
                                    ],
                                    Text(
                                      state.currentPlaybackInfo!.qualityLabel,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: state.currentPlaybackInfo!.isDolbyAtmos
                                            ? Colors.white
                                            : Theme.of(context).colorScheme.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(width: 12),
                        Text(
                          _formatDuration(state.position),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          ' / ',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          _formatDuration(state.totalDuration),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          tooltip: 'Show queue',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                              minWidth: 32, minHeight: 32),
                          iconSize: 20,
                          icon: const Icon(Icons.queue_music_rounded),
                          color: Colors.white54,
                          onPressed: onArtTap,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
