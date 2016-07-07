var Elm = require('./elm');
// var chromecast = require('electron-chromecast');
var app = Elm.Player.fullscreen();
var dbUtils = require('./src/database/dbUtils');

app.ports.destroyDatabase.subscribe(function(){
  dbUtils.destroyDatabase().then(function(){
    updateSongs([]);
  });
});

app.ports.createDatabase.subscribe(function(){
  dbUtils.createDatabase().then(function(){
    dbUtils.groupBy("album").then(function(groups){
      updateGroups(groups);
    });
  });
});

app.ports.textSearch.subscribe(function(value){
  dbUtils.textSearch(value).then(function(groups){
    updateGroups(groups);
  });
});

app.ports.groupBy.subscribe(function(key){
  if (key === 'song') {
    dbUtils.allSongs().then(function(songs){
      updateSongs(songs);
    });
  } else {
    dbUtils.groupBy(key).then(function(groups){
      updateGroups(groups);
    });
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

function updateSongs(dbSongs) {
  if (dbSongs.length > 0) {
    var normalizedSongs = dbSongs.map(normalizeSongs);
    app.ports.updateSongs.send(normalizedSongs);
  } else{
    app.ports.updateSongs.send([]);
  }
}

function normalizeSongs(song) {
  if (!song.title) {song.title = 'unknown';}
  if(song.track) {
    song.track = Number(song.track.split("/")[0]);
  } else {
    song.track = 0;
  }
  song.isDragging = false;
  return song;
}

function updateGroups(groups){
  var normalizedGroups = groups.map(function(group){
    var title = group.doc.title;
    return {title: title, songs: group.doc.songs.map(normalizeSongs)};
  });
  app.ports.updateGroups.send(normalizedGroups);
}


// var castConfig = {
//   sessionRequest: {appId: "elm-audio"},
//   sessionListener: function(session) {
//     console.log("sessionListener");
//   },
//   receiverListener: function(available){
//     console.log(available);
//   }
// };

// chrome.cast.initialize(castConfig, castSuccess, castFailure);
// chrome.cast.requestSession(castSuccess, castFailure);

// // chromecast(function(recievers){

// //   return new Promise(function (resolve, reject) {
// //     // Do some logic to choose a receiver, possibly ask the user through a UI
// //     var chosenReceiver = receivers[0];
// //     resolve(chosenReceiver);
// //   });
// // });

// function castSuccess(){
//   console.log("success");
//   console.log(arguments);
// }

// function castFailure(){
//   console.log("failure");
//   console.log(arguments);
// }
