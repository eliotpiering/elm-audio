module MyModels exposing (..)

import Array exposing (Array)
import Drag


type alias Model =
    { currentSong : Int
    , files : List IndexedFileObject
    , subDirs : List FileRecord
    , queue : Array FileRecord
    , rootPath : String
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
    , dragModel : Drag.Model
    }


type alias IndexedFileObject =
    { id : Int
    , fileObject : FileObjectModel
    }
                             
