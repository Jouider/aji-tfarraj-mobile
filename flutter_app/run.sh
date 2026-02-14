#!/bin/bash
# Load environment variables from .env file and run Flutter

if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
fi

flutter run \
  --dart-define=FIREBASE_ANDROID_API_KEY=$FIREBASE_ANDROID_API_KEY \
  --dart-define=FIREBASE_IOS_API_KEY=$FIREBASE_IOS_API_KEY \
  "$@"
