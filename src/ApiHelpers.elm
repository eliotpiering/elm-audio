module ApiHelpers exposing (apiEndpoint, fetchAllAlbums, fetchAllArtists, fetchAllSongs)

import Http
import Json.Decode as Json exposing (Decoder, (:=))
import Task exposing (Task)
import MyModels exposing (..)


apiEndpoint : String
apiEndpoint =
    "http://localhost:4000/api/"


-- fetchAllSongs : Msg -> Msg -> Cmd Msg
fetchAllSongs failAction successAction =
    let
        url =
            apiEndpoint ++ "songs"
    in
        Task.perform failAction successAction <|
            Http.get songsDecoder url


-- fetchAllArtists : Msg -> Msg -> Cmd Msg
fetchAllArtists failAction successAction =
    let
        url =
            apiEndpoint ++ "artists"
    in
        Task.perform failAction successAction <|
            Http.get artistsDecoder url


-- fetchAllAlbums : Msg -> Msg -> Cmd Msg
fetchAllAlbums failAction successAction =
    let
        url =
            apiEndpoint ++ "albums"
    in
        Task.perform failAction successAction <|
            Http.get albumsDecoder url


albumsDecoder : Decoder (List GroupModel)
albumsDecoder =
    "albums" := Json.list groupDecoder


artistsDecoder : Decoder (List GroupModel)
artistsDecoder =
    "artists" := Json.list groupDecoder


songsDecoder : Decoder (List SongModel)
songsDecoder =
    "songs" := Json.list songDecoder


groupDecoder : Decoder GroupModel
groupDecoder =
    Json.object2 GroupModel
        ("title" := Json.string)
        songsDecoder


-- TODO embed the songs in the json


songDecoder : Decoder SongModel
songDecoder =
    Json.object6 SongModel
        ("id" := Json.int)
        ("path" := Json.string)
        ("title" := Json.string)
        ("artist" := Json.string)
        ("album" := Json.string)
        ("track" := Json.int)
