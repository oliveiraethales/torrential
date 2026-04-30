import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../services/app_state.dart';

/// Shows a sleek, dark-themed dialog for creating a new playlist.
///
/// Returns the newly created [Playlist] on success, or `null` if the user
/// dismissed the dialog.
Future<Playlist?> showCreatePlaylistDialog(BuildContext context) async {
  return showGeneralDialog<Playlist?>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Create playlist',
    barrierColor: Colors.black.withValues(alpha: 0.55),
    transitionDuration: const Duration(milliseconds: 180),
    pageBuilder: (_, __, ___) => const SizedBox.shrink(),
    transitionBuilder: (context, anim, _, __) {
      final curved =
          CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
      return Opacity(
        opacity: curved.value,
        child: Transform.scale(
          scale: 0.96 + 0.04 * curved.value,
          child: const _CreatePlaylistDialog(),
        ),
      );
    },
  );
}

class _CreatePlaylistDialog extends StatefulWidget {
  const _CreatePlaylistDialog();

  @override
  State<_CreatePlaylistDialog> createState() => _CreatePlaylistDialogState();
}

class _CreatePlaylistDialogState extends State<_CreatePlaylistDialog> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _titleFocus = FocusNode();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _titleFocus.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      !_busy && _titleCtrl.text.trim().isNotEmpty;

  Future<void> _submit() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final state = context.read<AppState>();
      final playlist = await state.createPlaylist(
        title,
        description: _descCtrl.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pop(playlist);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Could not create playlist: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1A1A1A),
      elevation: 12,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.playlist_add_rounded,
                        size: 20, color: Colors.white70),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'New playlist',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  IconButton(
                    iconSize: 18,
                    splashRadius: 18,
                    onPressed: _busy ? null : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, color: Colors.white54),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              CallbackShortcuts(
                bindings: {
                  const SingleActivator(LogicalKeyboardKey.enter): _submit,
                  const SingleActivator(LogicalKeyboardKey.numpadEnter): _submit,
                },
                child: Focus(
                  autofocus: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _titleCtrl,
                        focusNode: _titleFocus,
                        autofocus: true,
                        textInputAction: TextInputAction.next,
                        enabled: !_busy,
                        onChanged: (_) => setState(() {}),
                        onSubmitted: (_) => _submit(),
                        maxLength: 80,
                        style: Theme.of(context).textTheme.titleMedium,
                        decoration: _decoration(
                          label: 'Title',
                          hint: 'My favourite tracks',
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _descCtrl,
                        enabled: !_busy,
                        maxLines: 3,
                        minLines: 2,
                        maxLength: 160,
                        style: Theme.of(context).textTheme.bodyMedium,
                        decoration: _decoration(
                          label: 'Description (optional)',
                          hint: 'What is this playlist about?',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 4),
                Text(
                  _error!,
                  style: TextStyle(
                    color: Colors.red.shade300,
                    fontSize: 12,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed:
                        _busy ? null : () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white70,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: _canSubmit ? _submit : null,
                    icon: _busy
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          )
                        : const Icon(Icons.check_rounded, size: 18),
                    label: Text(_busy ? 'Creating…' : 'Create'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      disabledBackgroundColor:
                          Colors.white.withValues(alpha: 0.12),
                      disabledForegroundColor: Colors.white38,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _decoration({required String label, required String hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      counterText: '',
      isDense: true,
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.04),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
      ),
    );
  }
}
