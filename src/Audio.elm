module Audio exposing (Msg, init, view, update, previousSong, nextSong)

import Html exposing (Html)
import Html.Events as Events
import Html.Attributes as Attr
import Json.Decode as JsonD exposing (Decoder, (:=))
import MyStyle
import Array
import MyModels
import Helpers


type alias ParentModel =
    MyModels.Model


type alias Model =
    String


init : String -> Model
init path =
    path


update : Msg -> ParentModel -> (ParentModel, Cmd msg)
update msg model =
    case msg of
        NextSong ->
            nextSong model

        PreviousSong ->
            previousSong model


nextSong : ParentModel -> (ParentModel, Cmd msg)
nextSong model =
    let
        shouldReset =
            model.currentSong >= (Array.length model.queue.array) - 1
    in
        if shouldReset then
            ({ model
                | currentSong = 0
            }, Helpers.lookupAlbumArt 0 model.queue.array)
        else
          let newCurrentSong = model.currentSong + 1 in
            ({ model
                | currentSong = newCurrentSong
            }, Helpers.lookupAlbumArt newCurrentSong model.queue.array)


previousSong : ParentModel -> (ParentModel, Cmd msg)
previousSong model =
    let
        shouldReset =
            model.currentSong == 0
    in
        if shouldReset then
          let newCurrentSong = (Array.length model.queue.array - 1) in
            ({ model
                | currentSong = newCurrentSong
            }, Helpers.lookupAlbumArt newCurrentSong model.queue.array)
        else
          let newCurrentSong = (model.currentSong - 1) in
            ({ model
                | currentSong = newCurrentSong
            }, Helpers.lookupAlbumArt newCurrentSong model.queue.array)


type Msg
    = NextSong
    | PreviousSong


view : Model -> Html Msg
view model =
    Html.div [ Attr.id "audio-view-container" ]
        [ (Html.div [ ]
            [ Html.audio
                [ Attr.id "audio-player-container"
                , Attr.src model
                , Attr.type' "audio/mp3"
                , Attr.controls True
                , Attr.autoplay True
                , Events.on "ended" (JsonD.succeed NextSong)
                ]
                []
            ]
          )
        ]
