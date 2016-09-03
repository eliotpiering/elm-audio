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


view : Maybe Pos -> Bool -> String -> ItemModel -> Html Msg
view maybeDragPos isCurrentSong id model =
    if model.isSelected then
        case model.data of
            Song songModel ->
                Html.li
                    [ Attr.class "song-item"
                    , MyStyle.currentSong
                    , Events.onClick ItemClicked
                    , Events.onDoubleClick ItemDoubleClicked
                      -- , MyStyle.mouseOver model.isMouseOver
                    , Events.onMouseEnter MouseEnter
                    , Events.onMouseLeave MouseLeave
                    ]
                    [ Html.text songModel.title
                    , Html.span [ MyStyle.dragging maybeDragPos ] [ Html.text songModel.title ]
                    ]

            Group groupModel ->
                Html.li
                    [ Attr.class "group-item"
                    , Attr.id <| "group-item-" ++ id
                    , MyStyle.currentSong
                    , Events.onClick ItemClicked
                    , Events.onDoubleClick ItemDoubleClicked
                      -- , Events.onMouseEnter MouseEnter
                      -- , Events.onMouseLeave MouseLeave
                      -- , MyStyle.mouseOver model.isMouseOver
                    ]
                    [ Html.text groupModel.title
                    , Html.span [ MyStyle.dragging maybeDragPos ] [ Html.text groupModel.title ]
                    ]
    else
        case model.data of
            Song songModel ->
                Html.li
                    [ Attr.class "song-item"
                      -- , MyStyle.mouseOver model.isMouseOver
                    , (if isCurrentSong then MyStyle.currentSong else MyStyle.none)
                    , Events.onClick ItemClicked
                    , Events.onDoubleClick ItemDoubleClicked
                    , Events.onMouseEnter MouseEnter
                    , Events.onMouseLeave MouseLeave
                    ]
                    [ Html.text songModel.title ]

            Group groupModel ->
                Html.li
                    [ Attr.class "group-item"
                    , Attr.id <| "group-item-" ++ id
                    -- , MyStyle.mouseOver model.isMouseOver
                    , Events.onClick ItemClicked
                    , Events.onDoubleClick ItemDoubleClicked
                      , Events.onMouseEnter MouseEnter
                      , Events.onMouseLeave MouseLeave
                    ]
                    [ Html.text groupModel.title ]
