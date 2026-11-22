DEVICE := 3f99d6b8
ADB := $(LOCALAPPDATA)/Android/Sdk/platform-tools/adb.exe
ENV := env.json
TEST_ENV := env.test.json

.PHONY: run build build-split test itest reverse clean deps

run:
	flutter run -d $(DEVICE) --dart-define-from-file=$(ENV)

build:
	flutter build apk --dart-define-from-file=$(ENV)

build-split:
	flutter build apk --split-per-abi --dart-define-from-file=$(ENV)

test:
	flutter test

itest:
	flutter test integration_test -d $(DEVICE) --dart-define-from-file=$(TEST_ENV)

reverse:
	"$(ADB)" reverse tcp:5151 tcp:5151

deps:
	flutter pub get

clean:
	flutter clean
	flutter pub get
