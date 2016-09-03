module Helpers exposing (makeSongItemDictionary, makeGroupItemDictionary, getItemTitle)
import Dict exposing (Dict)
import MyModels exposing (..)

-- Public

makeSongItemDictionary : List SongModel -> ItemDictionary
makeSongItemDictionary songs =
  makeItemDictionary <| List.map Song songs

makeGroupItemDictionary : List GroupModel -> ItemDictionary
makeGroupItemDictionary groups =
  makeItemDictionary <| List.map Group groups

getItemTitle : ItemModel -> String
getItemTitle item =
  case item.data of
    Song songModel ->
      songModel.title
    Group groupModel ->
      groupModel.title

-- Private

makeItemDictionary : List ItemData -> ItemDictionary
makeItemDictionary itemDatas =
    let
        ids =
            List.map toString <| generateIdList (List.length itemDatas) []
        pairs =
            List.map2 (,) ids itemDatas
    in
        List.foldl
          (\( id, itemData) dict -> Dict.insert id {isSelected = False, isMouseOver = False, data = itemData }  dict)
          Dict.empty
          pairs

generateIdList : Int -> List Int -> List Int
generateIdList len list =
    if len == 0 then
        list
    else
        len :: (generateIdList (len - 1) list)

