PLATFORM := macos
ifeq ($(OS),Windows_NT)
    IS_WINDOWS := $(USERPROFILE)
	PLATFORM := windows
endif

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
	$$token = gcloud auth print-access-token; java -jar .\tools\jsign-7.1.jar --name "Viam VNC Hosts Updater" --storetype GOOGLECLOUD --keystore projects/engineering-tools-310515/locations/global/keyRings/release_signing_key --storepass "$$token" --alias ev-code-signing-key/cryptoKeyVersions/1 --certfile cert.pem .\tools\hosts_updater\hosts_updater.exe
	robocopy .\tools\hosts_updater .\assets\exe hosts_updater.exe /is /ns /nc /nfl /ndl /np /njh /njs || exit 0
	$(MAKE) build_flutter
	"C:\Program Files (x86)\Inno Setup 6\Compil32.exe" /cc .\windows_setup.iss
	java -jar .\tools\jsign-7.1.jar --storetype GOOGLECLOUD --keystore projects/engineering-tools-310515/locations/global/keyRings/release_signing_key --storepass "$(gcloud auth print-access-token)" --alias ev-code-signing-key/cryptoKeyVersions/1 --certfile cert.pem .\tools\hosts_updater\hosts_updater.exe
