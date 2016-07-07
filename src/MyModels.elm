module MyModels exposing (..)

import Array exposing (Array)


type alias Model =
    { currentSong : Int
    , songs : List IndexedSongModel
    , groups : List IndexedGroupModel
    , queue : QueueModel
    , rootPath : String
    , currentMousePos : { x : Int, y : Int }
    , isDragging : Bool
    }


type alias SongModel =
    { path : String
    , title : String
    , artist : String
    , album : String
    , track : Int
    , picture : String
    , isDragging : Bool
    }


type alias GroupModel =
    { title : String
    , songs : List SongModel
    }


type alias QueueModel =
    { array : Array IndexedSongModel
    , mouseOver : Bool
    }


type alias IndexedSongModel =
    { id : Int
    , model : SongModel
    }


type alias IndexedGroupModel =
    { id : Int
    , model : GroupModel
    }
