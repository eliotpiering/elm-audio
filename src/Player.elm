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
import Song
import Group
import Queue
import QueueSong
import SortSongs


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
    , songs = []
    , groups = Dict.empty
    , rootPath = "/home/eliot/Music"
    , currentMousePos = { x = 0, y = 0 }
    , isDragging = False
    , keysBeingTyped = ""
    , isShiftDown = False
    }



-- UPDATE


type Msg
    = SongMsg Int Song.Msg
    | GroupMsg String Group.Msg
    | NavigationBack
    | AudioMsg Audio.Msg
    | QueueMsg Queue.Msg
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

                        str =
                            Debug.log "str is " <| model.keysBeingTyped ++ cString

                        -- getGroupModelTitle =
                        --     .model >> .title
                        maybefirstMatch =
                            List.head <| List.filter (\( id, gm ) -> String.startsWith str (String.toUpper <| gm.title)) <| Dict.toList model.groups
                    in
                        case maybefirstMatch of
                            Just ( id, groupModel ) ->
                                ( { model
                                    | keysBeingTyped = model.keysBeingTyped ++ cString
                                  }
                                , Port.scrollToElement <| "group-model-" ++ id
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
                      ({model | isShiftDown = False}, Cmd.none)

                    c ->
                        textSearchUpdateHelper c

        KeyDown keyCode ->
          case keyCode of
            16 ->
              ({ model | isShiftDown = True }, Cmd.none)
            anythingElse ->
              (model, Cmd.none)

        ResetKeysBeingTyped str ->
            let
                nothing =
                    Debug.log "reset keys " str
            in
                ( { model | keysBeingTyped = "" }, Cmd.none )

        GroupMsg id msg ->
            let
                clickedGroup =
                    Dict.get id model.groups
            in
                case Dict.get id model.groups of
                    Just groupModel ->
                        case msg of
                            Group.OpenGroup ->
                                ( { model
                                    | songs = makeIndexedFileObjects groupModel.songs
                                    , groups = Dict.empty
                                  }
                                , Cmd.none
                                )

                            Group.SelectGroup ->
                                let updatedGroups =
                                      if model.isShiftDown then
                                       model.groups
                                      else
                                        Dict.map (\id gm -> Group.reset gm) model.groups
                                in
                                  ( { model
                                      | groups = Dict.insert id (Group.update msg groupModel) updatedGroups
                                    }
                                  , Cmd.none
                                  )

                    Nothing ->
                        ( model, Cmd.none )

        SongMsg id msg ->
            let
                newSongs =
                    (List.map
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
          case (Debug.log "which msg " msg) of
            Queue.SongMsg queueNumber QueueSong.SetCurrentSong ->
              ({model | currentSong = queueNumber}, Cmd.none)
            otherMessages ->
              ( { model | queue = Queue.update msg model.queue }, Cmd.none )

        UpdateSongs songs ->
            ( { model
                | songs = makeIndexedFileObjects songs
                , groups = Dict.empty
              }
            , Cmd.none
            )

        UpdateGroups groups ->
            ( { model
                | groups = makeGroupDictionary groups
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
                , groups = if model.queue.mouseOver then
                             Dict.map (\id group-> Group.reset group) model.groups
                           else
                             model.groups
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


makeGroupDictionary : List GroupModel -> Dict String GroupModel
makeGroupDictionary groups =
    let
        ids =
            List.map toString <| generateIdList (List.length groups) []

        pairs =
            List.map2 (,) ids groups
    in
        List.foldl (\( id, group ) dict -> Dict.insert id group dict) Dict.empty pairs


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
        , Port.resetKeysBeingTyped ResetKeysBeingTyped
        , Keyboard.ups KeyUp
        , Keyboard.downs KeyDown
        , Mouse.downs MouseDowns
        , Mouse.ups MouseUps
        , Mouse.moves MouseMoves
        ]



-- VIEW


view : Model -> Html Msg
view model =
    Html.div [ Attr.id "main-container" ]
        [ audioPlayer model
        , navigationView
        , songView model
        , queueView model
        -- , albumArtView model
        ]


audioPlayer : Model -> Html Msg
audioPlayer model =
    case (Array.get model.currentSong model.queue.array) of
        Just indexedFileObject ->
            Html.map AudioMsg (Audio.view indexedFileObject.model.path)

        Nothing ->
            Html.div [] []


songView : Model -> Html Msg
songView model =
    Html.div [ Attr.id "file-view-container", Attr.class "scroll-box" ]
        [ Html.ul [] (List.map viewGroupModel <| List.sortBy (snd >> .title) <| Dict.toList model.groups)
        , Html.table []
            ([ Html.thead []
                [ Html.tr [] [ Html.td [] [ Html.text "Title" ], Html.td [] [ Html.text "Artist" ], Html.td [] [ Html.text "Album" ] ]
                ]
             ]
                ++ (List.map (viewFileObject model.currentMousePos) <| SortSongs.byIndexedAlbumAndTrack model.songs)
            )
        ]


queueView : Model -> Html Msg
queueView model =
    Html.map QueueMsg (Queue.view model)


albumArtView : Model -> Html Msg
albumArtView model =
    case (Array.get model.currentSong model.queue.array) of
        Just indexedSong ->
            Html.div [ Attr.id "album-art-container" ]
                [ Html.img [ Attr.src indexedSong.model.picture ] [] ]

        Nothing ->
            Html.div [] [ Html.text "nothing" ]


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


viewFileObject : { x : Int, y : Int } -> IndexedSongModel -> Html Msg
viewFileObject dragPos { id, model } =
    Html.map (SongMsg id) (Song.view model dragPos)


viewGroupModel : ( String, GroupModel ) -> Html Msg
viewGroupModel ( id, model ) =
    Html.map (GroupMsg id) (Group.view model id)
