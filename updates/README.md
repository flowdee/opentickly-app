# macOS updates

OpenTickly uses Sparkle 2. The Mac app reads the signed feed in this directory from the public `main` branch. Update archives live in GitHub Releases. Anyone can check for updates without a GitHub account. An empty channel means there are no published builds to install.

## Prepare a release

1. Increase the build number in `pubspec.yaml` for every distributed build. Sparkle compares `CFBundleVersion` (the number after `+`). Keep the app’s bundle identifier stable.
2. Build an Xcode archive and export it for Developer ID distribution with hardened runtime enabled. Sign with the publisher’s **Developer ID Application** identity, notarize the app and staple the ticket. Check the downloaded package on a second Mac. Xcode’s archive/export process also signs Sparkle’s nested helpers. [Apple distribution guide](https://developer.apple.com/developer-id/) · [Sparkle sandbox signing](https://sparkle-project.org/documentation/sandboxing/#code-signing)
3. Package the exported app for the release. The following example assumes an exported, stapled app at `export/OpenTickly.app`. Run it from the repository root, with matching Sparkle tools (`generate_appcast` and `sign_update`) on your PATH.

```sh
tag=v0.1.1
artifacts=$(mktemp -d)
ditto -c -k --sequesterRsrc --keepParent export/OpenTickly.app "$artifacts/OpenTickly-${tag}-macOS.zip"

generate_appcast --account dev.fdmedia.openticklyApp.updates \
  --download-url-prefix "https://github.com/flowdee/opentickly-app/releases/download/$tag/" \
  --maximum-deltas 0 "$artifacts"
sign_update --account dev.fdmedia.openticklyApp.updates --verify "$artifacts/appcast.xml"
```

4. Inspect the generated version, download URL and minimum macOS version. Publish the matching ZIP in the GitHub release for that tag, then confirm it downloads without authentication.
5. Copy the generated `appcast.xml` into `updates/` unchanged and commit it to `main`. This makes the new version discoverable to installed clients. The example produces a feed with the latest build only. To support older macOS versions after raising the deployment target, retain a compatible signed release in the feed.

The Sparkle private key lives in the release maintainer’s macOS Keychain under the account `dev.fdmedia.openticklyApp.updates`. Back it up securely before the first public release. The app embeds the matching public key and verifies both the feed and the downloaded archive. Editing a signed feed requires signing it again. [Sparkle publishing guide](https://sparkle-project.org/documentation/publishing/)
