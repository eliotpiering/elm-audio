module NavigationParser exposing (..)

import UrlParser as Parser exposing (Parser, (</>), int, s)
import Navigation exposing (Location)


type Route
    = ArtistsRoute
    | AlbumsRoute
    | SongsRoute
    | ArtistRoute Int
    | AlbumRoute Int
    | NotFoundRoute


urlParser : Location -> Route
urlParser location =
    case Parser.parseHash route location of
        Just route ->
            route
        Nothing ->
            NotFoundRoute


route : Parser (Route -> a) a
route =
    Parser.oneOf
        [ Parser.map ArtistsRoute (s "artists")
        , Parser.map AlbumsRoute (s "albums")
        , Parser.map SongsRoute (s "songs")
        , Parser.map ArtistRoute (s "artists" </> int)
        , Parser.map AlbumRoute (s "albums" </> int)
        ]
