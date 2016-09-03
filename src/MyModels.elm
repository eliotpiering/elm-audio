module MyModels exposing (..)

import Array exposing (Array)
import Dict exposing (Dict)


type alias Model =
    { currentSong : Int
    , browser : BrowserModel
    -- , items : ItemDictionary
    -- , groups : ItemDictionary
    , queue : QueueModel
    , rootPath : String
    , currentMousePos : { x : Int, y : Int }
    , isDragging : Bool
    , keysBeingTyped : String
    , isShiftDown : Bool
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


-- type alias QueueSongModel =
--     { path : String
--     , title : String
--     , artist : String
--     , album : String
--     , track : Int
--     , picture : String
--     , isDragging : Bool
--     , isMouseOver : Bool
--     }


type alias GroupModel =
    { title : String
    , songs : List SongModel
    , isSelected : Bool
    , isDragging : Bool
    }


type alias QueueModel =
    { array : Array ItemModel
    , mouseOver : Bool
    , mouseOverItem : Int
    }

type alias BrowserModel =
    { items : ItemDictionary }


-- type alias IndexedQueueSongModel =
--     { id : Int
--     , model : QueueSongModel
--     }


-- type alias IndexedSongModel =
--     { id : Int
--     , model : SongModel
--     }


type alias ItemDictionary =
    Dict String ItemModel


type alias ItemModel =
    { isSelected : Bool
    , isMouseOver : Bool
    , data : ItemData
    }


type ItemData
    = Song SongModel
    | Group GroupModel
