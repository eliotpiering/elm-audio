module ApiHelpers exposing (apiEndpoint, fetchAllAlbums, fetchAllArtists, fetchAllSongs)

import Http
import Json.Decode as Json exposing (Decoder)
import MyModels exposing (..)
import Result


apiEndpoint : String
apiEndpoint =
    "http://localhost:4000/api/"



-- fetchAllSongs : Msg -> Msg -> Cmd Msg
fetchAllSongs successAction =
    let
        url =
            apiEndpoint ++ "songs"
    in
        Http.send successAction <|
            Http.get url songsDecoder



-- fetchAllArtists : Msg -> Msg -> Cmd Msg


fetchAllArtists successAction =
    let 
        url =
            apiEndpoint ++ "artists"
    in
        Http.send successAction  <|
            Http.get url artistsDecoder



-- fetchAllAlbums : Msg -> Msg -> Cmd Msg


fetchAllAlbums successAction =
    let
        url =
            apiEndpoint ++ "albums"
    in
        Http.send successAction <|
            Http.get url albumsDecoder


albumsDecoder : Decoder (List GroupModel)
albumsDecoder =
    Json.field "albums" <| Json.list groupDecoder


artistsDecoder : Decoder (List GroupModel)
artistsDecoder =
    Json.field "artists" <| Json.list groupDecoder


songsDecoder : Decoder (List SongModel)
songsDecoder =
    Json.field "songs" <| Json.list songDecoder


groupDecoder : Decoder GroupModel
groupDecoder =
    Json.map2 GroupModel
        (Json.field "title" Json.string)
        songsDecoder



-- TODO embed the songs in the json


songDecoder : Decoder SongModel
songDecoder =
    Json.map6 SongModel
        (Json.field "id" Json.int)
        (Json.field "path" Json.string)
        (Json.field "title" Json.string)
        (Json.field "artist" Json.string)
        (Json.field "album" Json.string)
        (Json.field "track" Json.int)
