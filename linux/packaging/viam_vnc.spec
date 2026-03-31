Name:           viam_vnc
Version:        0.1.6
Release:        0%{?dist}
Summary:        VNC viewer for Viam machines
License:        Proprietary
URL:            https://www.viam.com
BuildArch:      x86_64
BuildRequires:  patchelf

%description
Viam VNC is a desktop VNC viewer that connects to machines managed
by the Viam robotics platform.

# ── Build ──────────────────────────────────────────────────────────────────────
# This spec expects the Flutter release bundle to already exist at:
#   ../../build/linux/x64/release/bundle
# Run `make build_linux` before calling rpmbuild.

%install
rm -rf %{buildroot}

BUNDLE_DIR="%{_bundle_dir}"

# Application files
install -d %{buildroot}/opt/viam_vnc
install -d %{buildroot}/opt/viam_vnc/lib
install -d %{buildroot}/opt/viam_vnc/data

cp -r "${BUNDLE_DIR}/data/"   %{buildroot}/opt/viam_vnc/
cp -r "${BUNDLE_DIR}/lib/"    %{buildroot}/opt/viam_vnc/
install -m 0755 "${BUNDLE_DIR}/viam_vnc" %{buildroot}/opt/viam_vnc/viam_vnc

# Symlink into PATH (relative: /usr/local/bin → ../../../opt/viam_vnc/viam_vnc)
install -d %{buildroot}/usr/local/bin
ln -sf ../../../opt/viam_vnc/viam_vnc %{buildroot}/usr/local/bin/viam_vnc

# Icon (hicolor theme)
install -d %{buildroot}/usr/share/icons/hicolor/256x256/apps
install -m 0644 "${BUNDLE_DIR}/data/icons/hicolor/256x256/apps/com.viam.viam_vnc.png" \
    %{buildroot}/usr/share/icons/hicolor/256x256/apps/com.viam.viam_vnc.png

# Desktop entry
install -d %{buildroot}/usr/share/applications
install -m 0644 "${BUNDLE_DIR}/data/com.viam.viam_vnc.desktop" \
    %{buildroot}/usr/share/applications/com.viam.viam_vnc.desktop

# Fix Exec= path in the installed .desktop file
sed -i 's|^Exec=.*|Exec=/opt/viam_vnc/viam_vnc|' \
    %{buildroot}/usr/share/applications/com.viam.viam_vnc.desktop

# Fix build-machine absolute paths in shared library RPATHs.
# Flutter plugin .so files are built with RPATH entries pointing at the
# source tree (e.g. .../linux/flutter/ephemeral). Replace them with
# $ORIGIN so the linker finds libflutter_linux_gtk.so at runtime from
# the same directory.
find %{buildroot}/opt/viam_vnc/lib -name '*.so' | while read so; do
    patchelf --set-rpath '$ORIGIN' "$so"
done

%post
# Register icon with the desktop icon cache
/usr/bin/gtk-update-icon-cache -f -t /usr/share/icons/hicolor &>/dev/null || :
# Update .desktop database
/usr/bin/update-desktop-database /usr/share/applications &>/dev/null || :

%postun
/usr/bin/gtk-update-icon-cache -f -t /usr/share/icons/hicolor &>/dev/null || :
/usr/bin/update-desktop-database /usr/share/applications &>/dev/null || :

%files
/opt/viam_vnc/
/usr/local/bin/viam_vnc
/usr/share/icons/hicolor/256x256/apps/com.viam.viam_vnc.png
/usr/share/applications/com.viam.viam_vnc.desktop

%changelog
* Tue Mar 31 2026 Viam <support@viam.com> - 0.1.6-0
- Fix RPATH entries in plugin .so files with patchelf
- Fix absolute symlink for /usr/local/bin/viam_vnc
* Tue Mar 31 2026 Viam <support@viam.com> - 0.1.5-6
- Initial RPM packaging
