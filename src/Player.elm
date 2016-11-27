module Player exposing (..)

import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events
import Http
import Array exposing (Array)
import Dict exposing (Dict)
import String
import Debug
import Port
import Keyboard
import Char
import Mouse
import MyModels exposing (..)
import Audio
import Queue
import AlbumArt
import Browser
import Helpers
import ApiHelpers
import Navigation exposing (Location)
import UrlParser
import NavigationParser exposing (..)


main : Program Never Model Msg
main =
    Navigation.program
        UrlUpdate
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


init : Location -> ( Model, Cmd Msg )
init location =
    ( initialModel, Cmd.none )


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
    = AudioMsg Audio.Msg
    | QueueMsg Queue.Msg
    | BrowserMsg Browser.Msg
    | UpdateSongs (Result Http.Error (List SongModel))
    | AddSongsToQueue (Result Http.Error (List SongModel))
    | AddSongToQueue (Result Http.Error SongModel)
    | OpenSongsInBrowser (Result Http.Error (List SongModel))
    | UpdateGroups (Result Http.Error (List GroupModel))
    | KeyUp Keyboard.KeyCode
    | KeyDown Keyboard.KeyCode
    | MouseDowns { x : Int, y : Int }
    | MouseUps { x : Int, y : Int }
    | MouseMoves { x : Int, y : Int }
    | GroupBy String
    | UpdateAlbumArt String
    | TextSearch String
    | ResetKeysBeingTyped String
    | UrlUpdate Location


