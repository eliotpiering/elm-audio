module Queue exposing (..)

import Html exposing (Html)
import Html.Events as Events
import Html.Attributes as Attr
import MyModels exposing (..)
import MyStyle exposing (..)
import Array exposing (Array)
import SortSongs
import Dict exposing (Dict)
import Http
import Helpers
import Array.Extra
import Audio
import QueueItem


type Msg
    = MouseEnter
    | MouseLeave
    | QueueItemMsg Int QueueItem.Msg
    | AudioMsg Audio.Msg
    | Drop (List QueueItemModel)
    | Reorder
    | Remove
    | PreviousSong
    | NextSong


type alias Pos =
    { x : Int, y : Int }


update : Msg -> QueueModel -> QueueModel
update msg model =
    case msg of
        MouseEnter ->
            { model | mouseOver = True }

        MouseLeave ->
            { model | mouseOver = False }

        QueueItemMsg id msg ->
            case Array.get id model.array of
                Just song ->
                    let
                        ( song_, queueItemCmd ) =
                            QueueItem.update msg song

                        model_ =
                            { model | array = Array.set id song_ model.array }
                    in
                        case queueItemCmd of
                            Just (QueueItem.MouseEntered) ->
                                { model_ | mouseOverItem = id }

                            Just (QueueItem.DoubleClicked) ->
                                { model_ | currentSong = id }

                            anythingElse ->
                                model_

                Nothing ->
                    model

        Drop newSongs ->
            let
                left =
                    Array.slice 0 model.mouseOverItem model.array

                right =
                    Array.slice model.mouseOverItem (Array.length model.array) model.array

                newArrayItems =
                    Array.fromList <| SortSongs.byAlbumAndTrack newSongs

                currentQueueIndex =
                    model.currentSong

                newQueueIndex =
                    if currentQueueIndex > model.mouseOverItem then
                        currentQueueIndex + (Array.length newArrayItems)
                    else
                        currentQueueIndex
            in
                { model
                    | array =
                        resetQueue <|
                            Array.append left <|
                                Array.append newArrayItems right
                    , currentSong = newQueueIndex
                }

        Reorder ->
            let
                currentQueueIndex =
                    model.currentSong

                maybeIndexedItemToReorder =
                    model.array |> Array.toIndexedList |> List.filter (\( i, song ) -> song.isSelected) |> List.head
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
                            { model
                                | array = resetQueue reorderedQueue
                                , currentSong = newQueueIndex
                            }

                    Nothing ->
                        model

        Remove ->
            let
                currentQueueIndex =
                    model.currentSong

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

                            array_ =
                                Array.Extra.removeAt index model.array
                        in
                            { model
                                | array = resetQueue array_
                                , currentSong = newQueueIndex
                            }

                    Nothing ->
                        model

        NextSong ->
            let
                shouldReset =
                    model.currentSong >= (Array.length model.array) - 1
            in
                if shouldReset then
                    { model
                        | currentSong = 0
                    }
                else
                    let
                        newCurrentSong =
                            model.currentSong + 1
                    in
                        { model
                            | currentSong = newCurrentSong
                        }

        PreviousSong ->
            let
                shouldReset =
                    model.currentSong == 0
            in
                if shouldReset then
                    let
                        newCurrentSong =
                            (Array.length model.array - 1)
                    in
                        { model
                            | currentSong = newCurrentSong
                        }
                else
                    let
                        newCurrentSong =
                            (model.currentSong - 1)
                    in
                        { model
                            | currentSong = newCurrentSong
                        }

        AudioMsg msg ->
            model


resetQueue : Array QueueItemModel -> Array QueueItemModel
resetQueue =
    Array.map (QueueItem.update QueueItem.Reset >> Tuple.first)


itemToHtml : Maybe Pos -> Int -> ( Int, QueueItemModel ) -> Html Msg
itemToHtml maybePos currentSong ( id, song ) =
    Html.map (QueueItemMsg id) (QueueItem.view maybePos (id == currentSong) (toString id) song)


view : Maybe Pos -> QueueModel -> Html Msg
view maybePos model =
    Html.div
        [ Attr.id "queue-view-container"
        , Attr.class "scroll-box"
        , Events.onMouseEnter MouseEnter
        , Events.onMouseLeave MouseLeave
        , MyStyle.mouseOver model.mouseOver
        ]
        [ audioPlayer <| getMaybeCurrentSong model
        , Html.ul [] <|
            Array.toList <|
                Array.indexedMap ((\id item -> itemToHtml maybePos model.currentSong ( id, item ))) model.array
        ]


audioPlayer : Maybe SongModel -> Html Msg
audioPlayer maybeSong =
    case maybeSong of
        Just song ->
            Html.map AudioMsg (Audio.view song)

        Nothing ->
            Html.div [ Attr.id "audio-view-container" ] []


getMaybeCurrentSong : QueueModel -> Maybe SongModel
getMaybeCurrentSong model =
    case Array.get model.currentSong model.array of
        Just songItem ->
            Just songItem.song

        Nothing ->
            Nothing
