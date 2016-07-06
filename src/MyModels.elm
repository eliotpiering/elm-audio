module MyModels exposing (..)

import Array exposing (Array)


type alias Model =
    { currentSong : Int
    , songs : List IndexedSongModel
    , groups : List IndexedGroupModel
    , queue : Array IndexedSongModel
    , rootPath : String
    , dropZone : Int
    , currentDrag : { x : Int, y : Int }
    }


type alias SongModel =
    { path : String
    , title : String
    , artist : String
    , album : String
    , track : Int
    , isDragging : Bool
    }


type alias GroupModel =
    { title : String
    , songs : List SongModel
    }

type alias IndexedSongModel =
    { id : Int
    , model : SongModel
    }
type alias IndexedGroupModel =
    { id : Int
    , model : GroupModel
    }
