module State exposing (init, update)

import Board exposing (startingBoard)
import Dict
import Move exposing (getPossibleMoves)
import Types exposing (..)


init : Model
init =
    { board = startingBoard
    , boardWithoutPossibleMoves = startingBoard
    , turn = White
    , beingDragged = Nothing
    , history = []
    }


update : Msg -> Model -> Model
update msg model =
    case msg of
        CheckPossibleMoves tileIndex ->
            let
                possMoves =
                    getPossibleMoves tileIndex model.boardWithoutPossibleMoves
            in
            { model | board = updatePossibleMoves possMoves model.boardWithoutPossibleMoves }

        RemovePossilbeMoves ->
            { model | board = model.boardWithoutPossibleMoves }

        Drag ( piece, index ) ->
            { model | beingDragged = Just ( piece, index ) }

        DragEnd ->
            { model | beingDragged = Nothing }

        DragOver ->
            model

        Drop targetIndex ->
            let
                boardWithoutPossibleMoves =
                    model.boardWithoutPossibleMoves

                updatedBoard =
                    case model.beingDragged of
                        Just ( piece, currentIndex ) ->
                            boardWithoutPossibleMoves
                                |> moveToNewTile targetIndex piece
                                |> removeFromPreviousTile currentIndex piece

                        Nothing ->
                            model.board
            in
            case model.beingDragged of
                Nothing ->
                    model

                Just ( piece, _ ) ->
                    { model
                        | beingDragged = Nothing
                        , board = updatedBoard
                        , boardWithoutPossibleMoves = updatedBoard
                        , turn = oppositeTeam piece.team
                        , history =
                            { board = model.boardWithoutPossibleMoves
                            , turn = model.turn
                            }
                                :: model.history
                    }

        CancelLastMove ->
            case model.history of
                previousEntry :: otherEntries ->
                    { model
                        | beingDragged = Nothing
                        , board = previousEntry.board
                        , boardWithoutPossibleMoves = previousEntry.board
                        , turn = previousEntry.turn
                        , history = otherEntries
                    }

                [] ->
                    model


oppositeTeam : Team -> Team
oppositeTeam team =
    case team of
        Black ->
            White

        White ->
            Black


moveToNewTile : Int -> Piece -> Board -> Board
moveToNewTile index piece board =
    Dict.update index (Maybe.map (\tile -> { tile | status = WithinBounds, piece = Just piece })) board


removeFromPreviousTile : Int -> Piece -> Board -> Board
removeFromPreviousTile index piece board =
    Dict.update index (Maybe.map (\tile -> { tile | status = WithinBounds, piece = Nothing })) board


updatePossibleMoves : List Int -> Board -> Board
updatePossibleMoves possMoves board =
    List.foldl updatePossibleMove board possMoves


updatePossibleMove : Int -> Board -> Board
updatePossibleMove index board =
    Dict.update index (Maybe.map (\tile -> { tile | status = PossilbeMove })) board
