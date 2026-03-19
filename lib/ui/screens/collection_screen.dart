import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/app_state.dart';
import '../widgets/album_grid.dart';

class AlbumsCollectionScreen extends StatelessWidget {
  const AlbumsCollectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return _CollectionView(
      title: 'Albums',
      isEmpty: state.favoriteAlbums.isEmpty,
      emptyIcon: Icons.album_outlined,
      emptyMessage: 'No albums in your collection',
      child: AlbumGrid(
        albums: state.favoriteAlbums,
        onTap: (album) => state.selectAlbum(album),
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

  const _CollectionView({
    required this.title,
    required this.isEmpty,
    required this.emptyIcon,
    required this.emptyMessage,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineLarge),
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
