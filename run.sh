#!/bin/bash
# One-command launcher: ./run.sh
cd "$(dirname "$0")"
flutter pub get && flutter run -d chrome
