module SortSongs exposing (byAlbumAndTrack, byIndexedAlbumAndTrack)
import MyModels exposing (..)

byAlbumAndTrack : List SongModel -> List SongModel
byAlbumAndTrack =
    List.sortWith
        (\s1 s2 ->
            case compare s1.album s2.album of
                EQ ->
                    compare s1.track s2.track

                greaterOrLess ->
                    greaterOrLess
        )
byIndexedAlbumAndTrack : List IndexedSongModel -> List IndexedSongModel
byIndexedAlbumAndTrack =
    List.sortWith
        (\s1 s2 ->
            case compare s1.model.album s2.model.album of
                EQ ->
                    compare s1.model.track s2.model.track

                greaterOrLess ->
                    greaterOrLess
        )
