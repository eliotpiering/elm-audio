module Audio exposing (Msg, view, update, previousSong, nextSong)

import Html exposing (Html)
import Html.Events as Events
import Html.Attributes as Attr
import Json.Decode as JsonD exposing (Decoder)
import MyStyle
import Array
import MyModels
import Helpers
import ApiHelpers


type alias ParentModel =
    MyModels.Model


type alias Model =
    MyModels.SongModel


update : Msg -> ParentModel -> ( ParentModel, Cmd msg )
update msg model =
    case msg of
        NextSong ->
            nextSong model

        PreviousSong ->
            previousSong model


nextSong : ParentModel -> ( ParentModel, Cmd msg )
nextSong model =
    let
        shouldReset =
            model.currentSong >= (Array.length model.queue.array) - 1
    in
        if shouldReset then
            ( { model
                | currentSong = 0
              }
            , Helpers.lookupAlbumArt 0 model.queue.array
            )
        else
            let
                newCurrentSong =
                    model.currentSong + 1
            in
                ( { model
                    | currentSong = newCurrentSong
                  }
                , Helpers.lookupAlbumArt newCurrentSong model.queue.array
                )


previousSong : ParentModel -> ( ParentModel, Cmd msg )
previousSong model =
    let
        shouldReset =
            model.currentSong == 0
    in
        if shouldReset then
            let
                newCurrentSong =
                    (Array.length model.queue.array - 1)
            in
                ( { model
                    | currentSong = newCurrentSong
                  }
                , Helpers.lookupAlbumArt newCurrentSong model.queue.array
                )
        else
            let
                newCurrentSong =
                    (model.currentSong - 1)
            in
                ( { model
                    | currentSong = newCurrentSong
                  }
                , Helpers.lookupAlbumArt newCurrentSong model.queue.array
                )


type Msg
    = NextSong
    | PreviousSong


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
        , Events.on "ended" (JsonD.succeed NextSong)
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
