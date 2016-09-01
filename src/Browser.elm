module Browser exposing (..)

import Html exposing (Html)
import Html.Events as Events
import Html.Attributes as Attr
import Html.App as Html
import MyModels exposing (..)
import MyStyle exposing (..)
import Dict exposing (Dict)
import Item


type Msg
    = ItemMsg String Item.Msg


type BrowserCmd
    = OpenGroup ItemModel
    | AddSong ItemModel

type alias Pos =
    { x : Int, y : Int }

update : Msg -> ItemDictionary -> ( ItemDictionary, Maybe BrowserCmd )
update msg model =
    case Debug.log "browser msg is " msg of
        ItemMsg id msg ->
            case Dict.get id model of
                Just item ->
                    let
                        ( item', itemCmd ) =
                            Item.update msg item

                        model' =
                            Dict.insert id item' model
                    in
                        case itemCmd of
                            Just Item.DoubleClicked ->
                              case item'.data of
                                Group _ ->
                                  (model', Just <| OpenGroup item')
                                Song _ ->
                                  (model', Just <| AddSong item')

                            anythingElse ->
                                ( model', Nothing )

                Nothing ->
                    ( model, Nothing )


view : Maybe Pos -> ItemDictionary -> Html Msg
view maybePos model =
    Html.div [ Attr.id "file-view-container", Attr.class "scroll-box" ]
        [ Html.ul [] (List.map (itemToHtml maybePos) <| Dict.toList model) ]


itemToHtml : Maybe Pos -> ( String, ItemModel ) -> Html Msg
itemToHtml maybePos ( id, item ) =
    Html.map (ItemMsg id) (Item.view maybePos item)
