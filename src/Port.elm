port module Port exposing (..)

import MyModels exposing (SongModel, GroupModel)


port scrollToElement : String -> Cmd msg


port resetKeysBeingTyped : (String -> msg) -> Sub msg


port pause : String -> Cmd msg


port lookupAlbumArt : String -> Cmd msg


port updateAlbumArt : (String -> msg) -> Sub msg
