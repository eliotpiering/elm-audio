module AlbumArt exposing (view)

import Html exposing (Html)
import Html.Attributes as Attr

view : String -> Html msg
view picture =
    Html.div [ Attr.id "album-art-container" ]
        [ Html.img [ Attr.src picture ] [] ]
