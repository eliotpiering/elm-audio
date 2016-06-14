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
    "#/" ++  (Debug.log "to_url" path)


fromUrl : String -> String
fromUrl url =
    String.dropLeft 1 <| Debug.log "from url " url


urlParser : Navigation.Parser String
urlParser =
    Navigation.makeParser (fromUrl << .hash)


init : String -> ( Model, Cmd Msg )
init s =
  (initialModel, Navigation.newUrl <| toUrl initialModel.rootPath )


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
    case action of
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
            ( model, Navigation.back <| Debug.log "nav back "1 )

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
                | files = dataModel.files
                , subDirs = dataModel.subDirs
              }
            , Cmd.none
            )


urlUpdate : String -> Model -> ( Model, Cmd Msg )
urlUpdate newPath model =
    ( { model | rootPath = Debug.log "new Path --asd " newPath }, Port.newDir newPath )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Port.updateDir UpdateDir



-- VIEW


view : Model -> Html Msg
view model =
    Html.div []
        [ audioPlayer model
        , fileView (model)
        , queueView model.queue
        ]


audioPlayer : Model -> Html Msg
audioPlayer model =
    case (Array.get model.currentSong model.queue) of
        Just fileRecord ->
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
