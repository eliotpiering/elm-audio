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
import Mouse
import Focus
import MyModels exposing (..)
import FileObject
import Window as Win


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
    , rootPath =
        "/home/eliot/Music"
        -- , dropZone = {lowX = Win.width / 2, highX = Win.width, lowY = 0, highY = Win.height }
    , dropZone = { lowX = 400, highX = 800, lowY = 0, highY = 800 }
    }



-- UPDATE


type Msg
    = ClickFile Int FileObject.Msg
    | ClickSubDir FileRecord
    | NavigationBack
    | NextSong
    | PreviousSong
    | UpdateDir DataModel
    | KeyUp Keyboard.KeyCode
    | MouseDowns { x : Int, y : Int }
    | MouseUps { x : Int, y : Int }


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

        ClickFile id msg ->
            let
                newFiles =
                    (List.map
                       (\indexed ->
                          if indexed.id == id
                          then
                            {indexed
                            | fileObject = fst
                              <| FileObject.update msg indexed.fileObject
                            }
                          else
                            indexed
                       ) model.files)
            in
                (( { model | files = newFiles}
                 , Cmd.none
                 )
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
                | files = makeIndexedFileObjects dataModel.files
                , subDirs = dataModel.subDirs
              }
            , Cmd.none
            )

        MouseDowns xy ->
            ( model, Cmd.none )

        MouseUps xy ->
            let
                dz =
                    model.dropZone
            in
                if xy.x > dz.lowX then
                    let
                        toAdd =
                            List.filter (.fileObject >> .isSelected) <| model.files
                        resetFiles =
                            List.map (\indexed -> {indexed | fileObject = FileObject.reset indexed.fileObject }) model.files
                    in
                        ( { model
                            | queue = Array.append model.queue <| Array.fromList toAdd
                            , files = resetFiles
                          }, Cmd.none )
                else
                    ( model, Cmd.none )


makeIndexedFileObjects : List FileRecord -> List IndexedFileObject
makeIndexedFileObjects fileRecords =
    let
        ids =
            generateIdList (List.length fileRecords) []
    in
        List.map2 (\id fileRecord -> { id = id, fileObject = (FileObject.init fileRecord) }) ids fileRecords


generateIdList : Int -> List Int -> List Int
generateIdList len list =
    if len == 0 then
        list
    else
        len :: (generateIdList (len - 1) list)


urlUpdate : String -> Model -> ( Model, Cmd Msg )
urlUpdate newPath model =
    ( { model | rootPath = newPath }, Port.newDir newPath )



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
    Sub.batch
        [ Port.updateDir UpdateDir
        , Keyboard.ups KeyUp
        , Mouse.downs MouseDowns
        , Mouse.ups MouseUps
        ]



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
        Just indexedFileObject ->
            Html.div [ MyStyle.audioViewContainer ]
                [ previousSongButton
                , (Html.div [ MyStyle.floatLeft ]
                    [ Html.audio
                        [ Attr.src indexedFileObject.fileObject.fileRecord.path
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
        , Html.ul [ MyStyle.songList ] (List.map viewFileObject model.files)
        ]


viewFileObject : IndexedFileObject -> Html Msg
viewFileObject { id, fileObject } =
    Html.map (ClickFile id) (FileObject.view fileObject)


directoryNavigationView : Html Msg
directoryNavigationView =
    Html.div [ Events.onClick NavigationBack ] [ Html.mark [ MyStyle.upArrow ] [ Html.text "⇪" ] ]


subDirToHtml : FileRecord -> Html Msg
subDirToHtml file =
    Html.li
        [ MyStyle.songItem False
        , Events.onClick <| ClickSubDir file
        ]
        [ Html.text file.name ]


queueView : Array IndexedFileObject -> Int -> Html Msg
queueView queue currentSong =
    Html.div [ MyStyle.queueViewContainer ]
        [ Html.ul [ MyStyle.songList ]
            <| Array.toList
            <| Array.indexedMap (queueToHtml currentSong) queue
        ]



-- Takes a currentSong, then is mapped with index over the queue


queueToHtml : Int -> Int -> IndexedFileObject -> Html Msg
queueToHtml currentSong i indexedFileObject =
    if (i == currentSong) then
        Html.li
            [ MyStyle.songItem True
            ]
            [ Html.text indexedFileObject.fileObject.fileRecord.name ]
    else
        Html.li
            [ MyStyle.songItem False
            ]
            [ Html.text indexedFileObject.fileObject.fileRecord.name ]
