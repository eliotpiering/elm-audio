module Group exposing (view, Msg)

import Html exposing (Html)
import Html.Events as Events
import MyModels exposing (..)
import MyStyle exposing (..)


init : GroupModel -> GroupModel
init groupModel =
    groupModel



type Msg
    = ClickGroup

-- update : Msg -> GroupModel -> ( GroupModel, Cmd Msg )
-- update msg model =
--     case msg of
--         ClickFile ->
--             ( { model | isSelected = not model.isSelected }, Cmd.none )


view : GroupModel -> Html Msg
view model =
    Html.li
        [ MyStyle.songItem False
        , Events.onClick <| ClickGroup
        ]
        [ Html.text model.title ]
