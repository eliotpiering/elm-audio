module QueueSong exposing (Msg, init, update, view, reset)

import Html exposing (Html)
import Html.Events as Events
import MyModels exposing (..)
import MyStyle exposing (..)


init : QueueSongModel -> QueueSongModel
init songModel =
    songModel


type Msg
    = DragStart
    | MouseEnter
    | MouseLeave

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



view : QueueSongModel -> { x : Int, y : Int } -> Bool -> Html Msg
view model dragPos isCurrentSong =
    Html.li
        [ MyStyle.songItem model.isDragging
        , MyStyle.dragging dragPos model.isDragging
        , MyStyle.mouseOver model.isMouseOver
        , (if isCurrentSong then
            MyStyle.currentSong
           else
            MyStyle.songItem model.isDragging
          )
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
