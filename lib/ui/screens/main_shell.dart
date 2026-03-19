import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/app_state.dart';
import '../widgets/now_playing_bar.dart';
import 'home_screen.dart';
import 'search_screen.dart';
import 'collection_screen.dart';
import 'album_detail_screen.dart';
import 'artist_detail_screen.dart';
import 'playlist_detail_screen.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                // Sidebar
                _Sidebar(),
                // Divider
                Container(
                  width: 1,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
                // Main content
                Expanded(
                  child: Column(
                    children: [
                      // Top bar with back button
                      if (state.canGoBack)
                        Container(
                          height: 48,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_back_rounded,
                                    size: 20),
                                onPressed: () => state.goBack(),
                                color: Colors.white70,
                              ),
                            ],
                          ),
                        ),
                      Expanded(child: _buildContent(state)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Now playing bar
          const NowPlayingBar(),
        ],
      ),
    );
  }

  Widget _buildContent(AppState state) {
    // Detail views take priority
    if (state.selectedAlbum != null) return const AlbumDetailScreen();
    if (state.selectedArtist != null) return const ArtistDetailScreen();
    if (state.selectedPlaylist != null) return const PlaylistDetailScreen();

    switch (state.currentNav) {
      case NavDestination.home:
        return const HomeScreen();
      case NavDestination.search:
        return const SearchScreen();
      case NavDestination.albums:
        return const AlbumsCollectionScreen();
      case NavDestination.artists:
        return const ArtistsCollectionScreen();
      case NavDestination.playlists:
        return const PlaylistsCollectionScreen();
    }
  }
}

class _Sidebar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Container(
      width: 220,
      color: const Color(0xFF0F0F0F),
      child: Column(
        children: [
          const SizedBox(height: 16),
          // App logo
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.waves_rounded, size: 24, color: Colors.white),
                const SizedBox(width: 10),
                Text(
                  'Torrential',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Navigation items
          _NavItem(
            icon: Icons.home_rounded,
            label: 'Home',
            selected: state.currentNav == NavDestination.home,
            onTap: () => state.navigateTo(NavDestination.home),
          ),
          _NavItem(
            icon: Icons.search_rounded,
            label: 'Search',
            selected: state.currentNav == NavDestination.search,
            onTap: () => state.navigateTo(NavDestination.search),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Divider(height: 1),
          ),

          Padding(
            padding: const EdgeInsets.only(left: 20, bottom: 8),
            child: Text(
              'LIBRARY',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),

          _NavItem(
            icon: Icons.album_rounded,
            label: 'Albums',
            selected: state.currentNav == NavDestination.albums,
            onTap: () => state.navigateTo(NavDestination.albums),
          ),
          _NavItem(
            icon: Icons.people_rounded,
            label: 'Artists',
            selected: state.currentNav == NavDestination.artists,
            onTap: () => state.navigateTo(NavDestination.artists),
          ),
          _NavItem(
            icon: Icons.playlist_play_rounded,
            label: 'Playlists',
            selected: state.currentNav == NavDestination.playlists,
            onTap: () => state.navigateTo(NavDestination.playlists),
          ),

          const Spacer(),

          // Settings / Logout
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextButton.icon(
              onPressed: () => state.logout(),
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text('Sign out'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white38,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: InkWell(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: widget.selected
                ? Colors.white.withValues(alpha: 0.08)
                : _hovering
                    ? Colors.white.withValues(alpha: 0.04)
                    : null,
            border: widget.selected
                ? const Border(
                    left: BorderSide(color: Colors.white, width: 3),
                  )
                : null,
          ),
          child: Row(
            children: [
              Icon(
                widget.icon,
                size: 20,
                color: widget.selected ? Colors.white : Colors.white54,
              ),
              const SizedBox(width: 12),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight:
                      widget.selected ? FontWeight.w600 : FontWeight.w400,
                  color: widget.selected ? Colors.white : Colors.white54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
