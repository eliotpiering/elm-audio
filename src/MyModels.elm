module MyModels exposing (..)

import Array exposing (Array)


type alias Model =
    { currentSong : Int
    , songs : List IndexedFileObject
    , groups : List IndexedGroupModel
    , queue : Array IndexedFileObject
    , rootPath : String
    , dropZone : Int
    }


type alias FileObjectModel =
    { path : String
    , title : String
    , artist : String
    , album : String
    , track : Int
    , isSelected : Bool
    }


type alias GroupModel =
    { title : String
    , songs : List FileObjectModel
    }

type alias IndexedFileObject =
    { id : Int
    , fileObject : FileObjectModel
    }
type alias IndexedGroupModel =
    { id : Int
    , model : GroupModel
    }
