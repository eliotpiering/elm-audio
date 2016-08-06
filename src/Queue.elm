module Queue exposing (view, update, Msg, drop)

import Html exposing (Html)
import Html.Events as Events
import Html.Attributes as Attr
import Html.App as Html
import MyModels exposing (..)
import MyStyle exposing (..)
import Array exposing (Array)
import QueueSong
import SortSongs
import Dict exposing (Dict)


type alias ParentModel =
    Model


type Msg
    = MouseEnter
    | MouseLeave
    | SongMsg Int QueueSong.Msg


update : Msg -> QueueModel -> QueueModel
update msg model =
    case msg of
        MouseEnter ->
            { model | mouseOver = True }

        MouseLeave ->
            { model | mouseOver = False }

        SongMsg id msg ->
            let
                updatedQueueSongsWithProps =
                    (Array.map
                        (\indexed ->
                            if indexed.id == id then
                                let
                                    ( newModel, maybeMouseOverItemId ) =
                                        QueueSong.update msg indexed.model
                                in
                                    case maybeMouseOverItemId of
                                        Just _ ->
                                            ( { indexed
                                                | model = newModel
                                              }
                                            , Just id
                                            )

                                        Nothing ->
                                            ( { indexed
                                                | model = newModel
                                              }
                                            , Nothing
                                            )
                            else
                                ( indexed, Nothing )
                        )
                        model.array
                    )
            in
                { model
                    | array = Array.map fst updatedQueueSongsWithProps
                    , mouseOverItem = Maybe.withDefault (Array.length model.array) <| Maybe.oneOf <| Array.toList <| Array.map snd updatedQueueSongsWithProps
                }


drop : ParentModel -> QueueModel
drop parentModel =
    let
        queueModel =
            parentModel.queue

        resetQueue =
            Array.indexedMap
                (\newId song ->
                    let
                        songModel =
                            song.model
                    in
                        { song
                            | model =
                                { songModel
                                    | isDragging = False
                                    , isMouseOver = False
                                }
                            , id = newId
                        }
                )
    in
        if queueModel.mouseOver then
            let
                newSongs =
                    Array.append (getNewSongsToAdd parentModel.songs) (getNewGroupsToAdd parentModel.groups)

                reorderedQueueSongs =
                    Array.filter (.model >> .isDragging) queueModel.array

                queueSongsNotDragging =
                    Array.filter (.model >> .isDragging >> not) queueModel.array

                left =
                    Array.slice 0 (Debug.log "quemodel mouse over item" queueModel.mouseOverItem) queueSongsNotDragging

                right =
                    Array.slice queueModel.mouseOverItem (Array.length queueModel.array) queueSongsNotDragging
            in
                { queueModel
                    | array =
                        resetQueue
                            <| Array.append left
                            <| Array.append reorderedQueueSongs
                            <| Array.append newSongs right
                    , mouseOverItem = Array.length queueModel.array + 1
                }
        else
            { queueModel
                | array =
                    resetQueue
                        <| Debug.log "how many in filter"
                        <| Array.filter (.model >> .isDragging >> not) queueModel.array
                , mouseOverItem = Array.length queueModel.array
            }


getNewSongsToAdd : List IndexedSongModel -> Array IndexedQueueSongModel
getNewSongsToAdd songModels =
    Array.fromList
        <| List.map songModelToQueueModel
        <| List.filter (.isDragging)
        <| List.map .model songModels


getNewGroupsToAdd : Dict String GroupModel -> Array IndexedQueueSongModel
getNewGroupsToAdd dict =
    let
        selectedGroupModels =
            dict |> Dict.values |> List.filter .isSelected

        songModels =
            SortSongs.byAlbumAndTrack <| List.foldl (\gm acc -> gm.songs ++ acc) [] selectedGroupModels
    in
        Array.fromList
            <| List.map songModelToQueueModel songModels


songModelToQueueModel : SongModel -> IndexedQueueSongModel
songModelToQueueModel sm =
    { model =
        { path = sm.path
        , title = sm.title
        , artist = sm.artist
        , album = sm.album
        , track = sm.track
        , picture = sm.picture
        , isDragging = False
        , isMouseOver = False
        }
    , id = 0
    }


view : ParentModel -> Html Msg
view parent =
    Html.div
        [ Attr.id "queue-view-container"
        , Attr.class "scroll-box"
        , MyStyle.queueViewContainer parent.isDragging
        , Events.onMouseEnter MouseEnter
        , Events.onMouseLeave MouseLeave
        ]
        [ Html.ul []
            <| Array.toList
            <| Array.indexedMap (queueToHtml parent.currentSong parent.currentMousePos) parent.queue.array
        ]


queueToHtml : Int -> { x : Int, y : Int } -> Int -> IndexedQueueSongModel -> Html Msg
queueToHtml currentSong dragPos i indexedQueueSongModel =
    let
        isCurrentSong =
            (i == currentSong)
    in
        Html.map (SongMsg i) (QueueSong.view indexedQueueSongModel.model dragPos isCurrentSong)



-- Html.li [ MyStyle.songItem isCurrentSong ]
--     [ Html.text iSongModel) indexedSongModel.model.title ]
