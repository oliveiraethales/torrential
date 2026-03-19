import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/app_state.dart';
import '../widgets/track_list.dart';

class AlbumDetailScreen extends StatelessWidget {
  const AlbumDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final album = state.selectedAlbum;
    if (album == null) return const SizedBox.shrink();

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // Album header
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover art
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: album.imageUrl.isNotEmpty
                  ? Image.network(
                      album.imageUrl,
                      width: 220,
                      height: 220,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder(),
                    )
                  : _placeholder(),
            ),
            const SizedBox(width: 24),
            // Album info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    album.title,
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      if (album.artists.isNotEmpty) {
                        state.selectArtist(album.artists.first);
                      }
                    },
                    child: Text(
                      album.artistNames,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (album.year != null)
                        _InfoChip(label: album.year!),
                      if (album.numberOfTracks != null) ...[
                        const SizedBox(width: 8),
                        _InfoChip(label: '${album.numberOfTracks} tracks'),
                      ],
                      if (album.audioQuality != null) ...[
                        const SizedBox(width: 8),
                        _InfoChip(
                          label: _qualityLabel(album.audioQuality!),
                          highlight: album.audioQuality == 'HI_RES_LOSSLESS' ||
                              album.audioQuality == 'HI_RES',
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Play all button
                  FilledButton.icon(
                    onPressed: state.selectedAlbumTracks.isNotEmpty
                        ? () => state.playTrack(
                              state.selectedAlbumTracks.first,
                              trackList: state.selectedAlbumTracks,
                              index: 0,
                            )
                        : null,
                    icon: const Icon(Icons.play_arrow_rounded, size: 22),
                    label: const Text('Play'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 32),

        // Track list
        if (state.contentLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(),
            ),
          )
        else
          TrackList(
            tracks: state.selectedAlbumTracks,
            showTrackNumber: true,
            onTap: (track, index) => state.playTrack(
              track,
              trackList: state.selectedAlbumTracks,
              index: index,
            ),
          ),
      ],
    );
  }

  Widget _placeholder() {
    return Container(
      width: 220,
      height: 220,
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.album, size: 64, color: Colors.white24),
    );
  }

  String _qualityLabel(String quality) {
    switch (quality) {
      case 'HI_RES_LOSSLESS':
      case 'HI_RES':
        return 'Hi-Res';
      case 'LOSSLESS':
        return 'Lossless';
      case 'HIGH':
        return 'High';
      default:
        return quality;
    }
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final bool highlight;

  const _InfoChip({required this.label, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: highlight ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2) : Colors.white10,
        borderRadius: BorderRadius.circular(4),
        border: highlight
            ? Border.all(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4))
            : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: highlight
              ? Theme.of(context).colorScheme.primary
              : Colors.white54,
        ),
      ),
    );
  }
}
