import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../services/app_state.dart';
import '../widgets/album_grid.dart';

class ComposersCollectionScreen extends StatefulWidget {
  const ComposersCollectionScreen({super.key});

  @override
  State<ComposersCollectionScreen> createState() => _ComposersCollectionScreenState();
}

class _ComposersCollectionScreenState extends State<ComposersCollectionScreen> {
  @override
  void initState() {
    super.initState();
    final state = context.read<AppState>();
    if (!state.composersLoaded && !state.composersLoading && state.favoriteAlbums.isNotEmpty) {
      state.loadComposers();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    if (state.selectedComposer != null) {
      return _ComposerAlbumsView(
        composer: state.selectedComposer!,
        albums: state.selectedComposerAlbums,
        onAlbumTap: (album) => state.selectAlbum(album),
      );
    }

    return _ComposersListView(
      composers: state.allComposers,
      loading: state.composersLoading,
      error: state.composersError,
      onTap: (composer) => state.selectComposer(composer),
    );
  }
}

class _ComposersListView extends StatelessWidget {
  final List<String> composers;
  final bool loading;
  final String? error;
  final ValueChanged<String> onTap;

  const _ComposersListView({
    required this.composers,
    required this.loading,
    this.error,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Composers', style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 24),
        if (loading && composers.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.only(top: 80),
              child: CircularProgressIndicator(),
            ),
          )
        else if (!loading && composers.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 80),
              child: Column(
                children: [
                  Icon(
                    error != null ? Icons.error_outline : Icons.music_note_outlined,
                    size: 64,
                    color: error != null ? Colors.red.withValues(alpha: 0.5) : Colors.white24,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    error ?? 'No composers found',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          )
        else ...[
          if (loading)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Loading composers…',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 160,
              childAspectRatio: 0.85,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: composers.length,
            itemBuilder: (context, index) {
              final composer = composers[index];
              return _ComposerCard(
                name: composer,
                onTap: () => onTap(composer),
              );
            },
          ),
        ],
      ],
    );
  }
}

class _ComposerCard extends StatefulWidget {
  final String name;
  final VoidCallback onTap;

  const _ComposerCard({required this.name, required this.onTap});

  @override
  State<_ComposerCard> createState() => _ComposerCardState();
}

class _ComposerCardState extends State<_ComposerCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          transform: _hovering
              ? (Matrix4.identity()..scale(1.02, 1.02, 1.0))
              : Matrix4.identity(),
          child: Column(
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: _hovering
                    ? Colors.white.withValues(alpha: 0.12)
                    : Colors.white.withValues(alpha: 0.06),
                child: const Icon(Icons.music_note_rounded, size: 32, color: Colors.white54),
              ),
              const SizedBox(height: 8),
              Text(
                widget.name,
                style: Theme.of(context).textTheme.titleMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ComposerAlbumsView extends StatelessWidget {
  final String composer;
  final List<Album> albums;
  final void Function(Album) onAlbumTap;

  const _ComposerAlbumsView({
    required this.composer,
    required this.albums,
    required this.onAlbumTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: Colors.white.withValues(alpha: 0.06),
              child: const Icon(Icons.music_note_rounded, size: 28, color: Colors.white54),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    composer,
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${albums.length} album${albums.length == 1 ? '' : 's'}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        AlbumGrid(
          albums: albums,
          onTap: onAlbumTap,
        ),
      ],
    );
  }
}
