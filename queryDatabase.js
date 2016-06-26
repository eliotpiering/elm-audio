var PouchDB = require('pouchdb');
PouchDB.plugin(require('pouchdb-find'));
var db = new PouchDB('music_database');

module.exports = {
  byAlbum: function() {
    return db.createIndex({
      index: {fields: ['album']}
    }).then(function () {
      return db.find({
        selector: {album: {$gt: null}},
        sort: ['album']
      });
    });
  }
};
