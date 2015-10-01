## Running the example app

Install the example app dependencies and start the server:

```
npm install
npm start
```

Bluetooth doesnt work in the simulator sadly, so get on the same network as your idevice, set the ip address in AppDelegate.m to your machine and finally run on your device. If/when another packager window opens, control c it to stop it so it doesn't affect the webpack packager.

To build for release:

```
npm run bundle
```

Then uncomment the line in AppDelegate.m that loads the local `main.jsbundle`.
