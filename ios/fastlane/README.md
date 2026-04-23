fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios deploy

```sh
[bundle exec] fastlane ios deploy
```

🚀 App Store 배포

### ios beta

```sh
[bundle exec] fastlane ios beta
```

🧪 TestFlight에 업로드

### ios upload_only

```sh
[bundle exec] fastlane ios upload_only
```

📤 이미 빌드된 IPA 업로드만

### ios upload_screenshots

```sh
[bundle exec] fastlane ios upload_screenshots
```

📸 스크린샷 업로드

### ios upload_metadata

```sh
[bundle exec] fastlane ios upload_metadata
```

📝 메타데이터 업로드

### ios submit_review

```sh
[bundle exec] fastlane ios submit_review
```

🚀 심사 제출 (빌드가 이미 업로드된 상태)

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
