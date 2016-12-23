module Song exposing (..)

import Html exposing (Html)
import Html.Events as Events
import Html.Attributes as Attr
import MyModels exposing (..)
import MyStyle exposing (..)


type Msg
    = MouseEnter
    | MouseLeave
    | ItemClicked
    | ItemDoubleClicked
    | Reset


type SongCmd
    = DoubleClicked
    | MouseEntered
    | Clicked


type alias Pos =
    { x : Int, y : Int }


update : Msg -> SongItemModel -> ( SongItemModel, Maybe SongCmd )
update msg model =
    case msg of
        MouseEnter ->
            ( { model | isMouseOver = True }, Just MouseEntered )

        MouseLeave ->
            ( { model | isMouseOver = False }, Nothing )

        ItemClicked ->
            ( { model | isSelected = not model.isSelected }, Just Clicked )

        ItemDoubleClicked ->
            ( model, Just DoubleClicked )

        Reset ->
            ( { model | isSelected = False }, Nothing )


view : Maybe Pos -> Bool -> String -> SongItemModel -> Html Msg
view maybeDragPos isCurrentSong id model =
    Html.li
        [ Attr.class "song-item"
        , MyStyle.currentSong isCurrentSong
        , Events.onMouseDown ItemClicked
        , Events.onDoubleClick ItemDoubleClicked
        , Events.onMouseEnter MouseEnter
        , Events.onMouseLeave MouseLeave
        , MyStyle.isSelected model.isSelected
        , MyStyle.mouseOver model.isMouseOver
        ]
        [ Html.text model.song.title
        , Html.span [ MyStyle.dragging maybeDragPos model.isSelected ] [ Html.text model.song.title ]
        ]
