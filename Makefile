PLATFORM := macos
ifeq ($(OS),Windows_NT)
    IS_WINDOWS := $(USERPROFILE)
	PLATFORM := windows
endif

.PHONY: build_macos
build_macos:

.PHONY: build_windows
build_windows:
	$(MAKE) -C tools\hosts_updater build
	robocopy .\tools\hosts_updater .\assets\exe hosts_updater.exe /is /ns /nc /nfl /ndl /np /njh /njs || exit 0

.PHONY: build_os
ifeq ($(IS_WINDOWS),)
build_os: build_macos
else
build_os: build_windows
endif

.PHONY: build
build: build_os
	flutter build $(PLATFORM) --release
