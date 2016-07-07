module MyStyle exposing (..)

import Color exposing (..)
import Html.Attributes exposing (style)


type alias MyStyle =
    List ( String, String )


playerContainer =
    style
        [ ( "overflow", "hidden" )
        , ( "position", "relative" )
        , ( "width", "100%" )
        ]


audioViewContainer =
    style
        [ ( "width", "100%" )
        , ( "height", "100px" )
        , ( "margin-left", "auto" )
        , ( "margin-right", "auto" )
        , ( "clear", "both" )
        , ( "-webkit-user-select", "none" )
        ]


fileViewContainer =
    style
        [ ( "width", "49%" )
        , ( "float", "left" )
        , ( "-webkit-user-select", "none" )
        ]


queueViewContainer canDrop =
    let
        baseStyle =
            [ ( "width", "49%" )
            , ( "float", "right" )
            , ( "min-height", "400px" )
            , ( "height", "100%" )
            , ( "position", "absolute" )
            , ( "right", "0" )
            , ( "top", "100px" )
            , ( "-webkit-user-select", "none" )
            , ( "overflow", "visible" )
            ]
    in
        if canDrop then
            style <| baseStyle ++ [ ( "border", "solid black 2px" ) ]
        else
            style baseStyle


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
                , ( "z-index", "-1" )
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


albumArtContainer =
    style
        [ ( "position", "absolute" )
        , ( "top", "100px" )
        , ( "right", "10px" )
        , ( "z-index", "-2" )
        , ( "-webkit-user-select", "none" )
        ]
