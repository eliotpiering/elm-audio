module MyModels exposing (..)

import Array exposing (Array)
import Drag


type alias Model =
    { currentSong : Int
    , files : List IndexedFileObject
    , subDirs : List FileRecord
    , queue : Array IndexedFileObject
    , rootPath : String
    , dropZone :
        { lowX : Int
        , highX : Int
        , lowY : Int
        , highY : Int
        }
    }


type alias FileRecord =
    { path : String
    , name : String
    }


type alias DataModel =
    { files : List FileRecord
    , subDirs : List FileRecord
    }


type alias FileObjectModel =
    { fileRecord : FileRecord
    , isSelected : Bool
    }


type alias IndexedFileObject =
    { id : Int
    , fileObject : FileObjectModel
    }
