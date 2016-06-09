module Main exposing (..)

import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events
import Html.App as Html
import Json.Decode as JsonD exposing (Decoder, (:=))
import Array exposing (Array)
import Debug
import Task
import Http



main : Program Never
main =
    Html.program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


init : ( Model, Cmd Msg )
init =
    ( initialModel
    , fetchFileRecords
    )



-- MODEL


type alias Model =
    { currentSong : Int
    , files : List FileRecord
    , queue : Array FileRecord
    }


type alias FileRecord =
    { path : String
    , name : String
    }


initialModel : Model
initialModel =
    { currentSong = 0
    , queue = Array.empty
    , files = [ { path = "/home/eliot/Music/Micachu%20and%20the%20Shapes%20-%20Good%20Sad%20Happy%20Bad%20%282015%29%20-%20CD%20V0/10%20Peach.mp3", name = "10 Peach.mp3" } ]
    }



-- UPDATE


type Msg
    = ClickFile FileRecord
    | NextSong
      -- Http stuff
    | FetchFileRecords
    | FetchSucceed (List FileRecord)
    | FetchFail Http.Error


update : Msg -> Model -> ( Model, Cmd Msg )
update action model =
    case action of
        ClickFile fileRecord ->
            ( { model
                | queue = Array.push fileRecord model.queue
              }
            , Cmd.none
            )

        NextSong ->
            let
                shouldReset =
                    ((Array.length model.queue) - 1) <= Debug.log "currentSong" model.currentSong
            in
                let
                    updatedModel =
                        if shouldReset then
                            { model
                                | currentSong = Debug.log "NextSongRESET" 0
                            }
                        else
                            { model
                                | currentSong = Debug.log "NextSong" <| (model.currentSong + 1)
                            }
                in
                    ( updatedModel, Cmd.none )

        FetchFileRecords ->
            ( model, fetchFileRecords )

        FetchSucceed fileRecords ->
            ( { model
                | files = fileRecords
              }
            , Cmd.none
            )

        FetchFail _ ->
            ( model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- HTTP


fetchFileRecords : Cmd Msg
fetchFileRecords =
    let
        url =
            "http://localhost:5000"
    in
        Task.perform FetchFail FetchSucceed (Http.get filesDecoder url)


filesDecoder : Decoder (List FileRecord)
filesDecoder =
    ("files" := JsonD.list decodeFileRecords)


decodeFileRecords : Decoder FileRecord
decodeFileRecords =
    JsonD.object2 FileRecord
        ("path" := JsonD.string)
        ("name" := JsonD.string)



-- VIEW


view : Model -> Html Msg
view model =
    Html.div []
        [ fileView model.files
        , queueView model.queue
        , audioPlayer model
        ]


audioPlayer : Model -> Html Msg
audioPlayer model =
    case Debug.log "new player" (Array.get model.currentSong model.queue) of
        Just fileRecord ->
            let
                srcWithFile =
                    "file://" ++ fileRecord.path
            in
                Html.audio
                    [ Attr.src srcWithFile
                    , Attr.type' "audio/mp3"
                    , Attr.controls True
                    , Attr.autoplay True
                    , Events.on "ended" (JsonD.succeed NextSong)
                    ]
                    []

        Nothing ->
            Html.div [] [ Html.text "------------- \x08\n                                                               -------------- \n Nothing playing" ]


fileView : List FileRecord -> Html Msg
fileView files =
    Html.div [ songList ] <| List.map fileToHtml files


fileToHtml : FileRecord -> Html Msg
fileToHtml file =
    Html.div [ Events.onClick <| ClickFile file ] [ Html.text file.name ]


queueView : Array FileRecord -> Html Msg
queueView files =
    Html.div []
        (List.map (Html.text << .name)
            <| Array.toList files
        )



-- songList : Attribute msg


songList =
    Attr.style
        [ ( "width", "50%" )
        , ( "float", "left" )
        ]