update : Msg -> Model -> ( Model, Cmd Msg )
update action model =
    case action of
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

        AudioMsg msg ->
            Audio.update msg model

        QueueMsg msg ->
            let
                ( queue_, queueCmd ) =
                    Queue.update msg model.queue
            in
                case queueCmd of
                    Just (Queue.UpdateCurrentSong newSong) ->
                        ( { model
                            | queue = queue_
                            , currentSong = newSong
                          }
                        , Helpers.lookupAlbumArt newSong queue_.array
                        )

                    anythingElse ->
                        ( { model | queue = queue_ }, Cmd.none )

        BrowserMsg msg ->
            let
                ( browser_, browserCmd ) =
                    Browser.update msg model.isShiftDown model.browser
            in
                case browserCmd of
                    Just (Browser.AddSong item) ->
                        case item.data of
                            Song songModel ->
                                ( { model
                                    | browser = browser_
                                    , queue = Tuple.first <| Queue.update (Queue.Drop [ item ] model.currentSong) model.queue
                                  }
                                , Cmd.none
                                )

                            anythingElse ->
                                ( { model | browser = browser_ }, Cmd.none )

                    Just (Browser.OpenGroup itemModel) ->
                        let
                            model_ =
                                { model | browser = browser_ }
                        in
                            case itemModel.data of
                                Song songModel ->
                                    ( model_, Cmd.none )

                                Group groupModel ->
                                        ( model_, Navigation.newUrl <| "#" ++ groupModel.kind ++ "/" ++ (toString groupModel.id) )

                    anythingElse ->
                        ( { model | browser = browser_ }, Cmd.none )

        UpdateSongs (Ok songs) ->
            let
                browser =
                    Debug.log "browser" Browser.initialModel

                browser_ =
                    { browser | items = Helpers.makeSongItemDictionary songs }
            in
                ( { model
                    | browser =
                        browser_
                  }
                , Cmd.none
                )

        UpdateSongs (Err _) ->
            ( model, Cmd.none )

        UpdateGroups (Ok groups) ->
            let
                browser =
                    Browser.initialModel

                browser_ =
                    Debug.log "new browser" <|
                        { browser | items = Helpers.makeGroupItemDictionary groups }
            in
                ( { model
                    | browser =
                        browser_
                  }
                , Cmd.none
                )

        UpdateGroups (Err ok) ->
            ( model, Cmd.none )

        AddSongsToQueue (Ok songs) ->
            let
                newItems =
                    Helpers.makeSongItemList songs

                model_ =
                    { model | dragStart = Nothing }

                ( queue_, queueCmd ) =
                    Queue.update (Queue.Drop newItems model.currentSong) model_.queue
            in
                case queueCmd of
                    Just (Queue.UpdateCurrentSong newSong) ->
                        ( { model_
                            | queue = queue_
                            , browser = Browser.update Browser.Reset False model.browser |> Tuple.first
                            , currentSong = newSong
                          }
                        , Helpers.lookupAlbumArt newSong queue_.array
                        )

                    anythingElse ->
                        ( model_, Cmd.none )

        AddSongsToQueue (Err _) ->
            ( model, Cmd.none )

        AddSongToQueue (Ok song) ->
            let
                newItems =
                    Debug.log "new itenm " <|
                        Helpers.makeSongItemList [ song ]

                model_ =
                    { model | dragStart = Nothing }

                ( queue_, queueCmd ) =
                    Queue.update (Queue.Drop newItems model.currentSong) model_.queue
            in
                case queueCmd of
                    Just (Queue.UpdateCurrentSong newSong) ->
                        ( { model_
                            | queue = queue_
                            , browser = Browser.update Browser.Reset False model.browser |> Tuple.first
                            , currentSong = newSong
                          }
                        , Helpers.lookupAlbumArt newSong queue_.array
                        )

                    anythingElse ->
                        ( model_, Cmd.none )

        AddSongToQueue (Err _) ->
            ( model, Cmd.none )

        OpenSongsInBrowser (Ok songs) ->
            let
                newItems =
                    Helpers.makeSongItemDictionary songs

                model_ =
                    { model | dragStart = Nothing }

                ( browser_, browserCmd ) =
                    Browser.update (Browser.UpdateSongs newItems) model.isShiftDown model_.browser
            in
                ( { model_ | browser = browser_ }, Cmd.none )

        OpenSongsInBrowser (Err _) ->
            ( model, Cmd.none )

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

                model_ =
                    { model | dragStart = Nothing }
            in
                case maybeDragStart of
                    Just BrowserWindow ->
                        case dragEnd of
                            QueueWindow ->
                                -- Droping browser items into the Queue
                                let
                                    currentQueueIndex =
                                        model.currentSong

                                    selectedGroupItems =
                                        model.browser.items |> Dict.values |> List.filter .isSelected |> List.filter (not << Helpers.isSong)

                                    updateGroupCmds =
                                        Cmd.batch (ApiHelpers.fetchSongsFromGroups selectedGroupItems AddSongsToQueue)

                                    selectedSongItems =
                                        model.browser.items |> Dict.values |> List.filter .isSelected |> List.filter Helpers.isSong

                                    ( queue_, queueCmd ) =
                                        Queue.update (Queue.Drop selectedSongItems model.currentSong) model.queue

                                    ( browser_, _ ) =
                                        Browser.update Browser.Reset False model.browser
                                in
                                    case queueCmd of
                                        Just (Queue.UpdateCurrentSong newSong) ->
                                            ( { model_
                                                | queue = queue_
                                                , browser = browser_
                                                , currentSong = newSong
                                              }
                                            , updateGroupCmds
                                            )

                                        anythingElse ->
                                            ( { model_
                                                | queue = queue_
                                                , browser = browser_
                                              }
                                            , updateGroupCmds
                                            )

                            anythingElse ->
                                ( model_, Cmd.none )

                    Just QueueWindow ->
                        case dragEnd of
                            QueueWindow ->
                                -- Reordering songs in the queue
                                let
                                    ( queue_, queueCmd ) =
                                        Queue.update (Queue.Reorder model.currentSong) model.queue
                                in
                                    case queueCmd of
                                        Just (Queue.UpdateCurrentSong newSong) ->
                                            ( { model_
                                                | queue = queue_
                                                , currentSong = newSong
                                              }
                                            , Helpers.lookupAlbumArt newSong queue_.array
                                            )

                                        anythingElse ->
                                            ( model, Cmd.none )

                            anythingElse ->
                                -- Removing songs from the queue
                                let
                                    ( queue_, queueCmd ) =
                                        Queue.update (Queue.Remove model.currentSong) model.queue
                                in
                                    case queueCmd of
                                        Just (Queue.UpdateCurrentSong newSong) ->
                                            ( { model_
                                                | queue = queue_
                                                , currentSong = newSong
                                              }
                                            , Helpers.lookupAlbumArt newSong queue_.array
                                            )

                                        anythingElse ->
                                            ( model, Cmd.none )

                    anythingElse ->
                        ( model_, Cmd.none )

        MouseMoves xy ->
            ( { model
                | currentMousePos = xy
              }
            , Cmd.none
            )

        GroupBy key ->
            case key of
                "song" ->
                    ( model, Navigation.newUrl "#songs" )

                "album" ->
                    ( model, Navigation.newUrl "#albums" )

                "artist" ->
                    ( model, Navigation.newUrl "#artists" )

                _ ->
                    ( model, Cmd.none )

        UpdateAlbumArt picture ->
            ( { model | albumArt = picture }, Cmd.none )

        TextSearch value ->
            ( model, Port.textSearch value )

        UrlUpdate location ->
            case urlParser location of
                ArtistsRoute ->
                    ( model, ApiHelpers.fetchAllArtists UpdateGroups )

                AlbumsRoute ->
                    ( model, ApiHelpers.fetchAllAlbums UpdateGroups )

                SongsRoute ->
                    ( model, ApiHelpers.fetchAllSongs UpdateSongs )

                ArtistRoute id ->
                    ( model, ApiHelpers.fetchSongsFromArtist id OpenSongsInBrowser)

                AlbumRoute id ->
                    ( model, ApiHelpers.fetchSongsFromAlbum id OpenSongsInBrowser)

                NotFoundRoute ->
                    ( model, Cmd.none )


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
                    Html.map AudioMsg (Audio.view 0)

        -- This should never happen
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
        ]
