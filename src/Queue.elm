module Queue exposing (view, update, Msg, drop)

import Html exposing (Html)
import Html.Events as Events
import Html.App as Html
import MyModels exposing (..)
import MyStyle exposing (..)
import Array exposing (Array)
import QueueSong


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
                                }
                            , id = newId
                        }
                )
    in
        if queueModel.mouseOver then
            let
                newSongs =
                    getNewSongsToAdd parentModel.songs

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
                }
        else
            { queueModel
                | array = resetQueue <|
                    Array.filter (.model >> .isDragging >> not) queueModel.array
            }


getNewSongsToAdd : List IndexedSongModel -> Array IndexedQueueSongModel
getNewSongsToAdd songModels =
    Array.fromList
        <| List.map
            (\sm ->
                { model =
                    { path = sm.model.path
                    , title = sm.model.title
                    , artist = sm.model.artist
                    , album = sm.model.album
                    , track = sm.model.track
                    , picture = sm.model.picture
                    , isDragging = False
                    , isMouseOver = False
                    }
                , id = 0
                }
            )
        <| List.filter (.model >> .isDragging) songModels


view : ParentModel -> Html Msg
view parent =
    Html.div
        [ MyStyle.queueViewContainer parent.isDragging
        , Events.onMouseEnter MouseEnter
        , Events.onMouseLeave MouseLeave
        ]
        [ Html.ul [ MyStyle.songList ]
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
