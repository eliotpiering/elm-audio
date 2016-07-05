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

  // db.get('mydoc').then(function(doc) {
  //   return db.put({
  //     _id: 'mydoc',
  //     _rev: doc._rev,
  //     title: "Let's Dance"
  //   });

  return db.get(song.album)
    .then(function(albumDocument){
      db.put({
        _id: albumDocument._id,
        _rev: albumDocument._rev,
        artist: albumDocument.artist,
        songs: albumDocument.songs.concat(song)
      }).then(successUpdate, failureUpdate);
    }).catch(function(err){
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
  var firstFile = filePaths.pop();
  return addSongsInSequence(firstFile, filePaths);
};

function addSongsInSequence(filePath, remainingFilePaths){
  return lookupSong(filePath).then(function(song){
    return addSong(song).then(function(){
      if(remainingFilePaths.length > 0) {
        var nextFilePath = remainingFilePaths.pop();
        return addSongsInSequence(nextFilePath, remainingFilePaths);
      } else {
        return true;
      }
    }).catch(function(){
      console.log("catch in addSong error");
      var nextFilePath = remainingFilePaths.pop();
      return addSongsInSequence(nextFilePath, remainingFilePaths);

    });
  }).catch(function(){
    console.log("catch in lookupSong error");
    var nextFilePath = remainingFilePaths.pop();
    return addSongsInSequence(nextFilePath, remainingFilePaths);
  });
}
