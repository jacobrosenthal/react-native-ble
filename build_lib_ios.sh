#!/bin/bash

cd ./ios
xcodebuild -scheme RNBLE build

cd ./BLEManager
xcodebuild -scheme BLEManager build
