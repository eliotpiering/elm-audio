module Audio exposing (view, Msg)

import Html exposing (Html)
import Html.Events as Events
import Html.Attributes as Attr
import Json.Decode as JsonD exposing (Decoder)
import MyStyle
import Array
import MyModels
import Helpers
import ApiHelpers


type alias Model =
    MyModels.SongModel

type Msg = NextSong


streamPath : Int -> String
streamPath id =
    ApiHelpers.apiEndpoint ++ "stream/" ++ (toString id)


view : Model -> Html Msg
view model =
    Html.div [ Attr.id "audio-view-container" ]
        [ Html.div []
            [ htmlAudio model.id
            , currentSongInfo model
            ]
        ]


htmlAudio : Int -> Html Msg
htmlAudio id =
    Html.audio
        [ Attr.src (streamPath id)
        , Attr.type_ "audio/mp3"
        , Attr.controls True
        , Attr.autoplay True
        -- , Events.on "ended" (JsonD.succeed NextSong)
        ]
        []


currentSongInfo : Model -> Html Msg
currentSongInfo model =
    Html.table []
        [ Html.thead []
            [ Html.tr []
                [ tableHeaderItem "Artist"
                , tableHeaderItem "Album"
                , tableHeaderItem "Song"
                ]
            ]
        , Html.tbody []
            [ Html.tr []
                [ tableItem model.artist
                , tableItem model.album
                , tableItem model.title
                ]
            ]
        ]


tableHeaderItem str =
    Html.th [] [ Html.text str ]


tableItem str =
    Html.td [] [ Html.text str ]
