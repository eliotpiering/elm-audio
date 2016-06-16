module Player exposing (..)

import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events
import Html.App as Html
import Json.Decode as JsonD exposing (Decoder, (:=))
import Array exposing (Array)
import String
import Debug
import Navigation
import MyStyle
import Port
import Keyboard
import Char
import MyModels exposing (..)


main : Program Never
main =
    Navigation.program urlParser
        { init = init
        , view = view
        , update = update
        , urlUpdate = urlUpdate
        , subscriptions = subscriptions
        }


toUrl : String -> String
toUrl path =
    "#/" ++ (Debug.log "to_url" path)


fromUrl : String -> String
fromUrl url =
    String.dropLeft 1 <| Debug.log "from url " url


urlParser : Navigation.Parser String
urlParser =
    Navigation.makeParser (fromUrl << .hash)


init : String -> ( Model, Cmd Msg )
init s =
    ( initialModel, Navigation.newUrl <| toUrl initialModel.rootPath )


initialModel : Model
initialModel =
    { currentSong = 0
    , queue = Array.empty
    , files = []
    , subDirs =
        []
        --   , rootPath = "/media/eliot/TOSHIBA EXT/organized_music/"
    , rootPath = "/home/eliot/Music/"
    }



-- UPDATE


type Msg
    = ClickFile FileRecord
    | ClickSubDir FileRecord
    | NavigationBack
    | NextSong
    | PreviousSong
    | UpdateDir DataModel
    | KeyUp Keyboard.KeyCode


update : Msg -> Model -> ( Model, Cmd Msg )
update action model =
    case action of
        KeyUp keyCode ->
            case keyCode of
                37 ->
                    ( previousSong model, Cmd.none )

                39 ->
                    ( nextSong model, Cmd.none )

                32 ->
                    ( model, Port.pause "null" )

                _ ->
                    ( model, Cmd.none )

        ClickFile fileRecord ->
            ( { model
                | queue = Array.push fileRecord model.queue
              }
            , Cmd.none
            )

        ClickSubDir subDir ->
            ( model
            , Navigation.newUrl <| Debug.log "new url" (toUrl subDir.path)
            )

        NavigationBack ->
            ( model, Navigation.back <| Debug.log "nav back " 1 )

        NextSong ->
            ( nextSong model, Cmd.none )

        PreviousSong ->
            ( previousSong model, Cmd.none )

        UpdateDir dataModel ->
            ( { model
                | files = dataModel.files
                , subDirs = dataModel.subDirs
              }
            , Cmd.none
            )


urlUpdate : String -> Model -> ( Model, Cmd Msg )
urlUpdate newPath model =
    ( { model | rootPath = Debug.log "new Path --asd " newPath }, Port.newDir newPath )



-- Helpers


nextSong : Model -> Model
nextSong model =
    let
        shouldReset =
            model.currentSong >= (Array.length model.queue) - 1
    in
        if shouldReset then
            { model
                | currentSong = 0
            }
        else
            { model
                | currentSong = (model.currentSong + 1)
            }


previousSong : Model -> Model
previousSong model =
    let
        shouldReset =
            model.currentSong == 0
    in
        if shouldReset then
            { model
                | currentSong = (Array.length model.queue - 1)
            }
        else
            { model
                | currentSong = (model.currentSong - 1)
            }



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch [ Port.updateDir UpdateDir, Keyboard.ups KeyUp ]



-- VIEW


view : Model -> Html Msg
view model =
    Html.div []
        [ audioPlayer model
        , fileView (model)
        , queueView model.queue model.currentSong
        ]


audioPlayer : Model -> Html Msg
audioPlayer model =
    case (Array.get model.currentSong model.queue) of
        Just fileRecord ->
            Html.div [ MyStyle.audioViewContainer ]
                [ previousSongButton
                , (Html.div [ MyStyle.floatLeft ]
                    [ Html.audio
                        [ Attr.src fileRecord.path
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

        Nothing ->
            Html.div [] [ Html.text "------------- \x08\n                                                               -------------- \n Nothing playing" ]


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


queueView : Array FileRecord -> Int -> Html Msg
queueView queue currentSong =
    Html.div [ MyStyle.queueViewContainer ]
        [ Html.ul [ MyStyle.songList ]
            <| Array.toList
            <| Array.indexedMap (queueToHtml currentSong) queue
        ]



-- Takes a currentSong, then is mapped with index over the queue


queueToHtml : Int -> Int -> FileRecord -> Html Msg
queueToHtml currentSong i file =
    if (i == currentSong) then
        Html.li
            [ MyStyle.songItem
            , Events.onClick <| ClickFile file
            , MyStyle.currentSong
            ]
            [ Html.text file.name ]
    else
        Html.li
            [ MyStyle.songItem
            , Events.onClick <| ClickFile file
            ]
            [ Html.text file.name ]
