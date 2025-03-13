PLATFORM := macos
ifeq ($(OS),Windows_NT)
    IS_WINDOWS := $(USERPROFILE)
	PLATFORM := windows
endif

.PHONY: build_macos
build_macos:
	rm -rf ./releases/*
	xcodebuild clean -workspace ./macos/Runner.xcworkspace -scheme Runner -configuration Release
	xcodebuild archive -workspace ./macos/Runner.xcworkspace -scheme Runner -configuration Release -archivePath ./releases/Runner.xcarchive -destination "generic/platform=macOS"
	xcodebuild -exportArchive -archivePath ./releases/Runner.xcarchive -exportOptionsPlist ./macos/ExportOptions.plist -exportPath ./releases
	ditto -c -k --keepParent ./releases/Viam\ VNC.app ./releases/Viam\ VNC.zip
	xcrun notarytool submit ./releases/Viam\ VNC.zip --keychain-profile "notarytool-password" --wait
	xcrun stapler staple ./releases/Viam\ VNC.app
	spctl --assess --type execute ./releases/Viam\ VNC.app

.PHONY: build_windows
build_windows:
	$(MAKE) -C tools\hosts_updater build
	"C:\Program Files (x86)\Windows Kits\10\bin\10.0.22621.0\x64\signtool.exe" sign /tr http://timestamp.comodoca.com /td sha256 /fd sha256 /d "Viam VNC Hosts Updater" /a .\tools\hosts_updater\hosts_updater.exe
	robocopy .\tools\hosts_updater .\assets\exe hosts_updater.exe /is /ns /nc /nfl /ndl /np /njh /njs || exit 0
	$(MAKE) build_flutter
	"C:\Program Files (x86)\Inno Setup 6\Compil32.exe" /cc .\windows_setup.iss

.PHONY: build_flutter
build_flutter:
	flutter build $(PLATFORM) --release

.PHONY: build
ifeq ($(IS_WINDOWS),)
build: build_macos
else
build: build_windows
endif
	
	
