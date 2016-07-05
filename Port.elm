port module Port exposing (..)
import MyModels exposing (FileObjectModel, GroupModel)

port updateSongs : (List FileObjectModel -> msg) -> Sub msg
port updateGroups : (List GroupModel -> msg)-> Sub msg

port sortByAlbum : String -> Cmd msg
port sortByArtist : String -> Cmd msg
port sortByTitle : String -> Cmd msg

port groupBy : String -> Cmd msg

port createDatabase : String -> Cmd msg
port destroyDatabase : String -> Cmd msg


port pause : String -> Cmd msg
