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


-- import Song
-- import Group

import Queue


-- import QueueSong

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
    , isDragging = False
    , keysBeingTyped = ""
    , isShiftDown = False
    }



-- UPDATE


type
    Msg
    -- = SongMsg Int Song.Msg
    -- = GroupMsg String Group.Msg
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

        -- GroupMsg id msg ->
        --   (model, Cmd.none)
        -- let
        --     clickedGroup =
        --         Dict.get id model.groups
        -- in
        --     case Dict.get id model.groups of
        --         Just groupModel ->
        --             case msg of
        --                 Group.OpenGroup ->
        --                     ( { model
        --                         | songs = Helpers.makeSongItemDictionary groupModel.songs
        --                         , groups = Dict.empty
        --                       }
        --                     , Cmd.none
        --                     )
        --                 Group.SelectGroup ->
        --                     let updatedGroups =
        --                           if model.isShiftDown then
        --                            model.groups
        --                           else
        --                             Dict.map (\id gm -> Group.reset gm) model.groups
        --                     in
        --                       ( { model
        --                           | groups = Dict.insert id (Group.update msg groupModel) updatedGroups
        --                         }
        --                       , Cmd.none
        --                       )
        --         Nothing ->
        --             ( model, Cmd.none )
        -- SongMsg id msg ->
        --     let
        --         newSongs = model.browser.items
        --             -- (List.map
        --             --     (\indexed ->
        --             --         if indexed.id == id then
        --             --             { indexed
        --             --                 | model =
        --             --                     fst
        --             --                         <| Song.update msg indexed.model
        --             --             }
        --             --         else
        --             --             indexed
        --             --     )
        --             --     model.songs
        --             -- )
        --     in
        --         ( { model | items = newSongs }
        --         , Cmd.none
        --         )
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
                  }, Cmd.none )
              anythingElse ->
                ( { model | queue = queue'}, Cmd.none )

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
                                    , queue = fst <| Queue.update (Queue.Drop [ item ]) model.queue
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
                    Browser.initialModel

                browser' =
                    { browser | items = Helpers.makeSongItemDictionary songs }
            in
                ( { model
                    | browser =
                        browser'
                        -- , groups = Dict.empty
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
                        -- , songs = Dict.empty
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
            if model.queue.mouseOver then
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
                in
                    ( { model
                        | queue = fst <| Queue.update (Queue.Drop itemsToDrop) model.queue
                        , browser = Browser.update Browser.Reset False model.browser |> fst
                            -- Helpers.makeGroupItemDictionary <| Item.update Item.Reset model.items
                        , isDragging = False
                      }
                    , Cmd.none
                    )
            else
                ( model, Cmd.none )

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
        , songView model
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


songView : Model -> Html Msg
songView model =
    let
        maybeMousePos =
            if model.isDragging then
                Just model.currentMousePos
            else
                Nothing
    in
        Html.map BrowserMsg (Browser.view maybeMousePos model.browser)



-- Html.div [ Attr.id "file-view-container", Attr.class "scroll-box" ]
--     [ Html.ul [] (List.map viewGroupModel <| List.sortBy (snd >> .title) comparable -> v -> Dict comparable v<| Dict.toList model.groups)
--     , Html.table []
--         ([ Html.thead []
--             [ Html.tr [] [ Html.td [] [ Html.text "Title" ], Html.td [] [ Html.text "Artist" ], Html.td [] [ Html.text "Album" ] ]
--             ]
--          ]
--             ++ (List.map (viewFileObject model.currentMousePos) <| SortSongs.byIndexedAlbumAndTrack model.songs)
--         )
--     ]


queueView : Model -> Html Msg
queueView model =
    let
        maybeMousePos =
            if model.isDragging then
                Just model.currentMousePos
            else
                Nothing
    in
        Html.map QueueMsg (Queue.view maybeMousePos model.currentSong model.queue.array)



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



-- viewFileObject : { x : Int, y : Int } -> IndexedSongModel -> Html Msg
-- viewFileObject dragPos { id, model } =
--     Html.map (SongMsg id) (Song.view model dragPos)
-- viewGroupModel : ( String, GroupModel ) -> Html Msg
-- viewGroupModel ( id, model ) =
--     Html.map (GroupMsg id) (Group.view model id)
