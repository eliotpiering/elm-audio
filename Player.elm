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
import MyStyle


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
    , fetchFileRecords "/home/eliot/Music/"
    )



-- MODEL


type alias Model =
    { currentSong : Int
    , files : List FileRecord
    , subDirs : List FileRecord
    , queue : Array FileRecord
    }


type alias FileRecord =
    { path : String
    , name : String
    }


type alias DataModel =
    { files : List FileRecord
    , subDirs : List FileRecord
    }


initialModel : Model
initialModel =
    { currentSong = 0
    , queue = Array.empty
    , files = [ { path = "/home/eliot/Music/Micachu%20and%20the%20Shapes%20-%20Good%20Sad%20Happy%20Bad%20%282015%29%20-%20CD%20V0/10%20Peach.mp3", name = "10 Peach.mp3" } ]
    , subDirs = []
    }



-- UPDATE


type Msg
    = ClickFile FileRecord
    | ClickSubDir FileRecord
    | NextSong
    | PreviousSong
      -- Http stuff
    | FetchFileRecords String
    | FetchSucceed DataModel
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

        ClickSubDir subDir ->
            ( model
            , fetchFileRecords subDir.path
            )

        NextSong ->
            let
                shouldReset =
                    model.currentSong >= (Array.length model.queue) - 1
            in
                let
                    updatedModel =
                        if shouldReset then
                            { model
                                | currentSong =  0
                            }
                        else
                            { model
                                | currentSong = (model.currentSong + 1)
                            }
                in
                    ( updatedModel, Cmd.none )

        PreviousSong ->
            let
                shouldReset =
                    model.currentSong == 0
            in
                let
                    updatedModel =
                        if shouldReset then
                            { model
                                | currentSong = (Array.length model.queue - 1)
                            }
                        else
                            { model
                                | currentSong =(model.currentSong - 1)
                            }
                in
                    ( updatedModel, Cmd.none )

        FetchFileRecords basePath ->
            ( model, fetchFileRecords basePath )

        FetchSucceed dataModel ->
            ( { model
                | files = dataModel.files
                , subDirs = dataModel.subDirs
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


fetchFileRecords : String -> Cmd Msg
fetchFileRecords base =
    let
        url =
            "http://localhost:5000/ls?dir=" ++ base
    in
        Task.perform FetchFail FetchSucceed (Http.get filesDecoder url)


filesDecoder : Decoder DataModel
filesDecoder =
    JsonD.object2 DataModel
        ("files" := JsonD.list decodeFileRecords)
        ("subDirs" := JsonD.list decodeFileRecords)


decodeFileRecords : Decoder FileRecord
decodeFileRecords =
    JsonD.object2 FileRecord
        ("path" := JsonD.string)
        ("name" := JsonD.string)



-- VIEW


view : Model -> Html Msg
view model =
    Html.div []
        [ audioPlayer model
        , fileView model
        , queueView model.queue
        ]


audioPlayer : Model -> Html Msg
audioPlayer model =
    case Debug.log "new player" (Array.get model.currentSong model.queue) of
        Just fileRecord ->
            -- let
            --     srcWithFile =
            --         "file://" ++ fileRecord.path
            -- in
            Html.div [ MyStyle.audioViewContainer ]
                [ previousSongButton
                , Html.audio
                    [ Attr.src fileRecord.path
                    , Attr.type' "audio/mp3"
                    , Attr.controls True
                    , Attr.autoplay True
                    , Events.on "ended" (JsonD.succeed NextSong)
                    ]
                    []
                  , nextSongButton
                ]

        Nothing ->
            Html.div [] [ Html.text "------------- \x08\n                                                               -------------- \n Nothing playing" ]


nextSongButton : Html Msg
nextSongButton =
    Html.div [ Events.onClick <| NextSong ]
        [ Html.text "NEXT -->" ]

previousSongButton : Html Msg
previousSongButton =
    Html.div [ Events.onClick <| PreviousSong ]
        [ Html.text "<-- PREVIOUS" ]


fileView : Model -> Html Msg
fileView model =
    Html.div [ MyStyle.fileViewContainer ]
        [ Html.ul [ MyStyle.songList ] (List.map subDirToHtml model.subDirs)
        , Html.ul [ MyStyle.songList ] (List.map fileToHtml model.files)
        ]


subDirToHtml : FileRecord -> Html Msg
subDirToHtml file =
    Html.li
        [ MyStyle.songItem
        , Events.onClick <| ClickSubDir file
        ]
        [ Html.text file.name ]


fileToHtml : FileRecord -> Html Msg
fileToHtml file =
    Html.li
        [ MyStyle.songItem
        , Events.onClick <| ClickFile file
        ]
        [ Html.text file.name ]


queueView : Array FileRecord -> Html Msg
queueView files =
    Html.div [ MyStyle.queueViewContainer ]
        [ Html.ul [ MyStyle.songList ]
            (List.map fileToHtml
                (Array.toList files)
            )
        ]
