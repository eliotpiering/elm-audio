module MyModels exposing (..)
import Array exposing (Array)


type alias Model =
    { currentSong : Int
    , files : List FileRecord
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


