#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
VERSION=$(grep '^version:' "$PROJECT_DIR/pubspec.yaml" | sed 's/version: //' | sed 's/+.*//')
BUNDLE_DIR="$PROJECT_DIR/build/linux/x64/release/bundle"
RELEASE_NAME="torrential-${VERSION}-linux-x86_64"
RELEASE_DIR="$PROJECT_DIR/build/release/$RELEASE_NAME"

echo "=== Torrential Release Packager ==="
echo "Version: $VERSION"

# Build release binary
echo "Building release binary..."
cd "$PROJECT_DIR"
flutter build linux --release

# Create release directory structure
echo "Packaging..."
rm -rf "$RELEASE_DIR"
mkdir -p "$RELEASE_DIR"

# Copy the bundle (binary + libs + data)
cp -r "$BUNDLE_DIR"/* "$RELEASE_DIR/"

# Copy icon files
mkdir -p "$RELEASE_DIR/icons"
for size in 16 32 48 64 128 256 512; do
  mkdir -p "$RELEASE_DIR/icons/hicolor/${size}x${size}/apps"
  cp "$PROJECT_DIR/assets/icon/torrential-${size}.png" \
     "$RELEASE_DIR/icons/hicolor/${size}x${size}/apps/com.torrential.torrential.png"
done

# Copy desktop file
cp "$PROJECT_DIR/linux/com.torrential.torrential.desktop" "$RELEASE_DIR/"

# Create install script
cat > "$RELEASE_DIR/install.sh" << 'INSTALL_EOF'
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INSTALL_DIR="${1:-$HOME/.local/opt/torrential}"
BIN_DIR="$HOME/.local/bin"

echo "Installing Torrential to $INSTALL_DIR..."

# Create directories
mkdir -p "$INSTALL_DIR" "$BIN_DIR"

# Copy application files
cp -r "$SCRIPT_DIR/torrential" "$SCRIPT_DIR/data" "$SCRIPT_DIR/lib" "$INSTALL_DIR/"

# Create symlink in PATH
ln -sf "$INSTALL_DIR/torrential" "$BIN_DIR/torrential"

# Install icons
for size_dir in "$SCRIPT_DIR"/icons/hicolor/*/apps; do
  size=$(basename "$(dirname "$size_dir")")
  dest="$HOME/.local/share/icons/hicolor/$size/apps"
  mkdir -p "$dest"
  cp "$size_dir/com.torrential.torrential.png" "$dest/"
done

# Install desktop file with correct Exec path
sed "s|Exec=torrential|Exec=$INSTALL_DIR/torrential|" \
  "$SCRIPT_DIR/com.torrential.torrential.desktop" \
  > "$HOME/.local/share/applications/com.torrential.torrential.desktop"

# Update icon cache if available
if command -v gtk-update-icon-cache &> /dev/null; then
  gtk-update-icon-cache -f -t "$HOME/.local/share/icons/hicolor" 2>/dev/null || true
fi

# Update desktop database if available
if command -v update-desktop-database &> /dev/null; then
  update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
fi

echo ""
echo "Torrential installed successfully!"
echo "  Binary:  $INSTALL_DIR/torrential"
echo "  Symlink: $BIN_DIR/torrential"
echo ""
echo "Note: Requires mpv and GTK3 to be installed on your system."
echo "  Arch/EndeavourOS: sudo pacman -S mpv gtk3"
echo "  Ubuntu/Debian:    sudo apt install mpv libgtk-3-0"
echo "  Fedora:           sudo dnf install mpv gtk3"
INSTALL_EOF
chmod +x "$RELEASE_DIR/install.sh"

# Create uninstall script
cat > "$RELEASE_DIR/uninstall.sh" << 'UNINSTALL_EOF'
#!/usr/bin/env bash
set -euo pipefail

INSTALL_DIR="${1:-$HOME/.local/opt/torrential}"
BIN_DIR="$HOME/.local/bin"

echo "Uninstalling Torrential..."

rm -rf "$INSTALL_DIR"
rm -f "$BIN_DIR/torrential"
rm -f "$HOME/.local/share/applications/com.torrential.torrential.desktop"

for size in 16 32 48 64 128 256 512; do
  rm -f "$HOME/.local/share/icons/hicolor/${size}x${size}/apps/com.torrential.torrential.png"
done

if command -v gtk-update-icon-cache &> /dev/null; then
  gtk-update-icon-cache -f -t "$HOME/.local/share/icons/hicolor" 2>/dev/null || true
fi

echo "Torrential uninstalled."
UNINSTALL_EOF
chmod +x "$RELEASE_DIR/uninstall.sh"

# Create tarball
echo "Creating tarball..."
cd "$PROJECT_DIR/build/release"
tar czf "${RELEASE_NAME}.tar.gz" "$RELEASE_NAME"

echo ""
echo "=== Release package ready ==="
echo "  $PROJECT_DIR/build/release/${RELEASE_NAME}.tar.gz"
echo ""
echo "To create a GitHub release:"
echo "  gh release create v${VERSION} build/release/${RELEASE_NAME}.tar.gz \\"
echo "    --title 'Torrential v${VERSION}' \\"
echo "    --notes 'Release notes here'"
