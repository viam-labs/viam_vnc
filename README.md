# Viam VNC

A VNC app to connect to Viam machines.


## Releasing

This process should get cleaned up eventually, but priority is super low.

1. Bump version and build number in `pubspec.yaml`
1. Bump version in `windows_setup.iss`
1. Run `flutter run -d <PLATFORM>`, where `<PLATFORM>` is `windows` or `macos` or `linux`, depending on your OS
  1. Click on the `gear` icon and make sure the version matches what you changed it to in step 1
1. Push to main
1. From an appropriately provisioned macOS device, run `make local_release_macos`
  1. Upon completion, zip the `releases/Viam VNC.app` file and name the zip `viamvnc-macos-arm64.zip`
1. Run the Github workflow `build` to run the Windows builder
  1. Upon completion, download the built asset
1. Create a new release named `v<VERSION>`, where `<VERSION>` is the version you set in step 1
1. When the macOS and Windows builds complete, upload the zips to the newly created release and publish
