var PouchDB = require('pouchdb');
PouchDB.plugin(require('pouchdb-find'));
var db = new PouchDB('music_database');
var createDatabase = require('./makeDatabase.js');

module.exports = {
  destroyDatabase: function(){
    return db.destroy().then(function(){
      return true;
    }).catch(function(err){
      console.log(err);
    });
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
      return results.rows.filter(function(row){
        var doc = row.doc;
        return doc.songs && doc.songs.length > 0 && doc.type == key;
      });
    });
  },

  sortBy: function(key) {
    return db.createIndex({
      index: {fields: [key]}
    }).then(function(){
      var sel = {};
      sel[key] = {$gt: null};
      return db.find({
        selector: sel,
        sort: [key]
      });
    });
  },

  findBy: {
    album: function(albumName) {
      return db.find({
        selector: {album: {$eq: albumName}},
        sort: ['track']
      });
    }
  }
};
