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
        , ( "-webkit-user-select", "none" )
          -- so can't highlight
        ]


fileViewContainer =
    style
        [ ( "width", "50%" )
        , ( "float", "left" )
        , ( "-webkit-user-select", "none" )
          -- so can't highlight
        ]


queueViewContainer =
    style
        [ ( "width", "50%" )
        , ( "float", "right" )
        , ( "-webkit-user-select", "none" )
          -- so can't highlight
        ]


songList =
    style
        [ ( "list-style", "none" )
        , ( "-webkit-user-select", "none" )
          -- so can't highlight
        ]


songItem isDragging =
    let
        baseStyle =
            [ ( "padding-top", "5px" )
            , ( "padding-bottom", "5px" )
            , ( "-webkit-user-select", "none" )
              -- so can't highlight
            ]
    in
        if isDragging then
            style <| [ ( "color", "white" ), ( "background-color", "black" ) ] ++ baseStyle
        else
            style baseStyle


dragging { x, y } isDragging =
    if isDragging then
        let
            xPos =
                toString x ++ "px"

            yPos =
                toString y ++ "px"
        in
            style
                [ ( "position", "absolute" )
                , ( "left", xPos )
                , ( "top", yPos )
                ]
    else
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


upArrow =
    style
        [ ( "background-color", "white" )
        , ( "color", "black" )
        , ( "font-family", "serif" )
        , ( "font-size", "2em" )
        , ( "line-height", "2em" )
        , ( "padding-top", "5%" )
        , ( "padding-bottom", "5%" )
        , ( "padding-left", "30%" )
        , ( "padding-right", "30%" )
        ]
