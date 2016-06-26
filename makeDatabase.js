var fs = require('fs');
var PouchDB = require('pouchdb');
var mediatags = require("jsmediatags");

var BASE_PATH = "/home/eliot/Music";

var db = new PouchDB('music_database');
// db.destroy();

function addSong(songPath) {
  mediatags.read(songPath, {
    onSuccess: function(tag) {
      var tags = tag.tags;
      var song = {
        _id: new Date().toISOString(),
        path: songPath,
        name: tags.title,
        artist: tags.artist,
        album: tags.album,
        track: tags.track
      };
      console.log(song);

      db.put(song, function callback(err, result) {
        if (!err) {
          console.log('Successfully added a song');
        }
      });
    },
    onError: function(error) {
      console.log(':(', error.type, error.info);
    }
  });
}

function createDatabase(basePath) {
  var filePaths = readDirectory(basePath, []);
  filePaths.forEach(function(filePath){
    addSong(filePath);
  });
}

createDatabase(BASE_PATH);


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
};
