module Queue exposing (..)

-- (view, update, Msg, drop)

import Html exposing (Html)
import Html.Events as Events
import Html.Attributes as Attr
import Html.App as Html
import MyModels exposing (..)
import MyStyle exposing (..)
import Array exposing (Array)
import QueueSong
import SortSongs
import Dict exposing (Dict)
import Item

-- type alias ParentModel =
--     Model


type Msg
    = MouseEnter
    | MouseLeave
    | ItemMsg Int Item.Msg
    | SongMsg Int QueueSong.Msg
    | Drop (List ItemModel)

type alias Pos =
    { x : Int, y : Int }


update : Msg -> QueueModel -> QueueModel
update msg model =
    case msg of
        MouseEnter ->
            { model | mouseOver = True }

        MouseLeave ->
            { model | mouseOver = False }

        SongMsg id msg ->
            let
                updatedQueueSongsWithProps =
                    (Array.map
                        (\indexed ->
                            if indexed.id == id then
                                let
                                    ( newModel, maybeMouseOverItemId ) =
                                        QueueSong.update msg indexed.model
                                in
                                    case maybeMouseOverItemId of
                                        Just _ ->
                                            ( { indexed
                                                | model = newModel
                                              }
                                            , Just id
                                            )

                                        Nothing ->
                                            ( { indexed
                                                | model = newModel
                                              }
                                            , Nothing
                                            )
                            else
                                ( indexed, Nothing )
                        )
                        model.array
                    )
            in
                { model
                    | array = Array.map fst updatedQueueSongsWithProps
                    , mouseOverItem = Maybe.withDefault (Array.length model.array) <| Maybe.oneOf <| Array.toList <| Array.map snd updatedQueueSongsWithProps
                }

        Drop newItems ->
            if model.mouseOver then
              -- let
              --     newSongs =
              --         getNewItemsparentModel.songs) (getNewGroupsToAdd parentModel.groups)
              --     -- reorderedQueueSongs =
              --     --     Array.filter (.model >> .isDragging) queueModel.array
              --     -- queueSongsNotDragging =
              --     --     Array.filter (.model >> .isDragging >> not) queueModel.array
              --     left =
              --         Array.slice 0 queueModel.mouseOverItem) queueSongsNotDragging
              --     right =
              --         Array.slice queueModel.mouseOverItem (Array.length queueModel.array) queueSongsNotDragging
              -- in
                  -- { model
                  --     | array =
                  --         resetQueue
                  --             <| Array.append (Array.fromList newItems) model.array
                  --     --         <| Array.append newSongs right
                  --     -- , mouseOverItem = Array.length queueModel.array + 1
                  -- }
              model
            else
              model

-- resetQueue : Array ItemModel -> Array ItemModel
-- resetQueue array =
--     Array.map
--         (\item ->
--                 { item
--                   | isSelected = False
--                   , isMouseOver = False
--                 }
--         )


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


itemToHtml : Maybe Pos -> (Int, ItemModel) -> Html Msg
itemToHtml maybePos ( id, item ) =
    Html.map (ItemMsg id) (Item.view maybePos item)


view : Maybe Pos -> Array ItemModel -> Html Msg
view maybePos model =
    Html.div
        [ Attr.id "queue-view-container"
        , Attr.class "scroll-box"
        -- , MyStyle.queueViewContainer parent.isDragging
        , Events.onMouseEnter MouseEnter
        , Events.onMouseLeave MouseLeave
        ]
        [ Html.ul []
            <| Array.toList
            <| Array.indexedMap ((\id item -> itemToHtml maybePos (id, item) )) model
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
