module Item exposing (..)

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


type ItemCmd
    = DoubleClicked
    | MouseEntered
    | Clicked


type alias Pos =
    { x : Int, y : Int }


update : Msg -> ItemModel -> ( ItemModel, Maybe ItemCmd )
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


browserItemView : Maybe Pos -> String -> ItemModel -> Html Msg
browserItemView maybeDragPos id model =
    case model.data of
        Song songModel ->
            Html.li (List.append [ Attr.class "song-item" ] <| commonAttrubutes model) <|
                commonHtml model maybeDragPos songModel

        Group groupModel ->
            Html.li (List.append [ Attr.class "group-item", Attr.id <| "group-item-" ++ id ] <| commonAttrubutes model) <|
                commonHtml model maybeDragPos groupModel


queueItemView : Maybe Pos -> Bool -> String -> ItemModel -> Html Msg
queueItemView maybeDragPos isCurrentSong id model =
    case model.data of
        Song songModel ->
            Html.li (List.append [ Attr.class "song-item", MyStyle.currentSong isCurrentSong ] <| commonAttrubutes model) <|
                commonHtml model maybeDragPos songModel

        Group groupModel ->
            Html.li []
                [ Html.text "This should never happen" ]


commonAttrubutes : ItemModel -> List (Html.Attribute Msg)
commonAttrubutes model =
    [ Events.onMouseDown ItemClicked
    , Events.onDoubleClick ItemDoubleClicked
    , Events.onMouseEnter MouseEnter
    , Events.onMouseLeave MouseLeave
    , MyStyle.isSelected model.isSelected
    , MyStyle.mouseOver model.isMouseOver
    ]


commonHtml : ItemModel -> Maybe Pos -> { a | title : String } -> List (Html Msg)
commonHtml model maybeDragPos data =
    [ Html.text data.title
    , Html.span [ MyStyle.dragging maybeDragPos model.isSelected ] [ Html.text data.title ]
    ]
