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
	
	
