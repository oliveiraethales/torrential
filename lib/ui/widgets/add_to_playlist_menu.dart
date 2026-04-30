import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../services/app_state.dart';
import 'create_playlist_dialog.dart';

/// Shows a sleek anchored picker for adding [track] to one of the user's
/// playlists. The popup is anchored to the [anchor] global rect (typically
/// the bounding box of the trigger button).
Future<void> showAddToPlaylistMenu({
  required BuildContext context,
  required Track track,
  required RelativeRect position,
}) async {
  await showMenu<void>(
    context: context,
    position: position,
    color: const Color(0xFF1E1E1E),
    elevation: 8,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
    ),
    constraints: const BoxConstraints(minWidth: 320, maxWidth: 320),
    items: [
      PopupMenuItem<void>(
        enabled: false,
        padding: EdgeInsets.zero,
        child: _AddToPlaylistContent(track: track),
      ),
    ],
  );
}

class _AddToPlaylistContent extends StatefulWidget {
  final Track track;
  const _AddToPlaylistContent({required this.track});

  @override
  State<_AddToPlaylistContent> createState() => _AddToPlaylistContentState();
}

class _AddToPlaylistContentState extends State<_AddToPlaylistContent> {
  String _query = '';
  int? _busyForUuidHash;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final all = state.userPlaylists;
    final filtered = _query.isEmpty
        ? all
        : all
            .where((p) =>
                p.title.toLowerCase().contains(_query.toLowerCase().trim()))
            .toList();

    return SizedBox(
      width: 320,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Text(
              'Add to playlist',
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: TextField(
              autofocus: true,
              onChanged: (v) => setState(() => _query = v),
              style: Theme.of(context).textTheme.bodyMedium,
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Filter playlists…',
                prefixIcon: const Icon(Icons.search, size: 18),
                prefixIconConstraints:
                    const BoxConstraints(minWidth: 32, minHeight: 32),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 10),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.04),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          _NewPlaylistRow(onTap: _createAndAdd),
          Divider(
            height: 1,
            thickness: 1,
            color: Colors.white.withValues(alpha: 0.05),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 280),
            child: filtered.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 24),
                    child: Center(
                      child: Text(
                        all.isEmpty
                            ? 'You have no playlists yet.'
                            : 'No matches.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final p = filtered[i];
                      final busy = _busyForUuidHash == p.uuid.hashCode;
                      return _PlaylistRow(
                        playlist: p,
                        busy: busy,
                        onTap: busy ? null : () => _add(p),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Future<void> _createAndAdd() async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final state = context.read<AppState>();
    // Close the popover so the dialog is the only modal on screen.
    navigator.pop();
    final created = await showCreatePlaylistDialog(navigator.context);
    if (created == null) return;
    try {
      await state.addTrackToPlaylist(widget.track, created);
      messenger.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          content: Text('Added to ${created.title}'),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red.shade900,
          content: Text('Created, but failed to add track: $e'),
        ),
      );
    }
  }

  Future<void> _add(Playlist playlist) async {
    setState(() => _busyForUuidHash = playlist.uuid.hashCode);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final state = context.read<AppState>();
    try {
      final added = await state.addTrackToPlaylist(widget.track, playlist);
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          content: Text(
            added > 0
                ? 'Added to ${playlist.title}'
                : 'Already in ${playlist.title}',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _busyForUuidHash = null);
      messenger.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red.shade900,
          content: Text('Failed to add: $e'),
        ),
      );
    }
  }
}

class _PlaylistRow extends StatefulWidget {
  final Playlist playlist;
  final bool busy;
  final VoidCallback? onTap;

  const _PlaylistRow({
    required this.playlist,
    required this.busy,
    required this.onTap,
  });

  @override
  State<_PlaylistRow> createState() => _PlaylistRowState();
}

class _PlaylistRowState extends State<_PlaylistRow> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.playlist;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: InkWell(
        onTap: widget.onTap,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: _hovering ? Colors.white.withValues(alpha: 0.05) : null,
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: p.imageUrl.isNotEmpty
                    ? Image.network(
                        p.imageUrl,
                        width: 36,
                        height: 36,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder(),
                      )
                    : _placeholder(),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.title,
                      style: Theme.of(context).textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${p.numberOfTracks} tracks',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (widget.busy)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 36,
      height: 36,
      color: Colors.white10,
      child: const Icon(Icons.playlist_play,
          size: 18, color: Colors.white30),
    );
  }
}

class _NewPlaylistRow extends StatefulWidget {
  final VoidCallback onTap;
  const _NewPlaylistRow({required this.onTap});

  @override
  State<_NewPlaylistRow> createState() => _NewPlaylistRowState();
}

class _NewPlaylistRowState extends State<_NewPlaylistRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: InkWell(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          color: _hover ? Colors.white.withValues(alpha: 0.05) : null,
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: Colors.white70,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'New playlist…',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  size: 18, color: Colors.white38),
            ],
          ),
        ),
      ),
    );
  }
}
