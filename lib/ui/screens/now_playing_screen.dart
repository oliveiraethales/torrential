import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/app_state.dart';

class NowPlayingScreen extends StatelessWidget {
  final VoidCallback onClose;

  const NowPlayingScreen({super.key, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final track = state.currentTrack;
    if (track == null) return const SizedBox.shrink();

    final size = MediaQuery.of(context).size;
    final artSize = (size.height * 0.45).clamp(200.0, 480.0);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Stack(
        children: [
          // Background gradient from album art dominant color
          if (track.imageUrl.isNotEmpty)
            Positioned.fill(
              child: _AlbumBackdrop(imageUrl: track.imageUrl),
            ),

          // Content
          SafeArea(
            child: Column(
              children: [
                // Top bar with collapse button
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.keyboard_arrow_down_rounded,
                            size: 32),
                        onPressed: onClose,
                        color: Colors.white70,
                      ),
                      const Spacer(),
                      if (track.album != null)
                        Text(
                          'Playing from',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.white38,
                                    letterSpacing: 0.5,
                                  ),
                        ),
                      const Spacer(),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),

                const Spacer(flex: 2),

                // Album art
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: track.imageUrl.isNotEmpty
                      ? Image.network(
                          track.imageUrl,
                          width: artSize,
                          height: artSize,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _artPlaceholder(artSize),
                        )
                      : _artPlaceholder(artSize),
                ),

                const Spacer(flex: 2),

                // Track info
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48),
                  child: Column(
                    children: [
                      Text(
                        track.displayTitle,
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        track.artistNames,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.white54,
                                ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (track.album != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          track.album!.title,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.white30,
                                  ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Progress bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48),
                  child: Column(
                    children: [
                      SliderTheme(
                        data: SliderThemeData(
                          trackHeight: 4,
                          thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 6),
                          overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 14),
                          activeTrackColor:
                              Theme.of(context).colorScheme.primary,
                          inactiveTrackColor: Colors.white12,
                          thumbColor: Colors.white,
                          overlayColor: Colors.white24,
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
                                    (value * state.totalDuration.inMilliseconds)
                                        .round());
                            state.seekTo(pos);
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDuration(state.position),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            if (state.currentPlaybackInfo != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  state.currentPlaybackInfo!.qualityLabel,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            Text(
                              _formatDuration(state.totalDuration),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Playback controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.skip_previous_rounded),
                      onPressed: () => state.playPrevious(),
                      iconSize: 40,
                      color: Colors.white70,
                    ),
                    const SizedBox(width: 24),
                    Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(
                          state.isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                        ),
                        onPressed: () => state.togglePlayPause(),
                        iconSize: 40,
                        color: Colors.black,
                        padding: const EdgeInsets.all(8),
                      ),
                    ),
                    const SizedBox(width: 24),
                    IconButton(
                      icon: const Icon(Icons.skip_next_rounded),
                      onPressed: () => state.playNext(),
                      iconSize: 40,
                      color: Colors.white70,
                    ),
                  ],
                ),

                const Spacer(flex: 1),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _artPlaceholder(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(Icons.album, size: size * 0.4, color: Colors.white24),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

class _AlbumBackdrop extends StatelessWidget {
  final String imageUrl;

  const _AlbumBackdrop({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) {
        return LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.3),
            Colors.transparent,
          ],
          stops: const [0.0, 0.6],
        ).createShader(bounds);
      },
      blendMode: BlendMode.dstIn,
      child: Image.network(
        imageUrl,
        fit: BoxFit.cover,
        color: Colors.black54,
        colorBlendMode: BlendMode.darken,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      ),
    );
  }
}
