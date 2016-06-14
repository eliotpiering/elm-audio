var ipc = require('electron').ipcRenderer;
var Elm = require('./elm.js');
var app = Elm.Player.fullscreen();

ipc.on('listDirectory', (event, message) => {
  app.ports.updateDir.send(message);
});

app.ports.newDir.subscribe(function(basePath) {
  console.log("new Dire");
  console.log(basePath.toString());
  if (basePath.length !== 0) {
    ipc.send('list-new-directory', basePath.toString());
  }
});
