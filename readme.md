# Detox chat app
Reference implementation of Chat application on top of Detox network using Detox Chat protocol.

WARNING: INSECURE UNTIL PROVEN THE OPPOSITE!!!

## Browser support
First of all, only 2 latest stable versions of any browser are supported! Don't ever ask to support older ones.

| Browser  | Support level                                         |
|----------|-------------------------------------------------------|
| Chromium | Flaky, bugs reported, should be better soon           |
| Firefox  | Fully supported                                       |
| Safari   | WebRTC support is not good enough yet, hopefully soon |
| Edge     | RTCDataChannel not supported at all, hopefully soon   |

## Alpha testing
Currently application is at alpha quality and only recommended for developers, not really suitable for early adopters yet.

Builds directly from master branch are available at [detox.github.io/chat-app](https://detox.github.io/chat-app/), they may be broken from time to time though.

WARNING: Alpha version can eat all of your CPU, RAM, network bandwidth, battery on mobile device or all at the same time. It may event eat pizza from your fridge. Don't blame me if it does.

If you want to run debugging build from sources, do:
```bash
git clone https://github.com/Detox/chat-app.git detox-chat-app
cd detox-chat-app
npm install
npm run demo-http-server
```

And open browser window at `http://127.0.0.1:8081/index-debug.html`.
Make sure to wait until node is connected to the network and announced to the network, so that someone can find you.

## Contribution
Feel free to create issues and send pull requests (for big changes create an issue first and link it from the PR), they are highly appreciated!

When reading LiveScript code make sure to configure 1 tab to be 4 spaces (GitHub uses 8 by default), otherwise code might be hard to read.

## License
Free Public License 1.0.0 / Zero Clause BSD License

https://opensource.org/licenses/FPL-1.0.0

https://tldrlegal.com/license/bsd-0-clause-license
