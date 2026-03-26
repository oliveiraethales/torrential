import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../services/app_state.dart';
import '../widgets/album_grid.dart';

class AlbumsCollectionScreen extends StatelessWidget {
  const AlbumsCollectionScreen({super.key});

  List<Album> _sortedAlbums(List<Album> albums, AlbumSortMode mode, bool ascending) {
    final sorted = List<Album>.from(albums);
    switch (mode) {
      case AlbumSortMode.title:
        sorted.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
      case AlbumSortMode.artist:
        sorted.sort((a, b) => a.artistNames.toLowerCase().compareTo(b.artistNames.toLowerCase()));
      case AlbumSortMode.year:
        sorted.sort((a, b) => (a.releaseDate ?? '').compareTo(b.releaseDate ?? ''));
    }
    return ascending ? sorted : sorted.reversed.toList();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return _CollectionView(
      title: 'Albums',
      isEmpty: state.favoriteAlbums.isEmpty,
      emptyIcon: Icons.album_outlined,
      emptyMessage: 'No albums in your collection',
      trailing: state.favoriteAlbums.isNotEmpty
          ? _SortDropdown(
              value: state.albumSortMode,
              ascending: state.albumSortAscending,
              onChanged: (mode) => state.setAlbumSort(mode),
            )
          : null,
      child: AlbumGrid(
        albums: _sortedAlbums(state.favoriteAlbums, state.albumSortMode, state.albumSortAscending),
        onTap: (album) => state.selectAlbum(album),
      ),
    );
  }
}

class _SortDropdown extends StatelessWidget {
  final AlbumSortMode value;
  final bool ascending;
  final ValueChanged<AlbumSortMode> onChanged;

  const _SortDropdown({required this.value, required this.ascending, required this.onChanged});

  String _label(AlbumSortMode mode) => switch (mode) {
        AlbumSortMode.title => 'Title',
        AlbumSortMode.artist => 'Artist',
        AlbumSortMode.year => 'Year',
      };

  IconData _icon(AlbumSortMode mode) => switch (mode) {
        AlbumSortMode.title => Icons.sort_by_alpha,
        AlbumSortMode.artist => Icons.person_outline,
        AlbumSortMode.year => Icons.calendar_today,
      };

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<AlbumSortMode>(
      onSelected: onChanged,
      tooltip: 'Sort albums',
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      color: const Color(0xFF1E1E1E),
      itemBuilder: (_) => AlbumSortMode.values.map((mode) {
        final isActive = mode == value;
        return PopupMenuItem(
          value: mode,
          child: Row(
            children: [
              Icon(_icon(mode), size: 18, color: isActive ? const Color(0xFF1DB954) : Colors.white70),
              const SizedBox(width: 8),
              Expanded(
                child: Text(_label(mode), style: TextStyle(color: isActive ? const Color(0xFF1DB954) : Colors.white)),
              ),
              if (isActive)
                Icon(ascending ? Icons.arrow_upward : Icons.arrow_downward, size: 14, color: const Color(0xFF1DB954)),
            ],
          ),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sort, size: 18, color: Colors.white70),
            const SizedBox(width: 6),
            Text(_label(value), style: const TextStyle(fontSize: 13, color: Colors.white70)),
            const SizedBox(width: 4),
            Icon(ascending ? Icons.arrow_upward : Icons.arrow_downward, size: 14, color: Colors.white38),
          ],
        ),
      ),
    );
  }
}

class ArtistsCollectionScreen extends StatelessWidget {
  const ArtistsCollectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return _CollectionView(
      title: 'Artists',
      isEmpty: state.favoriteArtists.isEmpty,
      emptyIcon: Icons.people_outlined,
      emptyMessage: 'No artists in your collection',
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 160,
          childAspectRatio: 0.75,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: state.favoriteArtists.length,
        itemBuilder: (context, index) {
          final artist = state.favoriteArtists[index];
          return InkWell(
            onTap: () => state.selectArtist(artist),
            borderRadius: BorderRadius.circular(8),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: Colors.white10,
                  backgroundImage: artist.imageUrl.isNotEmpty
                      ? NetworkImage(artist.imageUrl)
                      : null,
                  child: artist.imageUrl.isEmpty
                      ? const Icon(Icons.person, size: 32)
                      : null,
                ),
                const SizedBox(height: 8),
                Text(
                  artist.name,
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class PlaylistsCollectionScreen extends StatelessWidget {
  const PlaylistsCollectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return _CollectionView(
      title: 'Playlists',
      isEmpty: state.userPlaylists.isEmpty,
      emptyIcon: Icons.playlist_play_outlined,
      emptyMessage: 'No playlists yet',
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 200,
          childAspectRatio: 0.8,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: state.userPlaylists.length,
        itemBuilder: (context, index) {
          final playlist = state.userPlaylists[index];
          return InkWell(
            onTap: () => state.selectPlaylist(playlist),
            borderRadius: BorderRadius.circular(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: playlist.imageUrl.isNotEmpty
                        ? Image.network(
                            playlist.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.white10,
                              child: const Icon(Icons.playlist_play,
                                  size: 48, color: Colors.white24),
                            ),
                          )
                        : Container(
                            color: Colors.white10,
                            child: const Icon(Icons.playlist_play,
                                size: 48, color: Colors.white24),
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  playlist.title,
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${playlist.numberOfTracks} tracks',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CollectionView extends StatelessWidget {
  final String title;
  final bool isEmpty;
  final IconData emptyIcon;
  final String emptyMessage;
  final Widget child;
  final Widget? trailing;

  const _CollectionView({
    required this.title,
    required this.isEmpty,
    required this.emptyIcon,
    required this.emptyMessage,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          children: [
            Expanded(child: Text(title, style: Theme.of(context).textTheme.headlineLarge)),
            if (trailing != null) trailing!,
          ],
        ),
        const SizedBox(height: 24),
        if (isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 80),
              child: Column(
                children: [
                  Icon(emptyIcon, size: 64, color: Colors.white24),
                  const SizedBox(height: 16),
                  Text(
                    emptyMessage,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          )
        else
          child,
      ],
    );
  }
}
