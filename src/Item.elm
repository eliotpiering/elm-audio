module Item exposing (..)

import Html exposing (Html)
import Html.Events as Events
import Html.Attributes as Attr
import MyModels exposing (..)
import MyStyle exposing (..)


type Msg
    = ItemClicked
    | ItemDoubleClicked
    | Reset


type ItemCmd
    = DoubleClicked
    | Clicked
    | None


type alias Pos =
    { x : Int, y : Int }


update : Msg -> ItemModel -> ( ItemModel, ItemCmd )
update msg model =
    case msg of
        ItemClicked ->
            ( { model | isSelected = not model.isSelected }, Clicked )

        ItemDoubleClicked ->
            ( model, DoubleClicked )

        Reset ->
            ( { model | isSelected = False }, None )


view : Maybe Pos -> String -> ItemModel -> Html Msg
view maybeDragPos id model =
    case model.data of
        Song songModel ->
            Html.li (List.append [ Attr.class "song-item" ] <| commonAttrubutes model) <|
                commonHtml model maybeDragPos songModel

        Group groupModel ->
            Html.li (List.append [ Attr.class "group-item", Attr.id <| "group-item-" ++ id ] <| commonAttrubutes model) <|
                commonHtml model maybeDragPos groupModel


commonAttrubutes : ItemModel -> List (Html.Attribute Msg)
commonAttrubutes model =
    [ Events.onMouseDown ItemClicked
    , Events.onDoubleClick ItemDoubleClicked
    , MyStyle.isSelected model.isSelected
    , MyStyle.mouseOver model.isMouseOver
    ]


commonHtml : ItemModel -> Maybe Pos -> { a | title : String } -> List (Html Msg)
commonHtml model maybeDragPos data =
    [ Html.text data.title
    , Html.span [ MyStyle.dragging maybeDragPos model.isSelected ] [ Html.text data.title ]
    ]
