module Player exposing (..)

import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events
import Http
import Html.App as Html
import Array exposing (Array)
import Dict exposing (Dict)
import String
import Debug
import Navigation
import MyStyle
import Port
import Keyboard
import Char
import Mouse
import Focus
import MyModels exposing (..)
import Window as Win
import Audio
import Queue
import AlbumArt
import SortSongs
import Browser
import Helpers
import ApiHelpers


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
    String.dropLeft 1 url


urlParser : Navigation.Parser String
urlParser =
    Navigation.makeParser (fromUrl << .hash)


init : String -> ( Model, Cmd Msg )
init s =
    ( initialModel, Navigation.newUrl <| toUrl "nothing" )



-- initialModel.rootPath )


initialModel : Model
initialModel =
    { currentSong = 0
    , queue = { array = Array.empty, mouseOver = False, mouseOverItem = 1 }
    , browser = Browser.initialModel
    , albumArt = "nothing"
    , currentMousePos = { x = 0, y = 0 }
    , dragStart = Nothing
    , keysBeingTyped = ""
    , isShiftDown = False
    }

-- UPDATE


type Msg
    = NavigationBack
    | AudioMsg Audio.Msg
    | QueueMsg Queue.Msg
    | BrowserMsg Browser.Msg
    | UpdateSongs (List SongModel)
    | UpdateSongsFail Http.Error
    | UpdateGroups (List GroupModel)
    | KeyUp Keyboard.KeyCode
    | KeyDown Keyboard.KeyCode
    | MouseDowns { x : Int, y : Int }
    | MouseUps { x : Int, y : Int }
    | MouseMoves { x : Int, y : Int }
    | GroupBy String
    | UpdateAlbumArt String
    | TextSearch String
    | DestroyDatabase
    | CreateDatabase
    | ResetKeysBeingTyped String


