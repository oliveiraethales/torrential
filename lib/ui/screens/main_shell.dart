import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/app_state.dart';
import '../widgets/now_playing_bar.dart';
import 'home_screen.dart';
import 'search_screen.dart';
import 'collection_screen.dart';
import 'composers_screen.dart';
import 'album_detail_screen.dart';
import 'artist_detail_screen.dart';
import 'playlist_detail_screen.dart';
import 'now_playing_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _heroController;
  late final Animation<Offset> _heroSlide;
  bool _showHero = false;

  @override
  void initState() {
    super.initState();
    _heroController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _heroSlide = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _heroController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    ));
    _heroController.addStatusListener((status) {
      if (status == AnimationStatus.dismissed) {
        setState(() => _showHero = false);
      }
    });
  }

  @override
  void dispose() {
    _heroController.dispose();
    super.dispose();
  }

  void _openHero() {
    setState(() => _showHero = true);
    _heroController.forward();
  }

  void _closeHero() {
    _heroController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: Row(
                  children: [
                    _Sidebar(),
                    Container(
                      width: 1,
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          if (state.canGoBack)
                            Container(
                              height: 48,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
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
              NowPlayingBar(onArtTap: _openHero),
            ],
          ),

          // Now Playing hero overlay
          if (_showHero)
            SlideTransition(
              position: _heroSlide,
              child: NowPlayingScreen(onClose: _closeHero),
            ),
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
      case NavDestination.composers:
        return const ComposersCollectionScreen();
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
            icon: Icons.music_note_rounded,
            label: 'Composers',
            selected: state.currentNav == NavDestination.composers,
            onTap: () => state.navigateTo(NavDestination.composers),
          ),
          _NavItem(
            icon: Icons.playlist_play_rounded,
            label: 'Playlists',
            selected: state.currentNav == NavDestination.playlists &&
                state.selectedPlaylist == null,
            onTap: () => state.navigateTo(NavDestination.playlists),
          ),

          if (state.userPlaylists.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Divider(height: 1),
            ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: state.userPlaylists.length,
                itemBuilder: (context, index) {
                  final playlist = state.userPlaylists[index];
                  final isSelected = state.selectedPlaylist?.uuid == playlist.uuid;
                  return _PlaylistItem(
                    title: playlist.title,
                    selected: isSelected,
                    onTap: () => state.selectPlaylist(playlist),
                  );
                },
              ),
            ),
          ] else
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

class _PlaylistItem extends StatefulWidget {
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const _PlaylistItem({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_PlaylistItem> createState() => _PlaylistItemState();
}

class _PlaylistItemState extends State<_PlaylistItem> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: InkWell(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
          color: widget.selected
              ? Colors.white.withValues(alpha: 0.08)
              : _hovering
                  ? Colors.white.withValues(alpha: 0.04)
                  : null,
          child: Text(
            widget.title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: widget.selected ? FontWeight.w500 : FontWeight.w400,
              color: widget.selected ? Colors.white : Colors.white38,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
