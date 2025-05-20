const tmi = require('tmi.js');
const WebSocket = require('ws');
const express = require('express');

const twitchUsername = 'AMNTDEVIIL';
const twitchOAuth = 'oauth:oojrc1s80i27gzgx0qtlnpo4l3iphd'; 
const channelName = 'amntdeviil';

// Set up Twitch client
const client = new tmi.Client({
  identity: {
    username: twitchUsername,
    password: twitchOAuth,
  },
  channels: [channelName]
});

// Connect Twitch client and print confirmation
client.connect().then(() => {
  console.log('Twitch bot is running and connected!');
}).catch(console.error);

// Set up WebSocket server for Flutter app connection
const wss = new WebSocket.Server({ port: 8080 });

let flutterSocket = null;

wss.on('connection', (ws) => {
  flutterSocket = ws;
  console.log('Flutter app connected via WebSocket');
  ws.on('close', () => {
    flutterSocket = null;
    console.log('Flutter app disconnected');
  });
});

// Listen to chat messages
client.on('message', (channel, tags, message, self) => {
  if (self) return; // Ignore messages from the bot itself

  if (message.startsWith('!attack')) {
    const parts = message.split(' ');
    if (parts.length === 2) {
      const attackType = parts[1].toUpperCase(); // P, F, I, W
      if (['P', 'F', 'I', 'W'].includes(attackType)) {
        console.log(`Received attack command: ${attackType}`);

        // Send to Flutter app via WebSocket
        if (flutterSocket && flutterSocket.readyState === WebSocket.OPEN) {
          flutterSocket.send(attackType);
        }
      }
    }
  }
});
