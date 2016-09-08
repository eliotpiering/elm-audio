module Queue exposing (..)

import Html exposing (Html)
import Html.Events as Events
import Html.Attributes as Attr
import Html.App as Html
import MyModels exposing (..)
import MyStyle exposing (..)
import Array exposing (Array)
import SortSongs
import Dict exposing (Dict)
import Item


type Msg
    = MouseEnter
    | MouseLeave
    | ItemMsg Int Item.Msg
    | Drop (List ItemModel) Int
    | Reorder Int
    | Remove Int


type alias Pos =
    { x : Int, y : Int }


type QueueCmd
    = UpdateCurrentSong Int


update : Msg -> QueueModel -> ( QueueModel, Maybe QueueCmd )
update msg model =
    case msg of
        MouseEnter ->
            ( { model | mouseOver = True }, Nothing )

        MouseLeave ->
            ( { model | mouseOver = False }, Nothing )

        ItemMsg id msg ->
            case Array.get id model.array of
                Just item ->
                    let
                        ( item', itemCmd ) =
                            Item.update msg item

                        model' =
                            { model | array = Array.set id item' model.array }
                    in
                        case itemCmd of
                            Just (Item.MouseEntered) ->
                                ( { model' | mouseOverItem = id }, Nothing )

                            Just (Item.DoubleClicked) ->
                                ( model', Just <| UpdateCurrentSong id )

                            anythingElse ->
                                ( model', Nothing )

                Nothing ->
                    ( model, Nothing )

        Drop newItems currentQueueIndex ->
            let
                left =
                    Array.slice 0 model.mouseOverItem model.array

                right =
                    Array.slice model.mouseOverItem (Array.length model.array) model.array

                newArrayItems =
                    Array.fromList <| SortSongs.byAlbumAndTrack newItems

                newQueueIndex =
                    if currentQueueIndex > model.mouseOverItem then
                        currentQueueIndex + (Array.length newArrayItems)
                    else
                        currentQueueIndex
            in
                ( { model
                    | array =
                        resetQueue
                            <| Array.append left
                            <| Array.append newArrayItems right
                  }
                , Just <| UpdateCurrentSong newQueueIndex
                )

        Reorder currentQueueIndex ->
            let
                maybeIndexedItemToReorder =
                    model.array |> Array.toIndexedList |> List.filter (\( i, item ) -> item.isSelected) |> List.head
            in
                case maybeIndexedItemToReorder of
                    Just ( indexOfItemToReorder, itemToReorder ) ->
                        let
                            queueLength =
                                Array.length model.array

                            itemsToStayTheSame =
                                model.array |> Array.filter (not << .isSelected)

                            left =
                                Array.slice 0 model.mouseOverItem itemsToStayTheSame

                            right =
                                Array.slice model.mouseOverItem queueLength itemsToStayTheSame

                            reorderedQueue =
                                Array.append (Array.push itemToReorder left) right

                            newQueueIndex =
                                if currentQueueIndex > indexOfItemToReorder && currentQueueIndex < model.mouseOverItem then
                                    currentQueueIndex - 1
                                else if currentQueueIndex < indexOfItemToReorder && currentQueueIndex > model.mouseOverItem then
                                    currentQueueIndex + 1
                                else
                                    currentQueueIndex
                        in
                            ( { model | array = resetQueue reorderedQueue }, Just <| UpdateCurrentSong newQueueIndex )

                    Nothing ->
                        ( model, Nothing )

        Remove currentQueueIndex ->
            let
                maybeItemToRemove =
                    model.array |> Array.toIndexedList |> List.filter (\( i, item ) -> item.isSelected) |> List.head
            in
                case maybeItemToRemove of
                    Just ( index, item ) ->
                        let
                            newQueueIndex =
                                if index < currentQueueIndex then
                                    currentQueueIndex - 1
                                else
                                    currentQueueIndex

                            array' =
                                Array.append (Array.slice 0 index model.array) (Array.slice (index + 1) -1 model.array)
                        in
                            ( { model | array = resetQueue array' }, Just <| UpdateCurrentSong newQueueIndex )

                    Nothing ->
                        ( model, Nothing )


resetQueue : Array ItemModel -> Array ItemModel
resetQueue =
    Array.map (Item.update Item.Reset >> fst)


itemToHtml : Maybe Pos -> Int -> ( Int, ItemModel ) -> Html Msg
itemToHtml maybePos currentSong ( id, item ) =
    Html.map (ItemMsg id) (Item.queueItemView maybePos (id == currentSong) (toString id) item)


view : Maybe Pos -> Int -> QueueModel -> Html Msg
view maybePos currentSong model =
    Html.div
        [ Attr.id "queue-view-container"
        , Attr.class "scroll-box"
        , Events.onMouseEnter MouseEnter
        , Events.onMouseLeave MouseLeave
        , MyStyle.mouseOver model.mouseOver
        ]
        [ Html.ul []
            <| Array.toList
            <| Array.indexedMap ((\id item -> itemToHtml maybePos currentSong ( id, item ))) model.array
        ]
