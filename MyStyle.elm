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
        , ( "clear", "both" )
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


currentSong =
    style [ ( "color", "white" ), ( "background-color", "black" ) ]


button =
    style
        [ ( "padding", "10%" )
        , ( "width", "80%" )
        ]


floatLeft =
    style
        [ ( "width", "33%" )
        , ( "float", "left" )
        , ( "padding", "auto" )
        , ( "margin", "auto" )
        , ( "text-align", "center" )
        ]


audioPlayer =
    style
        [ ( "width", "80%" )
        , ( "padding", "10%" )
        , ( "background-color", "black" )
        , ( "border-radius", "20%" )
        ]