update : Msg -> Model -> ( Model, Cmd Msg )
update action model =
    case (Debug.log "action " action) of
        KeyUp keyCode ->
            let
                textSearchUpdateHelper code =
                    let
                        cString =
                            String.fromChar <| Char.fromCode code

                        maybefirstMatch =
                            List.head <| List.filter (\( id, item ) -> String.startsWith model.keysBeingTyped (String.toUpper <| Helpers.getItemTitle item)) <| Dict.toList model.browser.items
                    in
                        case maybefirstMatch of
                            Just ( id, groupModel ) ->
                                ( { model
                                    | keysBeingTyped = model.keysBeingTyped ++ cString
                                  }
                                , Port.scrollToElement <| "group-item-" ++ id
                                )

                            Nothing ->
                                ( model, Port.scrollToElement "no-id" )
            in
                case keyCode of
                    37 ->
                        (Audio.previousSong model)

                    39 ->
                        (Audio.nextSong model)

                    32 ->
                        if (String.length model.keysBeingTyped > 0) then
                            textSearchUpdateHelper 32
                        else
                            ( model, Port.pause "null" )

                    16 ->
                        ( { model | isShiftDown = False }, Cmd.none )

                    c ->
                        textSearchUpdateHelper c

        KeyDown keyCode ->
            case keyCode of
                16 ->
                    ( { model | isShiftDown = True }, Cmd.none )

                anythingElse ->
                    ( model, Cmd.none )

        ResetKeysBeingTyped str ->
            ( { model | keysBeingTyped = "" }, Cmd.none )

        NavigationBack ->
            ( model, Navigation.back <| Debug.log "nav back " 1 )

        AudioMsg msg ->
            Audio.update msg model

        QueueMsg msg ->
            let
                ( queue', queueCmd ) =
                    Queue.update msg model.queue
            in
                case queueCmd of
                    Just (Queue.UpdateCurrentSong newSong) ->
                        ( { model
                            | queue = queue'
                            , currentSong = newSong
                          }
                        , Helpers.lookupAlbumArt newSong queue'.array
                        )

                    anythingElse ->
                        ( { model | queue = queue' }, Cmd.none )

        BrowserMsg msg ->
            let
                ( browser', browserCmd ) =
                    Browser.update msg model.isShiftDown model.browser
            in
                case browserCmd of
                    Just (Browser.AddSong item) ->
                        case item.data of
                            Song songModel ->
                                ( { model
                                    | browser = browser'
                                    , queue = fst <| Queue.update (Queue.Drop [ item ] model.currentSong) model.queue
                                  }
                                , Cmd.none
                                )

                            anythingElse ->
                                ( { model | browser = browser' }, Cmd.none )

                    anythingElse ->
                        ( { model | browser = browser' }, Cmd.none )

        UpdateSongs songs ->
            let
                browser =
                    Debug.log "browser" Browser.initialModel

                browser' =
                    { browser | items = Helpers.makeSongItemDictionary songs }
            in
                ( { model
                    | browser =
                        browser'
                  }
                , Cmd.none
                )

        UpdateSongsFail songs ->
            ( model, Cmd.none )

        UpdateGroups groups ->
            let
                browser =
                    Browser.initialModel

                browser' =
                    { browser | items = Helpers.makeGroupItemDictionary groups }
            in
                ( { model
                    | browser =
                        browser'
                  }
                , Cmd.none
                )

        MouseDowns xy ->
            ( { model
                | dragStart =
                    Just <| currentMouseLocation model
              }
            , Cmd.none
            )

        MouseUps xy ->
            let
                maybeDragStart =
                    model.dragStart

                dragEnd =
                    currentMouseLocation model

                model' =
                    { model | dragStart = Nothing }
            in
                case maybeDragStart of
                    Just BrowserWindow ->
                        case dragEnd of
                            QueueWindow ->
                                -- Droping browser items
                                let
                                    itemsToDrop =
                                        model.browser.items
                                            |> Dict.values
                                            |> List.filter .isSelected
                                            |> List.foldl
                                                (\item acc ->
                                                    case item.data of
                                                        Group groupModel ->
                                                            let
                                                                newItems =
                                                                    List.map (\song -> { isSelected = False, isMouseOver = False, data = Song song }) groupModel.songs
                                                            in
                                                                newItems ++ acc

                                                        anythingElse ->
                                                            item :: acc
                                                )
                                                []

                                    ( queue', queueCmd ) =
                                        Queue.update (Queue.Drop itemsToDrop model.currentSong) model.queue
                                in
                                    case queueCmd of
                                        Just (Queue.UpdateCurrentSong newSong) ->
                                            ( { model'
                                                | queue = queue'
                                                , browser = Browser.update Browser.Reset False model.browser |> fst
                                                , currentSong = newSong
                                              }
                                            , Helpers.lookupAlbumArt newSong queue'.array
                                            )

                                        anythingElse ->
                                            ( model', Cmd.none )

                            anythingElse ->
                                ( model', Cmd.none )

                    Just QueueWindow ->
                        case dragEnd of
                            QueueWindow ->
                                -- Reordering songs in the queue
                                let
                                    ( queue', queueCmd ) =
                                        Queue.update (Queue.Reorder model.currentSong) model.queue
                                in
                                    case queueCmd of
                                        Just (Queue.UpdateCurrentSong newSong) ->
                                            ( { model'
                                                | queue = queue'
                                                , currentSong = newSong
                                              }
                                            , Helpers.lookupAlbumArt newSong queue'.array
                                            )

                                        anythingElse ->
                                            ( model, Cmd.none )

                            anythingElse ->
                                -- Removing songs from the queue
                                let
                                    ( queue', queueCmd ) =
                                        Queue.update (Queue.Remove model.currentSong) model.queue
                                in
                                    case queueCmd of
                                        Just (Queue.UpdateCurrentSong newSong) ->
                                            ( { model'
                                                | queue = queue'
                                                , currentSong = newSong
                                              }
                                            , Helpers.lookupAlbumArt newSong queue'.array
                                            )

                                        anythingElse ->
                                            ( model, Cmd.none )

                    anythingElse ->
                        ( model', Cmd.none )

        MouseMoves xy ->
            ( { model
                | currentMousePos = xy
              }
            , Cmd.none
            )

        GroupBy key ->
            case key of
                "song" ->
                    ( model, ApiHelpers.fetchAllSongs UpdateSongsFail UpdateSongs )

                "album" ->
                    ( model, ApiHelpers.fetchAllAlbums UpdateSongsFail UpdateGroups)

                "artist" ->
                    ( model, ApiHelpers.fetchAllArtists UpdateSongsFail UpdateGroups)

                _ ->
                    ( model, Cmd.none )

        UpdateAlbumArt picture ->
            ( { model | albumArt = picture }, Cmd.none )

        TextSearch value ->
            ( model, Port.textSearch value )

        CreateDatabase ->
            ( model, Cmd.none )

        DestroyDatabase ->
            ( model, Cmd.none )


urlUpdate : String -> Model -> ( Model, Cmd Msg )
urlUpdate newPath model =
    ( model, Cmd.none )



-- ( { model | rootPath = newPath }, (Port.groupBy newPath) )


currentMouseLocation : Model -> MouseLocation
currentMouseLocation model =
    if model.browser.isMouseOver then
        BrowserWindow
    else if model.queue.mouseOver then
        QueueWindow
    else
        OtherWindow



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Port.resetKeysBeingTyped ResetKeysBeingTyped
        , Port.updateAlbumArt UpdateAlbumArt
        , Keyboard.ups KeyUp
        , Keyboard.downs KeyDown
        , Mouse.downs MouseDowns
        , Mouse.ups MouseUps
        , Mouse.moves MouseMoves
        ]


view : Model -> Html Msg
view model =
    Html.div [ Attr.id "main-container" ]
        [ Html.div [ Attr.id "banner" ] []
        , audioPlayer model
        , navigationView
        , browserView model
        , queueView model
        , AlbumArt.view model.albumArt
        ]


audioPlayer : Model -> Html Msg
audioPlayer model =
    case (Array.get model.currentSong model.queue.array) of
        Just item ->
            case item.data of
                Song song ->
                    Html.map AudioMsg (Audio.view song.id)

                somthingElse ->
                    Html.map AudioMsg (Audio.view 0) -- This should never happen

        Nothing ->
            Html.div [] []


browserView : Model -> Html Msg
browserView model =
    let
        maybeMousePos =
            case model.dragStart of
                Just BrowserWindow ->
                    Just model.currentMousePos

                anythingElse ->
                    Nothing
    in
        Html.map BrowserMsg (Browser.view maybeMousePos model.browser)


queueView : Model -> Html Msg
queueView model =
    let
        maybeMousePos =
            case model.dragStart of
                Just QueueWindow ->
                    Just model.currentMousePos

                anythingElse ->
                    Nothing
    in
        Html.map QueueMsg (Queue.view maybeMousePos model.currentSong model.queue)


navigationView : Html Msg
navigationView =
    Html.ul [ Attr.id "navigation-view-container" ]
        [ Html.li [ Events.onClick (GroupBy "album") ] [ Html.text "Group By album" ]
        , Html.li [ Events.onClick (GroupBy "artist") ] [ Html.text "Group By artist" ]
        , Html.li [ Events.onClick (GroupBy "song") ] [ Html.text "Group By song" ]
        , Html.input [ Events.onInput TextSearch ] []
        , Html.li [ Events.onClick CreateDatabase ] [ Html.text "Create Database" ]
        , Html.li [ Events.onClick DestroyDatabase ] [ Html.text "Destroy Database" ]
        ]
