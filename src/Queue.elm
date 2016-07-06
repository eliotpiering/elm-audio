module Queue exposing (view, update, Msg, drop)

import Html exposing (Html)
import Html.Events as Events
import MyModels exposing (..)
import MyStyle exposing (..)
import Array


type alias ParentModel =
    Model


type Msg
    = MouseEnter
    | MouseLeave


update : Msg -> QueueModel -> QueueModel
update msg model =
    case Debug.log "queue msg " msg of
        MouseEnter ->
            { model | mouseOver = True }

        MouseLeave ->
            { model | mouseOver = False }


drop : ParentModel -> QueueModel
drop parentModel =
    let
        queueModel =
            parentModel.queue
    in
        if Debug.log "is mouse over? " queueModel.mouseOver then
            { queueModel
                | array =
                    Array.append queueModel.array
                        <| Array.fromList
                        <| List.filter (.model >> .isDragging) parentModel.songs
            }
        else
            queueModel


view : QueueModel -> Int -> Bool -> Html Msg
view model currentSong isMouseDown =
        Html.div
            [ MyStyle.queueViewContainer isMouseDown
            , Events.onMouseEnter MouseEnter
            , Events.onMouseLeave MouseLeave
            ]
            [ Html.ul [ MyStyle.songList ]
                <| Array.toList
                <| Array.indexedMap (queueToHtml currentSong) model.array
            ]


queueToHtml : Int -> Int -> IndexedSongModel -> Html Msg
queueToHtml currentSong i indexedFileObject =
    let
        isCurrentSong =
            (i == currentSong)
    in
        Html.li [ MyStyle.songItem isCurrentSong ]
            [ Html.text indexedFileObject.model.title ]
