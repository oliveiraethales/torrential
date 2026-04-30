#!/usr/bin/env bash
set -euo pipefail

VERSION=$(grep '^version:' "$(dirname "$0")/../pubspec.yaml" | sed 's/version: //' | sed 's/+.*//')
TARBALL_URL="https://github.com/oliveiraethales/torrential/releases/download/v${VERSION}/torrential-${VERSION}-linux-x86_64.tar.gz"

echo "=== AUR Package Updater ==="
echo "Version: $VERSION"
echo "Source:  $TARBALL_URL"

WORKDIR=$(mktemp -d)
trap "rm -rf $WORKDIR" EXIT

cd "$WORKDIR"
git clone ssh://aur@aur.archlinux.org/torrential.git .
git checkout master

# Download tarball and compute checksum
echo "Downloading tarball to compute sha256sum..."
curl -sL "$TARBALL_URL" -o "torrential-${VERSION}.tar.gz"
SHA256=$(sha256sum "torrential-${VERSION}.tar.gz" | cut -d' ' -f1)
echo "SHA256: $SHA256"

cat > PKGBUILD << EOF
# Maintainer: Tháles de Oliveira <oliveiraethales@gmail.com>
pkgname=torrential
pkgver=${VERSION}
pkgrel=1
pkgdesc='A sleek Linux TIDAL client with Hi-Res FLAC support (24-bit/192kHz)'
arch=('x86_64')
url='https://github.com/oliveiraethales/torrential'
license=('MIT')
depends=('gtk3' 'mpv')
source=("\${pkgname}-\${pkgver}.tar.gz::https://github.com/oliveiraethales/torrential/releases/download/v\${pkgver}/torrential-\${pkgver}-linux-x86_64.tar.gz")
sha256sums=('${SHA256}')

package() {
  cd "\${pkgname}-\${pkgver}-linux-x86_64"

  # Install application binary and data
  install -d "\${pkgdir}/opt/\${pkgname}"
  cp -r torrential data lib "\${pkgdir}/opt/\${pkgname}/"

  # Create /usr/bin symlink
  install -d "\${pkgdir}/usr/bin"
  ln -s "/opt/\${pkgname}/torrential" "\${pkgdir}/usr/bin/torrential"

  # Install desktop file
  install -Dm644 com.torrential.torrential.desktop \\
    "\${pkgdir}/usr/share/applications/com.torrential.torrential.desktop"

  # Fix Exec path in desktop file
  sed -i 's|Exec=torrential|Exec=/opt/torrential/torrential|' \\
    "\${pkgdir}/usr/share/applications/com.torrential.torrential.desktop"

  # Install icons
  for size in 16 32 48 64 128 256 512; do
    install -Dm644 "icons/hicolor/\${size}x\${size}/apps/com.torrential.torrential.png" \\
      "\${pkgdir}/usr/share/icons/hicolor/\${size}x\${size}/apps/com.torrential.torrential.png"
  done
}
EOF

makepkg --printsrcinfo > .SRCINFO

git add PKGBUILD .SRCINFO
git commit -m "Update to ${VERSION}"
git push

echo ""
echo "=== AUR package updated to ${VERSION} ==="
