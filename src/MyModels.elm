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
    , keysBeingTyped : String
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


type alias QueueSongModel =
    { path : String
    , title : String
    , artist : String
    , album : String
    , track : Int
    , picture : String
    , isDragging : Bool
    , isMouseOver : Bool
    }


type alias GroupModel =
    { title : String
    , songs : List SongModel
    }


type alias QueueModel =
    { array : Array IndexedQueueSongModel
    , mouseOver : Bool
    , mouseOverItem : Int
    }


type alias IndexedQueueSongModel =
    { id : Int
    , model : QueueSongModel
    }


type alias IndexedSongModel =
    { id : Int
    , model : SongModel
    }


type alias IndexedGroupModel =
    { id : Int
    , model : GroupModel
    }
