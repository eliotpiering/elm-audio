var app = Elm.Player.fullscreen();

/* Text search helpers */
app.ports.textSearch.subscribe(function(value){
    dbUtils.textSearch(value).then(function(groups){
        updateGroups(groups);
    });
});
var lastTimeoutId;
app.ports.scrollToElement.subscribe(function(value){
    if (lastTimeoutId) {
        window.clearTimeout(lastTimeoutId);
    }
    var element = document.getElementById(value);

    if (element) {
        element.scrollIntoView();
    }

    lastTimeoutId = window.setTimeout(function(){
        app.ports.resetKeysBeingTyped.send("nothing");
    }, 1000);
});



/* Pause */
app.ports.pause.subscribe(function(){
    var player = document.getElementsByTagName("audio")[0];
    if (!player)  {return;}
    if (player.paused) {
        player.play();
    } else {
        player.pause();
    }
});

/* Album Art */
app.ports.lookupAlbumArt.subscribe(function(albumName){
    dbUtils.findById(albumName + "-album").then(function(doc){
        app.ports.updateAlbumArt.send(doc.picture);
    });
});
