module FileObject exposing (Msg, init, update, view, reset)

import Html exposing (Html)
import Html.Events as Events
import MyModels exposing (..)
import MyStyle exposing (..)


init : FileObjectModel -> FileObjectModel
init fileObjectModel = fileObjectModel


type Msg
    = ClickFile


update : Msg -> FileObjectModel -> ( FileObjectModel, Cmd Msg )
update msg model =
    case msg of
        ClickFile ->
            ( { model | isSelected = not model.isSelected }, Cmd.none )


view : FileObjectModel -> Html Msg
view model =
    Html.li
        [ MyStyle.songItem model.isSelected
        , Events.onClick <| ClickFile
        ]
        [ Html.text model.title ]


reset : FileObjectModel -> FileObjectModel
reset model =
    { model | isSelected = False }
