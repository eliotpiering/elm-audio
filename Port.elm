port module Port exposing (..)
import MyModels exposing (FileObjectModel, GroupModel)

port updateSongs : (List FileObjectModel -> msg) -> Sub msg
port updateGroups : (List GroupModel -> msg)-> Sub msg

port groupBy : String -> Cmd msg
port textSearch : String -> Cmd msg

port createDatabase : String -> Cmd msg
port destroyDatabase : String -> Cmd msg


port pause : String -> Cmd msg
