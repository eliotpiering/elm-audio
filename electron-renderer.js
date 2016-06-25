var ipc = require('electron').ipcRenderer;
var Elm = require('./elm.js');
var chromecast = require('electron-chromecast');
var app = Elm.Player.fullscreen();

ipc.on('listDirectory', (event, message) => {
  app.ports.updateDir.send(message);
});

app.ports.newDir.subscribe(function(basePath) {
  if (basePath.length !== 0) {
    ipc.send('list-new-directory', basePath.toString());
  }
});

app.ports.pause.subscribe(function(){
  var player = document.getElementsByTagName("audio")[0];
  if (!player)  {return;}
  if (player.paused) {
    player.play();
  } else {
    player.pause();
  }
});


var castConfig = {
  sessionRequest: {appId: "elm-audio"},
  sessionListener: function(session) {
    console.log("sessionListener");
  },
  receiverListener: function(available){
    console.log(available);
  }
};

chrome.cast.initialize(castConfig, castSuccess, castFailure);
chrome.cast.requestSession(castSuccess, castFailure);

// chromecast(function(recievers){

//   return new Promise(function (resolve, reject) {
//     // Do some logic to choose a receiver, possibly ask the user through a UI
//     var chosenReceiver = receivers[0];
//     resolve(chosenReceiver);
//   });
// });

function castSuccess(){
  console.log("success");
  console.log(arguments);
}

function castFailure(){
  console.log("failure");
  console.log(arguments);
}


