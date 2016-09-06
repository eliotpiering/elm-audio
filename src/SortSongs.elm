module SortSongs exposing (byAlbumAndTrack, byGroupTitle)

import MyModels exposing (..)


-- Only works for items that are songs
byAlbumAndTrack : List ItemModel -> List ItemModel
byAlbumAndTrack =
    List.sortWith
        (\item1 item2 ->
            case item1.data of
                Song s1 ->
                    case item2.data of
                        Song s2 ->
                            case compare s1.album s2.album of
                                EQ ->
                                    compare s1.track s2.track

                                greaterOrLess ->
                                    greaterOrLess
           
                        anythingElse ->
                            EQ

                anythingElse ->
                    EQ
        )

-- Only works for items that are groups
byGroupTitle: List (String, ItemModel) -> List (String, ItemModel)
byGroupTitle =
    List.sortWith
        (\(_, item1) (_, item2) ->
            case item1.data of
                Group g1 ->
                    case item2.data of
                        Group g2 ->
                            compare g1.title g2.title 
                        anythingElse ->
                            EQ

                anythingElse ->
                    EQ
        )



-- byIndexedAlbumAndTrack : List IndexedSongModel -> List IndexedSongModel
-- byIndexedAlbumAndTrack =
--     List.sortWith
--         (\s1 s2 ->
--             case compare s1.model.album s2.model.album of
--                 EQ ->
--                     compare s1.model.track s2.model.track
--                 greaterOrLess ->
--                     greaterOrLess
--         )
