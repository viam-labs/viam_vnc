PLATFORM := macos
ifeq ($(OS),Windows_NT)
    IS_WINDOWS := $(USERPROFILE)
	PLATFORM := windows
endif

VERSION     := 0.1.6
RELEASE     := 0
BUNDLE_DIR  := build/linux/x64/release/bundle
PKG_STAGE   := build/linux/packaging
RPM_ROOT    := $(PKG_STAGE)/rpm
DEB_STAGE   := $(PKG_STAGE)/deb

.PHONY: build_macos
build_macos:
	$(MAKE) build_flutter

.PHONY: build_windows
build_windows:
	$(MAKE) -C tools\hosts_updater build
	robocopy .\tools\hosts_updater .\assets\exe hosts_updater.exe /is /ns /nc /nfl /ndl /np /njh /njs || exit 0
	$(MAKE) build_flutter

.PHONY: build_flutter
build_flutter:
	flutter build $(PLATFORM) --release

.PHONY: build
ifeq ($(IS_WINDOWS),)
build: build_macos
else
build: build_windows
endif
	
.PHONY: local_release_macos
local_release_macos:
	@echo "This target must be run from a local macOS machine with the appropriate programs and crendentials"
	$(MAKE) build_macos
	rm -rf ./releases/*
	xcodebuild clean -workspace ./macos/Runner.xcworkspace -scheme Runner -configuration Release
	xcodebuild archive -workspace ./macos/Runner.xcworkspace -scheme Runner -configuration Release -archivePath ./releases/Runner.xcarchive -destination "generic/platform=macOS"
	xcodebuild -exportArchive -archivePath ./releases/Runner.xcarchive -exportOptionsPlist ./macos/ExportOptions.plist -exportPath ./releases
	ditto -c -k --keepParent ./releases/Viam\ VNC.app ./releases/Viam\ VNC.zip
	xcrun notarytool submit ./releases/Viam\ VNC.zip --keychain-profile "notarytool-password" --wait
	xcrun stapler staple ./releases/Viam\ VNC.app
	spctl --assess --type execute ./releases/Viam\ VNC.app

.PHONY: local_release_windows
local_release_windows:
	@echo "This target must be run from a local Windows machine with the appropriate programs and crendentials"
	del /S /q ".\releases\*"
	$(MAKE) -C tools\hosts_updater build
	gcloud secrets versions access projects/385154741571/secrets/ev-code-signing-public-key/versions/3 --out-file=cert.pem
	$$token = gcloud auth print-access-token; java -jar .\tools\jsign-7.1.jar --name "Viam VNC Hosts Updater" --storetype GOOGLECLOUD --keystore projects/engineering-tools-310515/locations/global/keyRings/release_signing_key --storepass "$$token" --alias ev-code-signing-key/cryptoKeyVersions/2 --certfile cert.pem .\tools\hosts_updater\hosts_updater.exe
	robocopy .\tools\hosts_updater .\assets\exe hosts_updater.exe /is /ns /nc /nfl /ndl /np /njh /njs || exit 0
	$(MAKE) build_flutter
	"C:\Program Files (x86)\Inno Setup 6\Compil32.exe" /cc .\windows_setup.iss
	java -jar .\tools\jsign-7.1.jar --storetype GOOGLECLOUD --keystore projects/engineering-tools-310515/locations/global/keyRings/release_signing_key --storepass "$(gcloud auth print-access-token)" --alias ev-code-signing-key/cryptoKeyVersions/2 --certfile cert.pem .\tools\hosts_updater\hosts_updater.exe

# ── Linux ──────────────────────────────────────────────────────────────────────

.PHONY: build_linux
build_linux:
	flutter build linux --release

# Stage the Flutter bundle into a filesystem tree ready for packaging.
# Both package_deb and package_rpm depend on this target.
.PHONY: _linux_stage
_linux_stage: build_linux
	# ── /opt/viam_vnc (application files) ──
	mkdir -p $(DEB_STAGE)/opt/viam_vnc/data \
	         $(DEB_STAGE)/opt/viam_vnc/lib
	cp -r $(BUNDLE_DIR)/data/ $(DEB_STAGE)/opt/viam_vnc/
	cp -r $(BUNDLE_DIR)/lib/  $(DEB_STAGE)/opt/viam_vnc/
	install -m 0755 $(BUNDLE_DIR)/viam_vnc $(DEB_STAGE)/opt/viam_vnc/viam_vnc
	# ── /usr/local/bin symlink ──
	mkdir -p $(DEB_STAGE)/usr/local/bin
	ln -sf /opt/viam_vnc/viam_vnc $(DEB_STAGE)/usr/local/bin/viam_vnc
	# ── hicolor icon ──
	mkdir -p $(DEB_STAGE)/usr/share/icons/hicolor/256x256/apps
	install -m 0644 \
	    $(BUNDLE_DIR)/data/icons/hicolor/256x256/apps/com.viam.viam_vnc.png \
	    $(DEB_STAGE)/usr/share/icons/hicolor/256x256/apps/com.viam.viam_vnc.png
	# ── .desktop entry (Exec= set to absolute path) ──
	mkdir -p $(DEB_STAGE)/usr/share/applications
	sed 's|^Exec=.*|Exec=/opt/viam_vnc/viam_vnc|' \
	    $(BUNDLE_DIR)/data/com.viam.viam_vnc.desktop \
	    > $(DEB_STAGE)/usr/share/applications/com.viam.viam_vnc.desktop

.PHONY: package_deb
package_deb: _linux_stage
	# Copy DEBIAN control directory into the stage tree
	cp -r linux/packaging/debian/DEBIAN $(DEB_STAGE)/DEBIAN
	# Fix permissions required by dpkg-deb
	chmod 0755 $(DEB_STAGE)/DEBIAN/postinst $(DEB_STAGE)/DEBIAN/postrm
	mkdir -p releases
	dpkg-deb --root-owner-group --build $(DEB_STAGE) \
	    releases/viam-vnc_$(VERSION)-$(RELEASE)_amd64.deb
	@echo "Created: releases/viam-vnc_$(VERSION)-$(RELEASE)_amd64.deb"

.PHONY: package_rpm
package_rpm: _linux_stage
	# Set up rpmbuild tree pointing at our staged DEB tree as the sysroot
	mkdir -p $(RPM_ROOT)/{BUILD,RPMS,SOURCES,SPECS,SRPMS}
	cp linux/packaging/viam_vnc.spec $(RPM_ROOT)/SPECS/viam_vnc.spec
	# Override _topdir so the spec can find the bundle via relative path
	rpmbuild -bb \
	    --define "_topdir $(CURDIR)/$(RPM_ROOT)" \
	    --define "_bundle_dir $(CURDIR)/$(BUNDLE_DIR)" \
	    $(RPM_ROOT)/SPECS/viam_vnc.spec
	mkdir -p releases
	find $(RPM_ROOT)/RPMS -name "*.rpm" -exec cp {} releases/ \;
	@echo "Created RPM in releases/"

.PHONY: release_linux
release_linux: package_deb package_rpm
