module Main exposing (..)

import Date
import Date.Extra.Duration as Duration
import Html exposing (Attribute, Html, div, input, p, text)
import Html.Attributes exposing (maxlength, placeholder)
import Html.Events exposing (onInput)
import LineChart exposing (lineChart)
import Task


main =
    Html.program
        { init = ( initialState, Task.perform NewDate Date.now )
        , view = view
        , update = update
        , subscriptions = always Sub.none
        }



-- MODEL


type alias Model =
    { interest : Float, years : Int, init : Float, contribution : Float, currentDate : Date.Date }


initialState : Model
initialState =
    { interest = 8, years = 10, init = 1000, contribution = 100, currentDate = Date.fromTime 0 }



-- UPDATE


type Msg
    = Interest String
    | Principal String
    | Duration String
    | Contribution String
    | NewDate Date.Date


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Interest s ->
            case String.toFloat s of
                Ok f ->
                    ( { model | interest = f }, Cmd.none )

                Err e ->
                    ( model, Cmd.none )

        Principal s ->
            case String.toFloat s of
                Ok f ->
                    ( { model | init = f }, Cmd.none )

                Err e ->
                    ( model, Cmd.none )

        Duration s ->
            case String.toInt s of
                Ok i ->
                    ( { model | years = i }, Cmd.none )

                Err e ->
                    ( model, Cmd.none )

        Contribution s ->
            case String.toFloat s of
                Ok f ->
                    ( { model | contribution = f }, Cmd.none )

                Err e ->
                    ( model, Cmd.none )

        NewDate d ->
            ( { model | currentDate = d }, Cmd.none )



-- VIEW


view : Model -> Html Msg
view model =
    div
        []
        [ p
            []
            [ text "Yearly Interest: "
            , input [ placeholder <| toString initialState.interest ++ "%", onInput Interest ] []
            ]
        , p
            []
            [ text "Starting Principal: "
            , input [ placeholder <| toString initialState.init ++ " EUR", onInput Principal ] []
            ]
        , p
            []
            [ text "Monthly Contribution: "
            , input [ placeholder <| toString initialState.contribution ++ " EUR", onInput Contribution ] []
            ]
        , p
            []
            [ text "Duration (years): "
            , input [ placeholder <| toString initialState.years, onInput Duration, maxlength 3 ] []
            ]
        , p [] [ text ("Final balance: " ++ toString (List.maximum <| List.map Tuple.second <| accumulatedInterest model)) ]
        , lineChart <| accumulatedInterest model
        ]



-- LOGIC


accumulatedInterest : Model -> List ( Date.Date, Float )
accumulatedInterest model =
    let
        compoundPerYear =
            12

        interest =
            model.interest / 100

        compoundInterest y =
            model.init * (1 + (interest / compoundPerYear)) ^ (compoundPerYear * y)

        futureValueOfSeries y =
            model.contribution
                * (((1 + interest / compoundPerYear) ^ (compoundPerYear * y) - 1)
                    / (interest / compoundPerYear)
                  )

        resolution =
            100

        yearStep =
            toFloat model.years / toFloat resolution

        dateInYears years =
            Duration.add Duration.Day (floor (years * 365)) model.currentDate
    in
    List.map
        (\i ->
            let
                y =
                    toFloat i * yearStep
            in
            ( dateInYears y
            , compoundInterest y + futureValueOfSeries y
            )
        )
    <|
        List.range 0 resolution
