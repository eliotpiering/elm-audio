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


type Msg
    = ItemMsg String Item.Msg
    | Reset
    | UpdateSongs ItemDictionary
    | MouseEnter
    | MouseLeave


type BrowserCmd
    = OpenGroup ItemModel
    | AddSong ItemModel


type alias Pos =
    { x : Int, y : Int }


initialModel : BrowserModel
initialModel =
    { isMouseOver = False, items = Dict.empty }


update : Msg -> Bool -> BrowserModel -> ( BrowserModel, Maybe BrowserCmd )
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
                                        -- let
                                        --     newItems =
                                        --         Helpers.makeSongItemDictionary groupModel.songs
                                        -- in
                                        --     ( { model_ | items = newItems }, Nothing )
                                        ( model_, Just <| OpenGroup item_)

                                    Song _ ->
                                        ( model_, Just <| AddSong item_ )

                            Just (Item.Clicked) ->
                                if isShiftDown then
                                    ( model_, Nothing )
                                else
                                    let
                                        cleanItems =
                                            resetItems model.items

                                        itemsWithOneSelected =
                                            Dict.insert id item_ cleanItems
                                    in
                                        ( { model | items = itemsWithOneSelected }, Nothing )

                            anythingElse ->
                                ( model_, Nothing )

                Nothing ->
                    ( model, Nothing )

        Reset ->
            ( { model | items = resetItems model.items }, Nothing )

        UpdateSongs itemModels ->
            ({model | items = itemModels}, Nothing)

        MouseEnter ->
            ( { model | isMouseOver = True }, Nothing )

        MouseLeave ->
            ( { model | isMouseOver = False }, Nothing )


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
        [ Html.ul []
            (List.map (itemToHtml maybePos) <| SortSongs.byGroupTitle <| Dict.toList model.items)
        ]


itemToHtml : Maybe Pos -> ( String, ItemModel ) -> Html Msg
itemToHtml maybePos ( id, item ) =
    Html.map (ItemMsg id) (Item.browserItemView maybePos id item)
