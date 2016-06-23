module FileObject exposing (Msg, init, update, view)

import Html exposing (Html)
import Html.Events as Events
import MyModels exposing (..)
import MyStyle exposing (..)
import Drag


init : FileRecord -> FileObjectModel
init fileRecord =
    { fileRecord = fileRecord, dragModel = Drag.initialModel }


type Msg
    = ClickFile FileRecord
    | Draging Position


update : Msg -> FileObjectModel -> ( FileObjectModel, Cmd Msg )
update msg model =
    case msg of
        ClickFile fileRecord ->
            ( model, Cmd.none )

        DragMsg dragMsg ->
            ( Debug.log "DragMsg" model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : FileObjectModel -> Sub Msg
subscriptions model =
    Drag.subscriptions mouse.downs


view : FileObjectModel -> Html Msg
view model =
    Html.li
        [ MyStyle.songItem
        , Events.onClick <| ClickFile model.fileRecord
        ]
        [ Html.text model.fileRecord.name ]
