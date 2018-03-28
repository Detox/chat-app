# Detox chat app
Reference implementation of Chat application on top of Detox network using Detox Chat protocol.

WARNING: INSECURE UNTIL PROVEN THE OPPOSITE!!!

## Alpha testing
Currently application is at alpha quality, but if you feel adventurous and want to take a look, here is how you do it.

Terminal 1:
```bash
git clone https://github.com/Detox/chat.git detox-chat
cd detox-chat
npm install
npm run demo-bootstrap-node
```

Terminal 2:
```bash
git clone https://github.com/Detox/chat-app.git detox-chat-app
cd detox-chat-app
npm install
npm run demo-http-server
```

Open 2 tabs or browser windows at `http://127.0.0.1:8081/` in order to connect from one to another.
Make sure to wait until node is connected to the network and at least one of the nodes was announced to the network, so that you can actually find it.

## Contribution
Feel free to create issues and send pull requests (for big changes create an issue first and link it from the PR), they are highly appreciated!

When reading LiveScript code make sure to configure 1 tab to be 4 spaces (GitHub uses 8 by default), otherwise code might be hard to read.

## License
Free Public License 1.0.0 / Zero Clause BSD License

https://opensource.org/licenses/FPL-1.0.0

https://tldrlegal.com/license/bsd-0-clause-license
