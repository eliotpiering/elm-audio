module MyModels exposing (..)

import Array exposing (Array)
import Dict exposing (Dict)


type alias Model =
    { currentSong : Int
    , browser : BrowserModel
    , queue : QueueModel
    , albumArt : String
    , currentMousePos : { x : Int, y : Int }
    , dragStart : Maybe MouseLocation
    , keysBeingTyped : String
    , isShiftDown : Bool
    }


type alias SongModel =
    { id : Int
    , path : String
    , title : String
    , artist : String
    , album : String
    , track : Int
    }


type alias GroupModel =
    { id : Int
    , kind : String
    , title : String
    , songs : List SongModel
    }


type alias QueueModel =
    { array : Array ItemModel
    , mouseOver : Bool
    , mouseOverItem : Int
    }


type alias BrowserModel =
    { isMouseOver : Bool
    , items : ItemDictionary
    }


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


type MouseLocation
    = BrowserWindow
    | QueueWindow
    | OtherWindow
