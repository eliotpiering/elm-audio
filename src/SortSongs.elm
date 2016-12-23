module SortSongs exposing (byAlbumAndTrack, byGroupTitle)

import MyModels exposing (..)


byAlbumAndTrack : List QueueItemModel -> List QueueItemModel
byAlbumAndTrack =
    List.sortWith
        (\item1 item2 ->
            case compare item1.song.album item2.song.album of
                EQ ->
                    compare item1.song.track item2.song.track

                greaterOrLess ->
                    greaterOrLess
        )



-- Only works for items that are groups


byGroupTitle : List ( String, ItemModel ) -> List ( String, ItemModel )
byGroupTitle =
    List.sortWith
        (\( _, item1 ) ( _, item2 ) ->
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
