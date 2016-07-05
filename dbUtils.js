var PouchDB = require('pouchdb');
PouchDB.plugin(require('pouchdb-find'));
var db = new PouchDB('music_database');
var createDatabase = require('./makeDatabase.js');

module.exports = {
  destroyDatabase: function(){
    return db.destroy();
  },
  createDatabase: function(){
    var _this = this;
    return createDatabase().then(function(){
      _this.buildIndexes();
    });
  },
  buildIndexes: function(){
    return db.createIndex({
      index: {fields: ['album', 'artist', 'title']}
    });
  },
  groupBy: function(key) {
    return db.allDocs({include_docs: true}).then(function(results){
      return results.rows.filter(function(result){
        return result.doc && result.doc.songs && result.doc.songs.length > 0;
      });
    });
  },

  sortBy: {
    album: function() {
      return db.createIndex({
        index: {fields: ['album']}
      }).then(function(){
        return db.find({
          selector: {album: {$gt: null}},
          sort: ['album']
        });
      });
    },
    artist: function() {
      return db.createIndex({
        index: {fields: ['artist']}
      }).then(function(){
        return db.find({
          selector: {artist: {$gt: null}},
          sort: ['artist']
        });
      });
    },
    title: function() {
      return db.createIndex({
        index: {fields: ['title']}
      }).then(function(){
        return db.find({
          selector: {title: {$gt: null}},
          sort: ['title']
        });
      });
    }
  },
  findBy: {
    album: function(albumName) {
      return db.find({
        selector: {album: {$eq: albumName}},
        sort: ['track']
      })
    }
  }
};
