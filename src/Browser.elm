module Browser exposing (..)

import Html exposing (Html)
import Html.Events as Events
import Html.Attributes as Attr
import Html.App as Html
import MyModels exposing (..)
import MyStyle exposing (..)
import Dict exposing (Dict)
import Item
import Helpers
import SortSongs


type Msg
    = ItemMsg String Item.Msg
    | Reset


type BrowserCmd
    = OpenGroup ItemModel
    | AddSong ItemModel


type alias Pos =
    { x : Int, y : Int }


initialModel : BrowserModel
initialModel =
    { items = Dict.empty }


update : Msg -> Bool -> BrowserModel -> ( BrowserModel, Maybe BrowserCmd )
update msg isShiftDown model =
    case msg of
        ItemMsg id msg ->
            case Dict.get id model.items of
                Just item ->
                    let
                        ( item', itemCmd ) =
                            Item.update msg item

                        model' =
                            { model | items = Dict.insert id item' model.items }
                    in
                        case itemCmd of
                            Just (Item.DoubleClicked) ->
                                case item'.data of
                                    Group groupModel ->
                                        let
                                            newItems =
                                                Helpers.makeSongItemDictionary groupModel.songs
                                        in
                                            ( { model' | items = newItems }, Nothing )

                                    Song _ ->
                                        ( model', Just <| AddSong item' )

                            Just (Item.Clicked) ->
                              if isShiftDown then 
                                (model', Nothing)
                              else
                                let cleanItems = resetItems model.items
                                    itemsWithOneSelected = Dict.insert id item' cleanItems in
                                ({model | items = itemsWithOneSelected }, Nothing)


                            anythingElse ->
                                ( model', Nothing )

                Nothing ->
                    ( model, Nothing )

        Reset ->
            ( { model | items =  resetItems model.items }, Nothing )

resetItems : ItemDictionary -> ItemDictionary
resetItems = Dict.map (\id item -> Item.update Item.Reset item |> fst)


view : Maybe Pos -> BrowserModel -> Html Msg
view maybePos model =
    Html.div [ Attr.id "file-view-container", Attr.class "scroll-box" ]
        [ Html.ul [] (List.map (itemToHtml maybePos) <| SortSongs.byGroupTitle <| Dict.toList model.items) ]


itemToHtml : Maybe Pos -> ( String, ItemModel ) -> Html Msg
itemToHtml maybePos ( id, item ) =
    Html.map (ItemMsg id) (Item.view maybePos False id item)
