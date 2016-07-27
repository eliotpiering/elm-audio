module Song exposing (Msg, init, update, view, reset)

import Html exposing (Html)
import Html.Events as Events
import Html.Attributes as Attr
import MyModels exposing (..)
import MyStyle exposing (..)


init : SongModel -> SongModel
init songModel =
    songModel


type Msg
    = DragStart


update : Msg -> SongModel -> ( SongModel, Cmd Msg )
update msg model =
    case msg of
        DragStart ->
            ( { model | isDragging = True }, Cmd.none )


view : SongModel -> {x:Int,y:Int} -> Html Msg
view model dragPos =
    Html.tr
        [ Attr.class "song-item"
        , MyStyle.dragging dragPos model.isDragging
        , Events.onMouseDown DragStart
        ]
        [ Html.td [] [Html.text model.title]
        , Html.td [] [Html.text model.artist]
        , Html.td [] [Html.text model.album]
        ]


reset : SongModel -> SongModel
reset model =
    { model | isDragging = False }
