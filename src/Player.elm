module Player exposing (..)

import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events
import Html.App as Html
import Json.Decode as JsonD exposing (Decoder, (:=))
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
import SortSongs
import Browser
import Helpers


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
    ( initialModel, Navigation.newUrl <| toUrl initialModel.rootPath )


initialModel : Model
initialModel =
    { currentSong = 0
    , queue = { array = Array.empty, mouseOver = False, mouseOverItem = 1 }
    , browser = Browser.initialModel
    , rootPath = "/home/eliot/Music"
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
    | UpdateGroups (List GroupModel)
    | KeyUp Keyboard.KeyCode
    | KeyDown Keyboard.KeyCode
    | MouseDowns { x : Int, y : Int }
    | MouseUps { x : Int, y : Int }
    | MouseMoves { x : Int, y : Int }
    | GroupBy String
    | TextSearch String
    | DestroyDatabase
    | CreateDatabase
    | ResetKeysBeingTyped String


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
                        ( Audio.previousSong model, Cmd.none )

                    39 ->
                        ( Audio.nextSong model, Cmd.none )

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
            let
                nothing =
                    Debug.log "reset keys " str
            in
                ( { model | keysBeingTyped = "" }, Cmd.none )

        NavigationBack ->
            ( model, Navigation.back <| Debug.log "nav back " 1 )

        AudioMsg msg ->
            ( Audio.update msg model, Cmd.none )

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
                        , Cmd.none
                        )

                    anythingElse ->
                        ( { model | queue = queue' }, Cmd.none )

        BrowserMsg msg ->
            let
                ( browser', browserCmd ) =
                    Browser.update msg model.isShiftDown model.browser
            in
                case (Debug.log "browser cmd " browserCmd) of
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
                        ( { model | browser = Debug.log "browsermsg in player " browser' }, Cmd.none )

        UpdateSongs songs ->
            let
                browser =
                    Browser.initialModel

                browser' =
                    { browser | items = Helpers.makeSongItemDictionary songs }
            in
                ( { model
                    | browser =
                        browser'
                  }
                , Cmd.none
                )

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
                                            , Cmd.none
                                            )

                                        anythingElse ->
                                            ( model', Cmd.none )

                            anythingElse ->
                                ( model', Cmd.none )

                    Just QueueWindow ->
                        case Debug.log "drag end" dragEnd of
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
                                            , Cmd.none
                                            )

                                        anythingElse ->
                                            ( model, Cmd.none )

                            anythingElse ->
                                -- Removing songs from the queue
                                let
                                    ( queue', queueCmd ) =
                                        Debug.log "updated queue" <| Queue.update (Queue.Remove model.currentSong) model.queue
                                in
                                    case queueCmd of
                                        Just (Queue.UpdateCurrentSong newSong) ->
                                            ( { model'
                                                | queue = queue'
                                                , currentSong = newSong
                                              }
                                            , Cmd.none
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
            ( model, Port.groupBy key )

        TextSearch value ->
            ( model, Port.textSearch value )

        CreateDatabase ->
            ( model, Port.createDatabase "foo" )

        DestroyDatabase ->
            ( model, Port.destroyDatabase "bar" )


urlUpdate : String -> Model -> ( Model, Cmd Msg )
urlUpdate newPath model =
    ( { model | rootPath = newPath }, (Port.groupBy newPath) )


currentMouseLocation : Model -> MouseLocation
currentMouseLocation model =
    if model.browser.isMouseOver then
        BrowserWindow
    else if Debug.log "is queue mouse over " <| model.queue.mouseOver then
        QueueWindow
    else
        OtherWindow



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Port.updateSongs UpdateSongs
        , Port.updateGroups UpdateGroups
        , Port.resetKeysBeingTyped ResetKeysBeingTyped
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
          -- , albumArtView model
        ]


audioPlayer : Model -> Html Msg
audioPlayer model =
    case (Array.get model.currentSong model.queue.array) of
        Just item ->
            case item.data of
                Song song ->
                    Html.map AudioMsg (Audio.view song.path)

                somthingElse ->
                    Html.map AudioMsg (Audio.view "this should never happen")

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



-- albumArtView : Model -> Html Msg
-- albumArtView model =
--     case (Array.get model.currentSong model.queue.array) of
--         Just indexedSong ->
--             Html.div [ Attr.id "album-art-container" ]
--                 [ Html.img [ Attr.src indexedSong.model.picture ] [] ]
--         Nothing ->
--             Html.div [] [ Html.text "nothing" ]


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
