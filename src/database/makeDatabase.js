var fs = require('fs');
var PouchDB = require('pouchdb');
var mediatags = require("jsmediatags");
var BASE_PATH = "/home/eliot/Music";
PouchDB.plugin(require('pouchdb-quick-search'));
PouchDB.plugin(require('pouchdb-find'));
var db = new PouchDB('music_database');


window.onerror = function(message, file, lineNumber) {
  // need to do this to catch errors in the metatags.read
  // hopefully this doesn't catch everything else :(

  console.log("global onerror" + message + file + lineNumber);
  return true;
};

 
function lookupSong(path) {
  return new Promise(function(resolve, reject) {
    console.log(path);
    var didCallback = false;
    mediatags.read(path, {
      onSuccess: function(tag) {
        didCallback = true;
        var tags = tag.tags;
        var artist = tag.tags.TPE2 ? tag.tags.TPE2.data : tags.artist ? tags.artist : "unknown artist";
        var album = tags.album ? tags.album : "unknown album";
        var title = tags.title ? tags.title : "unknown title";
        var picture = 'no picture'; // tags.picture ? tags.picture : "no picture";
        var track = tags.track ? tags.track.toString() : "0";
        resolve({
          _id: new Date().toISOString(),
          path: path,
          title: title,
          artist: artist,
          album: album,
          track: track,
          picture: picture
        });
      },

      onError: function(error) {
        didCallback = true;
        console.log(':(', error.type, error.info);
        reject("error");
      }
    });
    setTimeout(function(){
      console.log("hit set timeout" + didCallback);
      if (!didCallback) {
        reject("error");
      }

    }, 10000)

  });
}

function addSong(song) {
  if (song.picture && song.picture.data) {
    song.picture = convertPictureToBase64String(song.picture.data, song.picture.format);
  } else {
    song.picture = "no picture :(";
  }
  return addArtistDocument(song).then(function(){
    return addAlbumDocument(song);
  }).catch(function(){
    return addAlbumDocument(song);
  });
}

function convertPictureToBase64String(buffer, imageFormat) {
  var binary = '';
  var bytes = new Uint8Array( buffer );
  var len = bytes.byteLength;
  for (var i = 0; i < len; i++) {
    binary += String.fromCharCode( bytes[ i ] );
  }
  var base64String = window.btoa( binary );
  return "data:" + imageFormat + ";base64, " + base64String;
}

function addAlbumDocument (song) {
  var albumId = (song.album + "-album");
  var album = {
    _id: albumId,
    title: (song.album + " - " + song.artist),
    artist: song.artist,
    type: "album",
    songs: [song]
  };
  return db.get(albumId).then(function(albumDocument){
    //Updating
    album._rev = albumDocument._rev;
    album.songs = album.songs.concat(albumDocument.songs);
    db.put(album).then(successUpdate, failureUpdate);
  }).catch(function(err){
    if (err.name == 'not_found') {
      //Creating
      db.put(album).then(successUpdate, failureUpdate);
    } else {
      console.log("I don't really know what happened");
    }
  });
}
function addArtistDocument (song) {
  var artistId = (song.artist + "-artist");
  var artist = {
    _id: artistId,
    title: song.artist,
    songs: [song],
    type: "artist"
  };
  return db.get(artistId).then(function(artistDocument){
    //Updating
    artist._rev = artistDocument._rev;
    artist.songs = artist.songs.concat(artistDocument.songs);
    db.put(artist).then(successUpdate, failureUpdate);
  }).catch(function(err){
    if (err.name == 'not_found') {
      //Creating
      db.put(artist).then(successUpdate, failureUpdate);
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

module.exports = function() {

  var filePaths = readDirectory(BASE_PATH, []);
  var firstFile = filePaths.pop();
  return addSongsInSequence(firstFile, filePaths);
};
