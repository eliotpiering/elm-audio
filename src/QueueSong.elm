module QueueSong exposing (..) -- (Msg, init, update, view, reset)

import Html exposing (Html)
import Html.Events as Events
import Html.Attributes as Attr
import MyModels exposing (..)
import MyStyle exposing (..)


init : QueueSongModel -> QueueSongModel
init songModel =
    songModel


type Msg
    = DragStart
    | MouseEnter
    | MouseLeave
    | SetCurrentSong

type Prop
  = MouseEntered


update : Msg -> QueueSongModel -> ( QueueSongModel, Maybe Prop)
update msg model =
    case msg of
        DragStart ->
            ( { model | isDragging = True }, Nothing )
        MouseEnter ->
            ( { model | isMouseOver = True }, Just MouseEntered)
        MouseLeave ->
            ( { model | isMouseOver = False }, Nothing)
        SetCurrentSong ->
            ( model, Nothing)



view : QueueSongModel -> { x : Int, y : Int } -> Bool -> Html Msg
view model dragPos isCurrentSong =
    Html.li
        [ Attr.id "song-item" 
        -- , MyStyle.dragging dragPos model.isDragging
        , MyStyle.mouseOver model.isMouseOver
        , (if isCurrentSong then
            MyStyle.currentSong
           else
            MyStyle.none
          )
        , Events.onClick SetCurrentSong
        , Events.onMouseDown DragStart
        , Events.onMouseEnter MouseEnter
        , Events.onMouseLeave MouseLeave
        ]
        [ Html.text model.title ]


reset : QueueSongModel -> QueueSongModel
reset model =
    { model
      | isDragging = False
      , isMouseOver = False
    }
