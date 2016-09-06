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
    | Drop (List ItemModel) Int
    | Reorder Int


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
                            { model | array = Array.set id (Debug.log "new item in queue " item') model.array }
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

        Drop newItems currentQueueIndex ->
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

                newQueueIndex =
                    if currentQueueIndex > model.mouseOverItem then
                      currentQueueIndex + (Array.length newArrayItems)
                    else
                      currentQueueIndex
            in
                ( { model
                    | array =
                        resetQueue
                            <| Array.append left
                            <| Array.append newArrayItems right
                  }
                , Just <| UpdateCurrentSong newQueueIndex
                )

        Reorder currentQueueIndex ->
            let
                maybeIndexedItemToReorder =
                    model.array |> Array.toIndexedList |> List.filter (\(i, item) -> item.isSelected ) |> List.head
            in
                case maybeIndexedItemToReorder of
                    Just ( indexOfItemToReorder, itemToReorder ) ->
                        let
                            queueLength =
                                Array.length model.array

                            itemsToStayTheSame =
                                model.array |> Array.filter (not << .isSelected)

                            left =
                                Array.slice 0 model.mouseOverItem itemsToStayTheSame

                            right =
                                Array.slice model.mouseOverItem queueLength itemsToStayTheSame

                            reorderedQueue =
                                Array.append (Array.push itemToReorder left) right

                            newQueueIndex =
                                if currentQueueIndex > indexOfItemToReorder && currentQueueIndex < model.mouseOverItem then
                                    currentQueueIndex - 1
                                else
                                  if currentQueueIndex < indexOfItemToReorder && currentQueueIndex > model.mouseOverItem then
                                    currentQueueIndex + 1
                                  else
                                    currentQueueIndex
                        in
                            ( { model | array = resetQueue reorderedQueue }, Just <| UpdateCurrentSong newQueueIndex )

                    Nothing ->
                        ( model, Nothing )


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
    Html.map (ItemMsg id) (Item.queueItemView maybePos (id == currentSong) (toString id) item)


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
