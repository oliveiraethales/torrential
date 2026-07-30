import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../services/app_state.dart';
import '../widgets/add_to_playlist_menu.dart';
import '../widgets/artist_links.dart';

class NowPlayingScreen extends StatefulWidget {
  final VoidCallback onClose;

  const NowPlayingScreen({super.key, required this.onClose});

  @override
  State<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends State<NowPlayingScreen> {
  bool _showQueue = true;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final track = state.currentTrack;
    if (track == null) return const SizedBox.shrink();

    final size = MediaQuery.of(context).size;
    final artSize = (size.height * 0.42).clamp(180.0, 440.0);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Stack(
        children: [
          if (track.imageUrl.isNotEmpty)
            Positioned.fill(
              child: _AlbumBackdrop(imageUrl: track.imageUrl),
            ),
          SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: _buildPlayerColumn(context, state, track, artSize),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  child: _showQueue
                      ? SizedBox(
                          width: 360,
                          child: _QueuePanel(
                            onClose: () => setState(() => _showQueue = false),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerColumn(
      BuildContext context, AppState state, Track track, double artSize) {
    return Column(
      children: [
        // Top bar with collapse + queue toggle
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32),
                onPressed: widget.onClose,
                color: Colors.white70,
              ),
              const Spacer(),
              Builder(
                builder: (btnContext) => IconButton(
                  tooltip: 'Add to playlist',
                  icon: const Icon(Icons.playlist_add_rounded),
                  onPressed: () => showAddToPlaylistMenuFor(
                    anchorContext: btnContext,
                    track: track,
                  ),
                  color: Colors.white70,
                ),
              ),
              IconButton(
                tooltip: _showQueue ? 'Hide queue' : 'Show queue',
                icon: const Icon(Icons.queue_music_rounded),
                onPressed: () => setState(() => _showQueue = !_showQueue),
                color: _showQueue
                    ? Theme.of(context).colorScheme.primary
                    : Colors.white70,
              ),
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
                  errorBuilder: (_, __, ___) => _artPlaceholder(artSize),
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
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              ArtistLinks(
                artists: track.artists,
                textAlign: TextAlign.center,
                maxLines: 1,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white54,
                    ),
              ),
              if (track.album != null) ...[
                const SizedBox(height: 4),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () {
                      context.read<AppState>().selectAlbum(track.album!);
                      widget.onClose();
                    },
                    child: Text(
                      track.album!.title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white30,
                          ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
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
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 6),
                  overlayShape:
                      const RoundSliderOverlayShape(overlayRadius: 14),
                  activeTrackColor: Theme.of(context).colorScheme.primary,
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
                      Tooltip(
                        message: state.enableDolbyAtmos
                            ? 'Dolby Atmos enabled (click to toggle)'
                            : 'Dolby Atmos disabled (click to toggle)',
                        child: InkWell(
                          borderRadius: BorderRadius.circular(4),
                          onTap: () => state.toggleDolbyAtmos(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
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
                                      size: 14, color: Colors.white),
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
              tooltip: state.shuffle ? 'Shuffle on' : 'Shuffle off',
              icon: const Icon(Icons.shuffle_rounded),
              onPressed: () => state.toggleShuffle(),
              iconSize: 24,
              color: state.shuffle
                  ? Theme.of(context).colorScheme.primary
                  : Colors.white54,
            ),
            const SizedBox(width: 16),
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
            const SizedBox(width: 16),
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
              iconSize: 24,
              color: state.repeat == PlayerRepeatMode.off
                  ? Colors.white54
                  : Theme.of(context).colorScheme.primary,
            ),
          ],
        ),

        const Spacer(flex: 1),
      ],
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

class _QueuePanel extends StatefulWidget {
  final VoidCallback onClose;

  const _QueuePanel({required this.onClose});

  @override
  State<_QueuePanel> createState() => _QueuePanelState();
}

class _QueuePanelState extends State<_QueuePanel> {
  final _scrollController = ScrollController();
  int? _lastScrolledIndex;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToCurrent(int index, int total) {
    if (_lastScrolledIndex == index) return;
    _lastScrolledIndex = index;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      const itemHeight = 64.0;
      final target = (index * itemHeight - 80).clamp(
        0.0,
        _scrollController.position.maxScrollExtent,
      );
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final queue = state.queue;
    final currentIndex = state.queueIndex;
    final contextLabel = _deriveContextLabel(queue);

    if (currentIndex >= 0) {
      _scrollToCurrent(currentIndex, queue.length);
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF101010).withValues(alpha: 0.96),
        border: Border(
          left: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Playing from',
                        style:
                            Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.white38,
                                  letterSpacing: 0.5,
                                ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        contextLabel,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Hide queue',
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: widget.onClose,
                  color: Colors.white54,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Up Next',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.white54,
                        letterSpacing: 1.2,
                      ),
                ),
                Text(
                  '${queue.length} ${queue.length == 1 ? "track" : "tracks"}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.white38,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: Colors.white12),
          Expanded(
            child: queue.isEmpty
                ? Center(
                    child: Text(
                      'Queue is empty',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white38,
                          ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: queue.length,
                    itemBuilder: (context, i) => _QueueRow(
                      track: queue[i],
                      index: i,
                      isCurrent: i == currentIndex,
                      isPlaying: state.isPlaying,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  String _deriveContextLabel(List<Track> queue) {
    if (queue.isEmpty) return 'Queue';
    final firstAlbum = queue.first.album?.title;
    if (firstAlbum != null &&
        queue.every((t) => t.album?.title == firstAlbum)) {
      return firstAlbum;
    }
    final firstArtist = queue.first.artistNames;
    if (queue.every((t) => t.artistNames == firstArtist)) {
      return firstArtist;
    }
    return 'Queue';
  }
}

class _QueueRow extends StatefulWidget {
  final Track track;
  final int index;
  final bool isCurrent;
  final bool isPlaying;

  const _QueueRow({
    required this.track,
    required this.index,
    required this.isCurrent,
    required this.isPlaying,
  });

  @override
  State<_QueueRow> createState() => _QueueRowState();
}

class _QueueRowState extends State<_QueueRow> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final accent = Theme.of(context).colorScheme.primary;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: InkWell(
        onTap: () => state.playFromQueue(widget.index),
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: widget.isCurrent
                ? accent.withValues(alpha: 0.10)
                : _hovering
                    ? Colors.white.withValues(alpha: 0.04)
                    : null,
          ),
          child: Row(
            children: [
              SizedBox(
                width: 24,
                child: widget.isCurrent
                    ? Icon(
                        widget.isPlaying
                            ? Icons.equalizer_rounded
                            : Icons.pause_rounded,
                        size: 16,
                        color: accent,
                      )
                    : _hovering
                        ? const Icon(Icons.play_arrow_rounded,
                            size: 16, color: Colors.white)
                        : Text(
                            '${widget.index + 1}',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: Colors.white38),
                            textAlign: TextAlign.center,
                          ),
              ),
              const SizedBox(width: 8),
              if (widget.track.imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
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
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.track.displayTitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: widget.isCurrent ? accent : Colors.white,
                            fontWeight: widget.isCurrent
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.track.artistNames,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white54,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 28,
                child: _hovering
                    ? Builder(
                        builder: (btnContext) => IconButton(
                          tooltip: 'Add to playlist',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                              minWidth: 24, minHeight: 24),
                          iconSize: 16,
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
              const SizedBox(width: 4),
              Text(
                widget.track.durationFormatted,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white38,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
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
