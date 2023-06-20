#!/bin/sh

set -exu

cd ..
flutter clean
flutter pub get

cd example
flutter clean
flutter pub get
# flutter run
flutter test integration_test
