module Queue exposing (..)

-- (view, update, Msg, drop)

import Html exposing (Html)
import Html.Events as Events
import Html.Attributes as Attr
import Html.App as Html
import MyModels exposing (..)
import MyStyle exposing (..)
import Array exposing (Array)


-- import QueueSong

import SortSongs
import Dict exposing (Dict)
import Item


-- type alias ParentModel =
--     Model


type Msg
    = MouseEnter
    | MouseLeave
    | ItemMsg Int Item.Msg
      -- | SongMsg Int QueueSong.Msg
    | Drop (List ItemModel)


type alias Pos =
    { x : Int, y : Int }


type QueueCmd
    = UpdateCurrentSong Int


update : Msg -> QueueModel -> ( QueueModel, Maybe QueueCmd )
update msg model =
    case msg of
        MouseEnter ->
            ( { model | mouseOver = True }, Nothing )

        MouseLeave ->
            ( { model | mouseOver = False }, Nothing )

        -- SongMsg id msg ->
        --   model
        -- let
        --     updatedQueueSongsWithProps =
        --         (Array.map
        --             (\indexed ->
        --                 if indexed.id == id then
        --                     let
        --                         ( newModel, maybeMouseOverItemId ) =
        --                             QueueSong.update msg indexed.model
        --                     in
        --                         case maybeMouseOverItemId of
        --                             Just _ ->
        --                                 ( { indexed
        --                                     | model = newModel
        --                                   }
        --                                 , Just id
        --                                 )
        --                             Nothing ->
        --                                 ( { indexed
        --                                     | model = newModel
        --                                   }
        --                                 , Nothing
        --                                 )
        --                 else
        --                     ( indexed, Nothing )
        --             )
        --             model.array
        --         )
        -- in
        --     { model
        --         | array = Array.map fst updatedQueueSongsWithProps
        --         , mouseOverItem = Maybe.withDefault (Array.length model.array) <| Maybe.oneOf <| Array.toList <| Array.map snd updatedQueueSongsWithProps
        --     }
        ItemMsg id msg ->
            case Array.get id model.array of
                Just item ->
                    let
                        ( item', itemCmd ) =
                            Item.update msg item

                        model' =
                            { model | array = Array.set id item' model.array }
                    in
                        case itemCmd of
                            Just (Item.MouseEntered) ->
                                ( { model' | mouseOverItem = id }, Nothing )

                            Just (Item.DoubleClicked) ->
                                ( model', Just <| UpdateCurrentSong id )

                            anythingElse ->
                                ( model', Nothing )

                Nothing ->
                    ( model, Nothing )

        Drop newItems ->
            -- if model.mouseOver then
            -- let
            --     newItems =
            --         getNewItemsparentModel.songs) (getNewGroupsToAdd parentModel.groups)
            --     -- reorderedQueueSongs =
            --     --     Array.filter (.model >> .isDragging) queueModel.array
            --     -- queueSongsNotDragging =
            --     --     Array.filter (.model >> .isDragging >> not) queueModel.array
            let
                left =
                    Array.slice 0 (Debug.log "mouse over item " model.mouseOverItem) model.array

                right =
                    Array.slice model.mouseOverItem (Array.length model.array) model.array

                newArrayItems =
                    Array.fromList <| SortSongs.byAlbumAndTrack newItems
            in
                ( { model
                    | array =
                        resetQueue
                            <| Array.append left
                            <| Array.append newArrayItems right
                  }
                , Nothing
                )



-- else
--   model


resetQueue : Array ItemModel -> Array ItemModel
resetQueue =
    Array.map (Item.update Item.Reset >> fst)



-- drop : ParentModel -> QueueModel
-- drop parentModel =
--     let
--         queueModel =
--             parentModel.queue
--     in
--         if queueModel.mouseOver then
-- -                 }
--         else
--             { queueModel
--                 | array =
--                     resetQueue
--                         <| Debug.log "how many in filter"
--                         <| Array.filter (.model >> .isDragging >> not) queueModel.array
--                 , mouseOverItem = Array.length queueModel.array
--             }
-- getNewSongsToAdd : List IndexedSongModel -> Array IndexedQueueSongModel
-- getNewSongsToAdd songModels =
--     Array.fromList
--         <| List.map songModelToQueueModel
--         <| List.filter (.isDragging)
--         <| List.map .model songModels
-- getNewGroupsToAdd : Dict String GroupModel -> Array IndexedQueueSongModel
-- getNewGroupsToAdd dict =
--     let
--         selectedGroupModels =
--             dict |> Dict.values |> List.filter .isSelected
--         songModels =
--             SortSongs.byAlbumAndTrack <| List.foldl (\gm acc -> gm.songs ++ acc) [] selectedGroupModels
--     in
--         Array.fromList
--             <| List.map songModelToQueueModel songModels
-- songModelToQueueModel : SongModel -> IndexedQueueSongModel
-- songModelToQueueModel sm =
--     { model =
--         { path = sm.path
--         , title = sm.title
--         , artist = sm.artist
--         , album = sm.album
--         , track = sm.track
--         , picture = sm.picture
--         , isDragging = False
--         , isMouseOver = False
--         }
--     , id = 0
--     }
-- view : Maybe Pos -> Array Item -> Html Msg
-- view maybePos model =
--     Html.div [ Attr.id "queue-view-container", Attr.class "scroll-box" ]
--         [ Html.ul [] (Array.toList <| Array.map (itemToHtml maybePos) <| model) ]


itemToHtml : Maybe Pos -> Int -> ( Int, ItemModel ) -> Html Msg
itemToHtml maybePos currentSong ( id, item ) =
    Html.map (ItemMsg id) (Item.view maybePos (id == currentSong) (toString id) item)


view : Maybe Pos -> Int -> Array ItemModel -> Html Msg
view maybePos currentSong model =
    Html.div
        [ Attr.id "queue-view-container"
        , Attr.class "scroll-box"
          -- , MyStyle.queueViewContainer parent.isDragging
        , Events.onMouseEnter MouseEnter
        , Events.onMouseLeave MouseLeave
        ]
        [ Html.ul []
            <| Array.toList
            <| Array.indexedMap ((\id item -> itemToHtml maybePos currentSong ( id, item ))) model
        ]



-- queueToHtml : Int -> { x : Int, y : Int } -> Int -> IndexedQueueSongModel -> Html Msg
-- queueToHtml currentSong dragPos i indexedQueueSongModel =
--     let
--         isCurrentSong =
--             (i == currentSong)
--     in
--         Html.map (SongMsg i) (QueueSong.view indexedQueueSongModel.model dragPos isCurrentSong)
-- -- Html.li [ MyStyle.songItem isCurrentSong ]
-- --     [ Html.text iSongModel) indexedSongModel.model.title ]
