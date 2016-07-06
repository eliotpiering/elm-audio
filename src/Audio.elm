module Audio exposing (Msg, init, view, update, previousSong, nextSong)

import Html exposing (Html)
import Html.Events as Events
import Html.Attributes as Attr
import Json.Decode as JsonD exposing (Decoder, (:=))
import MyStyle
import Array
import MyModels


type alias ParentModel =
    MyModels.Model


type alias Model =
    String


init : String -> Model
init path =
    path


update : Msg -> ParentModel -> ParentModel
update msg model =
    case msg of
        NextSong ->
            nextSong model

        PreviousSong ->
            previousSong model


nextSong : ParentModel -> ParentModel
nextSong model =
    let
        shouldReset =
            model.currentSong >= (Array.length model.queue.array) - 1
    in
        if shouldReset then
            { model
                | currentSong = 0
            }
        else
            { model
                | currentSong = (model.currentSong + 1)
            }


previousSong : ParentModel -> ParentModel
previousSong model =
    let
        shouldReset =
            model.currentSong == 0
    in
        if shouldReset then
            { model
                | currentSong = (Array.length model.queue.array - 1)
            }
        else
            { model
                | currentSong = (model.currentSong - 1)
            }


type Msg
    = NextSong
    | PreviousSong


view : Model -> Html Msg
view model =
    Html.div [ MyStyle.audioViewContainer ]
        [ previousSongButton
        , (Html.div [ MyStyle.floatLeft ]
            [ Html.audio
                [ Attr.src model
                , Attr.type' "audio/mp3"
                , Attr.controls True
                , Attr.autoplay True
                , MyStyle.audioPlayer
                , Events.on "ended" (JsonD.succeed NextSong)
                ]
                []
            ]
          )
        , nextSongButton
        ]


nextSongButton : Html Msg
nextSongButton =
    Html.div
        [ MyStyle.floatLeft
        ]
        [ Html.div [ MyStyle.button, Events.onClick <| NextSong ] [ Html.text "NEXT -->" ] ]


previousSongButton : Html Msg
previousSongButton =
    Html.div
        [ MyStyle.floatLeft
        ]
        [ Html.div [ MyStyle.button, Events.onClick <| PreviousSong ] [ Html.text "<-- PREVIOUS" ] ]
