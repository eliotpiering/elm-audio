module MyStyle exposing (..)

import Color exposing (..)
import Html.Attributes exposing (style)


type alias MyStyle =
    List ( String, String )


none =
    style []


queueViewContainer canDrop =
    if canDrop then
        style [ ( "border", "solid black 2px" ) ]
    else
        style []


dragging { x, y } isDragging =
    if isDragging then
        let
            xPos =
                toString x ++ "px"

            yPos =
                toString y ++ "px"
        in
            style
                [ ( "position", "fixed" )
                , ( "left", xPos )
                , ( "top", yPos )
                , ( "z-index", "-1" )
                , ( "color", "white" )
                , ( "background-color", "black" )
                ]
    else
        style []


mouseOver isMouseOver =
    if isMouseOver then
        style
            [ ( "border-bottom", "1px solid black" )
            ]
    else
        style []


currentSong =
    style [ ( "color", "white" ), ( "background-color", "black" ) ]


isSelected isSelected =
    if isSelected then
        style
            [ ( "color", "white" )
            , ( "background-color", "black" )
            ]
    else
        style []
