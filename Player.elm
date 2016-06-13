module Player exposing (..)

import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events
import Html.App as Html
import Json.Decode as JsonD exposing (Decoder, (:=))
import Array exposing (Array)
import Debug
import Navigation
import MyStyle
import Port
import MyModels exposing (..)


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
    , Port.newDir initialModel.rootPath
    )


initialModel : Model
initialModel =
    { currentSong = 0
    , queue = Array.empty
    , files = []
    , subDirs = []
    , rootPath = "/home/eliot/Music"
    }



-- UPDATE


type Msg
    = ClickFile FileRecord
    | ClickSubDir FileRecord
    | NavigationBack
    | NextSong
    | PreviousSong
    | UpdateDir DataModel


update : Msg -> Model -> ( Model, Cmd Msg )
update action model =
    case Debug.log "action " action of
        ClickFile fileRecord ->
            ( { model
                | queue = Array.push fileRecord model.queue
              }
            , Cmd.none
            )

        ClickSubDir subDir ->
            ( { model | rootPath = subDir.path }
            , Port.newDir subDir.path
            )

        NavigationBack ->
            ( model, Navigation.back 1 )

        NextSong ->
            let
                shouldReset =
                    model.currentSong >= (Array.length model.queue) - 1
            in
                let
                    updatedModel =
                        if shouldReset then
                            { model
                                | currentSong = 0
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
                                | currentSong = (model.currentSong - 1)
                            }
                in
                    ( updatedModel, Cmd.none )

        UpdateDir dataModel ->
            ( { model
                | files = Debug.log "new file " dataModel.files
                , subDirs = Debug.log "new sub Dirs " dataModel.subDirs
              }
            , Navigation.newUrl model.rootPath
            )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Port.updateDir UpdateDir



-- VIEW


view : Model -> Html Msg
view model =
    Html.div []
        [ audioPlayer model
        , fileView (Debug.log "view" model)
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
        [ directoryNavigationView
        , Html.ul [ MyStyle.songList ] (List.map subDirToHtml model.subDirs)
        , Html.ul [ MyStyle.songList ] (List.map fileToHtml model.files)
        ]


directoryNavigationView : Html Msg
directoryNavigationView =
    Html.div [ Events.onClick NavigationBack ] [ Html.text ".. Back" ]


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
