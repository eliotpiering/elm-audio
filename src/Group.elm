module Group exposing (view, Msg)

import Html exposing (Html)
import Html.Events as Events
import Html.Attributes as Attr
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


view : GroupModel -> Int -> Html Msg
view model id =
    Html.li
        [ Attr.class "group-item"
        , Events.onClick <| ClickGroup
        , Attr.id <| "group-model-" ++ (toString id)
        ]
        [ Html.text model.title ]
