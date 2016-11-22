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


dragging maybeDragPos isSelected =
    case maybeDragPos of
        Just { x, y } ->
            if isSelected then
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
                        , ( "pointer-events", "none" )
                          -- make sure not to trigger mouseenters on the dragged element
                        ]
            else
                style [ ( "display", "none" ) ]

        Nothing ->
            style [ ( "display", "none" ) ]


mouseOver isMouseOver =
    if isMouseOver then
        style
            [ ( "border", "1px solid black" )
            ]
    else
        style []


currentSong isCurrentSong =
    if isCurrentSong then
        style [ ( "color", "white" ), ( "background-color", "blue" ) ]
    else
        style []


isSelected isSelected =
    if isSelected then
        style
            [ ( "color", "white" )
            , ( "background-color", "black" )
            ]
    else
        style []
