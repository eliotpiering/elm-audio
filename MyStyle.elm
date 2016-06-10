module MyStyle exposing (..)

import Color exposing (..)
import Html.Attributes exposing (style)


type alias MyStyle =
    List ( String, String )


audioViewContainer =
    style
        [ ( "width", "100%" )
        , ( "margin-left", "auto" )
        , ( "margin-right", "auto" )
        ]


fileViewContainer =
    style
        [ ( "width", "50%" )
        , ( "float", "left" )
        ]


queueViewContainer =
    style
        [ ( "width", "50%" )
        , ( "float", "right" )
        ]


songList =
    style
        [ ( "list-style", "none" )
        ]


songItem =
    style []
