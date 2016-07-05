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
import FileObject
import Group


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
    , songs = []
    , groups = []
    , rootPath = "/home/eliot/Music"
    , dropZone = 400
    }



-- UPDATE


type Msg
    = ClickFile Int FileObject.Msg
    | ClickGroup Int Group.Msg
    | NavigationBack
    | AudioMsg Audio.Msg
    | UpdateSongs (List FileObjectModel)
    | UpdateGroups (List GroupModel)
    | KeyUp Keyboard.KeyCode
    | MouseDowns { x : Int, y : Int }
    | MouseUps { x : Int, y : Int }
    | SortByAlbum
    | SortByArtist
    | SortByTitle
    | GroupBy String
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
                    Debug.log "clickedGroup" <| List.head
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

        ClickFile id msg ->
            let
                newFiles =
                    (List.map
                        (\indexed ->
                            if indexed.id == id then
                                { indexed
                                    | fileObject =
                                        fst
                                            <| FileObject.update msg indexed.fileObject
                                }
                            else
                                indexed
                        )
                        model.songs
                    )
            in
                (( { model | songs = newFiles }
                 , Cmd.none
                 )
                )

        NavigationBack ->
            ( model, Navigation.back <| Debug.log "nav back " 1 )

        AudioMsg msg ->
            ( Audio.update msg model, Cmd.none )

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
            ( model, Cmd.none )

        MouseUps xy ->
            if xy.x > model.dropZone then
                let
                    toAdd =
                        List.filter (.fileObject >> .isSelected) <| model.songs

                    resetFiles =
                        List.map (\indexed -> { indexed | fileObject = FileObject.reset indexed.fileObject }) model.songs
                in
                    ( { model
                        | queue = Array.append model.queue <| Array.fromList toAdd
                        , songs = resetFiles
                      }
                    , Cmd.none
                    )
            else
                ( model, Cmd.none )

        SortByAlbum ->
            ( model, Port.sortByAlbum "album" )

        SortByArtist ->
            ( model, Port.sortByArtist "artist" )

        SortByTitle ->
            ( model, Port.sortByTitle "title" )

        GroupBy key ->
            ( model, Port.groupBy key )

        CreateDatabase ->
            ( model, Port.createDatabase "foo" )

        DestroyDatabase ->
            ( model, Port.destroyDatabase "bar" )


makeIndexedFileObjects : List FileObjectModel -> List IndexedFileObject
makeIndexedFileObjects fileObjects =
    let
        ids =
            generateIdList (List.length fileObjects) []
    in
        List.map2 IndexedFileObject ids fileObjects


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
    ( { model | rootPath = newPath }, Port.sortByArtist newPath )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Port.updateSongs UpdateSongs
        , Port.updateGroups UpdateGroups
        , Keyboard.ups KeyUp
        , Mouse.downs MouseDowns
        , Mouse.ups MouseUps
        ]



-- VIEW


view : Model -> Html Msg
view model =
    Html.div []
        [ audioPlayer model
        , songView (model)
        , queueView model.queue model.currentSong
        ]


audioPlayer : Model -> Html Msg
audioPlayer model =
    case (Array.get model.currentSong model.queue) of
        Just indexedFileObject ->
            Html.map (AudioMsg) (Audio.view indexedFileObject.fileObject.path)

        Nothing ->
            Html.div [] [ Html.text "-------------------------- \n Nothing playing" ]


songView : Model -> Html Msg
songView model =
    Html.div [ MyStyle.fileViewContainer ]
        [ navigationView
        , Html.ul [ MyStyle.songList ] (List.map viewGroupModel model.groups)
        , Html.ul [ MyStyle.songList ] (List.map viewFileObject model.songs)
        ]


navigationView : Html Msg
navigationView =
    Html.ul []
        [ Html.li [ Events.onClick SortByAlbum ] [ Html.text "By Album" ]
        , Html.li [ Events.onClick SortByArtist ] [ Html.text "By Artist" ]
        , Html.li [ Events.onClick SortByTitle ] [ Html.text "By Song Title" ]
        , Html.li [ Events.onClick (GroupBy "album") ] [ Html.text "Group By album" ]
        , Html.li [ Events.onClick CreateDatabase ] [ Html.text "Create Database" ]
        , Html.li [ Events.onClick DestroyDatabase ] [ Html.text "Destroy Database" ]
        ]


viewFileObject : IndexedFileObject -> Html Msg
viewFileObject { id, fileObject } =
    Html.map (ClickFile id) (FileObject.view fileObject)


viewGroupModel : IndexedGroupModel -> Html Msg
viewGroupModel { id, model } =
    Html.map (ClickGroup id) (Group.view model)


queueView : Array IndexedFileObject -> Int -> Html Msg
queueView queue currentSong =
    Html.div [ MyStyle.queueViewContainer ]
        [ Html.ul [ MyStyle.songList ]
            <| Array.toList
            <| Array.indexedMap (queueToHtml currentSong) queue
        ]


queueToHtml : Int -> Int -> IndexedFileObject -> Html Msg
queueToHtml currentSong i indexedFileObject =
    if (i == currentSong) then
        Html.li
            [ MyStyle.songItem True
            ]
            [ Html.text indexedFileObject.fileObject.title ]
    else
        Html.li
            [ MyStyle.songItem False
            ]
            [ Html.text indexedFileObject.fileObject.title ]
