module Item exposing (..)

import Html exposing (Html)
import Html.Events as Events
import Html.Attributes as Attr
import Html.App as Html
import MyModels exposing (..)
import MyStyle exposing (..)


type Msg
    = MouseEnter
    | MouseLeave
    | ItemClicked
    | ItemDoubleClicked
    | Reset


type ItemCmd
    = DoubleClicked
    | MouseEntered
    | Clicked


type alias Pos =
    { x : Int, y : Int }


update : Msg -> ItemModel -> ( ItemModel, Maybe ItemCmd )
update msg model =
    case Debug.log "itemmsg " msg of
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


browserItemView : Maybe Pos -> String -> ItemModel -> Html Msg
browserItemView maybeDragPos id model =
    case model.data of
        Song songModel ->
            Html.li
                [ Attr.class "song-item"
                , Events.onMouseDown ItemClicked
                , Events.onDoubleClick ItemDoubleClicked
                , Events.onMouseEnter MouseEnter
                , Events.onMouseLeave MouseLeave
                , MyStyle.isSelected model.isSelected
                ]
                [ Html.text songModel.title
                , Html.span [ MyStyle.dragging maybeDragPos model.isSelected] [ Html.text songModel.title ]
                ]

        Group groupModel ->
            Html.li
                [ Attr.class "group-item"
                , Attr.id <| "group-item-" ++ id
                , Events.onMouseDown ItemClicked
                , Events.onDoubleClick ItemDoubleClicked
                , MyStyle.isSelected model.isSelected
                ]
                [ Html.text groupModel.title
                , Html.span [ MyStyle.dragging maybeDragPos model.isSelected] [ Html.text groupModel.title ]
                ]


queueItemView : Maybe Pos -> Bool -> String -> ItemModel -> Html Msg
queueItemView maybeDragPos isCurrentSong id model =
    case model.data of
        Song songModel ->
            Html.li
                [ Attr.class "song-item"
                , MyStyle.mouseOver model.isMouseOver
                , MyStyle.currentSong isCurrentSong
                , Events.onMouseDown ItemClicked
                , Events.onDoubleClick ItemDoubleClicked
                , Events.onMouseEnter MouseEnter
                , Events.onMouseLeave MouseLeave
                ]
                [ Html.text songModel.title
                , Html.span [ MyStyle.dragging maybeDragPos model.isSelected] [ Html.text songModel.title ]
                ]

        Group groupModel ->
            Html.li []
                [ Html.text "This should never happen" ]
