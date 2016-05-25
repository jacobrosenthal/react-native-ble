## Running the example app

The app scans for heartrate devices and prints them to the console, then connects and shows the heartrate on screen.

First install the example app dependencies with `npm install`.

Bluetooth doesnt work in the simulator sadly, and with all the new security on ios on loading non secure content, this example is setup to load via bundle. 

To run your app on iOS `react-native run-ios` or `open BabelES6.xcodeproj` and hit run.