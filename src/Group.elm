module Group exposing (..)

import Html exposing (Html)
import Html.Events as Events
import Html.Attributes as Attr
import MyModels exposing (..)
import MyStyle exposing (..)

type Msg
    = OpenGroup
    | SelectGroup

update : Msg -> GroupModel -> GroupModel
update msg model =
    case msg of
        SelectGroup ->
             { model | isSelected = not model.isSelected }
        OpenGroup ->
             { model | isSelected = False}

reset : GroupModel -> GroupModel
reset model =
  {model
    | isSelected = False
    , isDragging = False
  }

view : GroupModel -> String -> Html Msg
view model id =
    Html.li
        [ Attr.class "group-item"
        , Events.onDoubleClick <| OpenGroup
        , Events.onMouseDown SelectGroup
        , Attr.id <| "group-model-" ++ id
        , MyStyle.isSelected model.isSelected
        ]
        [ Html.text model.title ]
