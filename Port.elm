port module Port exposing (..)
import MyModels exposing (DataModel)

port updateDir : (DataModel -> msg) -> Sub msg
port newDir : String -> Cmd msg
