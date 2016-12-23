module Browser exposing (..)

import Html exposing (Html)
import Html.Events as Events
import Html.Attributes as Attr
import MyModels exposing (..)
import MyStyle exposing (..)
import Dict exposing (Dict)
import Item
import Helpers
import SortSongs
import NavigationParser exposing (..)


type Msg
    = ItemMsg String Item.Msg
    | Reset
    | UpdateSongs ItemDictionary
    | MouseEnter
    | MouseLeave
    | GroupBy String


type BrowserCmd
    = OpenGroup ItemModel
    | AddSong ItemModel
    | ChangeRoute Route
    | None


type alias Pos =
    { x : Int, y : Int }


initialModel : BrowserModel
initialModel =
    { isMouseOver = False, items = Dict.empty }


update : Msg -> Bool -> BrowserModel -> ( BrowserModel, BrowserCmd )
update msg isShiftDown model =
    case msg of
        ItemMsg id msg ->
            case Dict.get id model.items of
                Just item ->
                    let
                        ( item_, itemCmd ) =
                            Item.update msg item

                        model_ =
                            { model | items = Dict.insert id item_ model.items }
                    in
                        case itemCmd of
                            Just (Item.DoubleClicked) ->
                                case item_.data of
                                    Group groupModel ->
                                        ( model_, OpenGroup item_)

                                    Song _ ->
                                        ( model_, AddSong item_ )

                            Just (Item.Clicked) ->
                                if isShiftDown then
                                    ( model_, None )
                                else
                                    let
                                        cleanItems =
                                            resetItems model.items

                                        itemsWithOneSelected =
                                            Dict.insert id item_ cleanItems
                                    in
                                        ( { model | items = itemsWithOneSelected }, None )

                            anythingElse ->
                                ( model_, None )

                Nothing ->
                    ( model, None )

        Reset ->
            ( { model | items = resetItems model.items }, None )

        UpdateSongs itemModels ->
            ({model | items = itemModels}, None)

        MouseEnter ->
            ( { model | isMouseOver = True }, None )

        MouseLeave ->
            ( { model | isMouseOver = False }, None )

        GroupBy key ->
            case key of
                "song" ->
                    ( model, ChangeRoute SongsRoute )

                "album" ->
                    ( model, ChangeRoute AlbumsRoute )

                "artist" ->
                    ( model, ChangeRoute ArtistsRoute )

                _ ->
                    ( model, None )


resetItems : ItemDictionary -> ItemDictionary
resetItems =
    Dict.map (\id item -> Item.update Item.Reset item |> Tuple.first)


view : Maybe Pos -> BrowserModel -> Html Msg
view maybePos model =
    Html.div
        [ Attr.id "file-view-container"
        , Attr.class "scroll-box"
        , Events.onMouseEnter MouseEnter
        , Events.onMouseLeave MouseLeave
        , MyStyle.mouseOver model.isMouseOver
        ]
        [ navigationView
        , Html.ul []
            (List.map (itemToHtml maybePos) <| SortSongs.byGroupTitle <| Dict.toList model.items)
        ]


itemToHtml : Maybe Pos -> ( String, ItemModel ) -> Html Msg
itemToHtml maybePos ( id, item ) =
    Html.map (ItemMsg id) (Item.browserItemView maybePos id item)

navigationView : Html Msg
navigationView =
    Html.ul [ Attr.id "navigation-view-container" ]
        [ Html.li [ Events.onClick (GroupBy "album") ] [ Html.text "Group By album" ]
        , Html.li [ Events.onClick (GroupBy "artist") ] [ Html.text "Group By artist" ]
        , Html.li [ Events.onClick (GroupBy "song") ] [ Html.text "Group By song" ]
        ]
