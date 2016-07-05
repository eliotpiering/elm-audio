var fs = require('fs');
var PouchDB = require('pouchdb');
var mediatags = require("jsmediatags");
var BASE_PATH = "/home/eliot/Music";
PouchDB.plugin(require('pouchdb-quick-search'));
PouchDB.plugin(require('pouchdb-find'));

var db = new PouchDB('music_database');

function lookupSong(path) {
  return new Promise(function(resolve, reject) {
    mediatags.read(path, {
      onSuccess: function(tag) {
        var tags = tag.tags;

        resolve({
          _id: new Date().toISOString(),
          path: path,
          title: tags.title,
          artist: tags.artist,
          album: tags.album,
          track: tags.track
        });
      },

      onError: function(error) {
        console.log(':(', error.type, error.info);
        reject("error");
      }
    });
  });
}

function addSong(song) {
  var album = {
    _id: song.album,
    artist: song.artist,
    songs: [song]
  };

  db.get(song.album).then(function(albumDocument){
    albumDocument.songs.concat(song);
    db.put(albumDocument).then(successUpdate, failureUpdate);
  }, function(err){
    if (err.name == 'not_found') {
      db.put(album).then(successUpdate, failureUpdate);
    } else {
      console.log("I don't really know what happened");
    }
  });
}

function successUpdate() {
  console.log('Successfully added a song');
}
function failureUpdate () {
  console.log("something went wrong");
}

function readDirectory(dir, filelist) {
  var files = fs.readdirSync(dir);
  files.forEach(function(file) {
    if (fs.statSync(dir + '/' + file).isDirectory()) {
      filelist = readDirectory(dir + '/' + file, filelist);
    }
    else {
      filelist.push(dir + '/' + file);
    }
  });
  return filelist;
}

module.exports = function() {
  var filePaths = readDirectory(BASE_PATH, []);
  filePaths.forEach(function(filePath){
    lookupSong(filePath).then(function(song){
      addSong(song);
    }).catch(function(){
      console.log("catch in lookupSong error");
    });
  });
  return new Promise(function(resolve, reject){
    resolve();
  });
};
