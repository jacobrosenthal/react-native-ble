#!/bin/bash
rsync -a --delete --progress ../../ ./node_modules/react-native-ble \
 --exclude examples \
 --exclude '.*' \
 --exclude android/build \
 --exclude android/react-native-ble.iml \
 --exclude README.md

rm -rf node_modules/react-native-ble/node_modules/react
rm -rf node_modules/react-native-ble/node_modules/react-native

cd node_modules/react-native-ble/node_modules
ln -sv ./../../react
ln -sv ./../../react-native
