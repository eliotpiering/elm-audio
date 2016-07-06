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
import Window as Win
import Audio
import Song
import Group
import Queue


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
    , queue = { array = Array.empty, mouseOver = False }
    , songs = []
    , groups = []
    , rootPath = "/home/eliot/Music"
    , currentMousePos = { x = 0, y = 0 }
    , isDragging = False
    }



-- UPDATE


type Msg
    = SongMsg Int Song.Msg
    | ClickGroup Int Group.Msg
    | NavigationBack
    | AudioMsg Audio.Msg
    | QueueMsg Queue.Msg
    | UpdateSongs (List SongModel)
    | UpdateGroups (List GroupModel)
    | KeyUp Keyboard.KeyCode
    | MouseDowns { x : Int, y : Int }
    | MouseUps { x : Int, y : Int }
    | MouseMoves { x : Int, y : Int }
    | GroupBy String
    | TextSearch String
    | DestroyDatabase
    | CreateDatabase


update : Msg -> Model -> ( Model, Cmd Msg )
update action model =
    case action of
        KeyUp keyCode ->
            case keyCode of
                37 ->
                    ( Audio.previousSong model, Cmd.none )

                39 ->
                    ( Audio.nextSong model, Cmd.none )

                32 ->
                    ( model, Port.pause "null" )

                _ ->
                    ( model, Cmd.none )

        ClickGroup id msg ->
            let
                clickedGroup =
                    Debug.log "clickedGroup"
                        <| List.head
                        <| List.filter (\indexedGroup -> indexedGroup.id == id) model.groups
            in
                case clickedGroup of
                    Just indexedGroupModel ->
                        ( { model
                            | songs = makeIndexedFileObjects indexedGroupModel.model.songs
                            , groups = []
                          }
                        , Cmd.none
                        )

                    Nothing ->
                        ( model, Cmd.none )

        SongMsg id msg ->
            let
                newSongs =
                    Debug.log "new Songs "
                        <| (List.map
                                (\indexed ->
                                    if indexed.id == id then
                                        { indexed
                                            | model =
                                                fst
                                                    <| Song.update msg indexed.model
                                        }
                                    else
                                        indexed
                                )
                                model.songs
                           )
            in
                ( { model | songs = newSongs }
                , Cmd.none
                )

        NavigationBack ->
            ( model, Navigation.back <| Debug.log "nav back " 1 )

        AudioMsg msg ->
            ( Audio.update msg model, Cmd.none )

        QueueMsg msg ->
            ( { model | queue = Queue.update msg model.queue }, Cmd.none )

        UpdateSongs songs ->
            ( { model
                | songs = makeIndexedFileObjects songs
                , groups = []
              }
            , Cmd.none
            )

        UpdateGroups groups ->
            ( { model
                | groups = makeIndexedGroupModels groups
                , songs = []
              }
            , Cmd.none
            )

        MouseDowns xy ->
            ( { model
                | isDragging = True
              }
            , Cmd.none
            )

        MouseUps xy ->
            ( { model
                | queue = Queue.drop model
                , songs = List.map (\indexed -> { indexed | model = Song.reset indexed.model }) model.songs
                , isDragging = False
              }
            , Cmd.none
            )

        MouseMoves xy ->
            ( { model
                | currentMousePos = xy
              }
            , Cmd.none
            )

        GroupBy key ->
            ( model, Port.groupBy key )

        TextSearch value ->
            ( model, Port.textSearch value )

        CreateDatabase ->
            ( model, Port.createDatabase "foo" )

        DestroyDatabase ->
            ( model, Port.destroyDatabase "bar" )


makeIndexedFileObjects : List SongModel -> List IndexedSongModel
makeIndexedFileObjects fileObjects =
    let
        ids =
            generateIdList (List.length fileObjects) []
    in
        List.map2 IndexedSongModel ids fileObjects


makeIndexedGroupModels : List GroupModel -> List IndexedGroupModel
makeIndexedGroupModels groups =
    let
        ids =
            generateIdList (List.length groups) []
    in
        List.map2 IndexedGroupModel ids groups


generateIdList : Int -> List Int -> List Int
generateIdList len list =
    if len == 0 then
        list
    else
        len :: (generateIdList (len - 1) list)


urlUpdate : String -> Model -> ( Model, Cmd Msg )
urlUpdate newPath model =
    ( { model | rootPath = newPath }, (Port.groupBy newPath) )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Port.updateSongs UpdateSongs
        , Port.updateGroups UpdateGroups
        , Keyboard.ups KeyUp
        , Mouse.downs MouseDowns
        , Mouse.ups MouseUps
        , Mouse.moves MouseMoves
        ]



-- VIEW


view : Model -> Html Msg
view model =
    Html.div [MyStyle.playerContainer]
        [ audioPlayer model
        , songView model
        , queueView model
        ]


audioPlayer : Model -> Html Msg
audioPlayer model =
    case (Array.get model.currentSong model.queue.array) of
        Just indexedFileObject ->
            Html.map AudioMsg (Audio.view indexedFileObject.model.path)

        Nothing ->
            Html.div [] [ Html.text "------------------------ Nothing playing" ]


songView : Model -> Html Msg
songView model =
    Html.div [ MyStyle.fileViewContainer ]
        [ navigationView
        , Html.ul [ MyStyle.songList ] (List.map viewGroupModel model.groups)
        , Html.ul [ MyStyle.songList ] (List.map (viewFileObject model.currentMousePos) model.songs)
        ]


queueView : Model -> Html Msg
queueView model =
    Html.map QueueMsg (Queue.view model.queue model.currentSong model.isDragging)


navigationView : Html Msg
navigationView =
    Html.ul []
        [ Html.li [ Events.onClick (GroupBy "album") ] [ Html.text "Group By album" ]
        , Html.li [ Events.onClick (GroupBy "artist") ] [ Html.text "Group By artist" ]
        , Html.li [ Events.onClick (GroupBy "song") ] [ Html.text "Group By song" ]
        , Html.input [ Events.onInput TextSearch ] []
        , Html.li [ Events.onClick CreateDatabase ] [ Html.text "Create Database" ]
        , Html.li [ Events.onClick DestroyDatabase ] [ Html.text "Destroy Database" ]
        ]


viewFileObject : { x : Int, y : Int } -> IndexedSongModel -> Html Msg
viewFileObject dragPos { id, model } =
    Html.map (SongMsg id) (Song.view model dragPos)


viewGroupModel : IndexedGroupModel -> Html Msg
viewGroupModel { id, model } =
    Html.map (ClickGroup id) (Group.view model)
