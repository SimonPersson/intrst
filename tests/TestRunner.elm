module TestRunner exposing (..)

import AccumulatedInterest
import Date
import Expect
import Fuzz exposing (..)
import Model exposing (fromBase64, toBase64)
import Test exposing (..)


allZeroesModel : Model.Model
allZeroesModel =
    { firstParam =
        { id = 0
        , interest = 0
        , years = 0
        , contribution = 0
        , contributionGrowthRate = 0
        , compoundingPerYear = 1
        }
    , parameters = []
    , initialPrincipal = 0
    , currentDate = Date.fromTime 0
    , showAdvanced = False
    , uid = 0
    , shareLink = ""
    }


maxResult : List ( Date.Date, Float ) -> Float
maxResult =
    Maybe.withDefault 0 << List.maximum << List.map Tuple.second


iteratingInterest : Int -> Float -> Float -> Float
iteratingInterest years principal discount =
    List.foldr (always ((*) discount)) principal <| List.range 1 years


iteratingContributionInterest : Int -> Float -> Float -> Float
iteratingContributionInterest years contribution discount =
    List.foldr (\x y -> contribution + discount * y) 0 <| List.map toFloat <| List.range 1 years


testDecodeEncode : Test
testDecodeEncode =
    test "The model should encode and decode without errors." <|
        \() ->
            Expect.equal (Ok allZeroesModel) <| fromBase64 <| toBase64 allZeroesModel


testBasics : Test
testBasics =
    describe "Basic assumptions"
        [ test "10 years of interest with no contribution." <|
            \() ->
                let
                    firstParam =
                        allZeroesModel.firstParam
                in
                Expect.within (Expect.Relative 0.1)
                    (AccumulatedInterest.accumulatedInterest
                        { allZeroesModel
                            | firstParam = { firstParam | interest = 5, years = 10 }
                            , initialPrincipal = 100
                        }
                        |> maxResult
                    )
                    (iteratingInterest 10 100 1.05)
        , test "10 years of only contributions" <|
            \() ->
                let
                    firstParam =
                        allZeroesModel.firstParam
                in
                Expect.within (Expect.Relative 0.1)
                    (AccumulatedInterest.accumulatedInterest
                        { allZeroesModel | firstParam = { firstParam | years = 10, contribution = 10 } }
                        |> maxResult
                    )
                    (10 * 10 * 12)
        , test "10 years with contributions and interest" <|
            \() ->
                let
                    firstParam =
                        allZeroesModel.firstParam
                in
                Expect.within (Expect.Relative 0.1)
                    (AccumulatedInterest.accumulatedInterest
                        { allZeroesModel
                            | firstParam =
                                { firstParam
                                    | years = 10
                                    , contribution = 10
                                    , interest = 5
                                }
                        }
                        |> maxResult
                    )
                    (iteratingContributionInterest 10 120 1.05)
        , test "10 years with contributions, initial, and interest" <|
            \() ->
                let
                    firstParam =
                        allZeroesModel.firstParam
                in
                Expect.within (Expect.Relative 0.1)
                    (AccumulatedInterest.accumulatedInterest
                        { allZeroesModel
                            | firstParam =
                                { firstParam
                                    | years = 10
                                    , contribution = 10
                                    , interest = 5
                                }
                            , initialPrincipal = 10000
                        }
                        |> maxResult
                    )
                    (iteratingContributionInterest 10 120 1.05 + iteratingInterest 10 10000 1.05)
        , test "10 years and then 10 years with other interest" <|
            \() ->
                let
                    firstParam =
                        allZeroesModel.firstParam
                in
                Expect.within (Expect.Relative 0.1)
                    (AccumulatedInterest.accumulatedInterest
                        { allZeroesModel
                            | firstParam =
                                { firstParam
                                    | years = 10
                                    , contribution = 10
                                    , interest = 5
                                }
                            , initialPrincipal = 10000
                            , parameters = [ { firstParam | years = 10, contribution = 10, interest = 8 } ]
                        }
                        |> maxResult
                    )
                    (let
                        first =
                            iteratingContributionInterest 10 120 1.05 + iteratingInterest 10 10000 1.05
                     in
                     iteratingContributionInterest 10 120 1.08 + iteratingInterest 10 first 1.08
                    )
        ]


testNoNaN : Test
testNoNaN =
    fuzz5
        (floatRange 0 100)
        (floatRange 0 1000000000000)
        (intRange 0 99)
        (floatRange 0 1000000)
        (floatRange 0 99)
        "Find NaN when using somewhat reasonable inputs."
    <|
        \interest principal years contribution contributionGrowth ->
            let
                model =
                    { firstParam =
                        { id = 0
                        , interest = interest
                        , years = years
                        , contribution = contribution
                        , contributionGrowthRate = contributionGrowth
                        , compoundingPerYear = 365
                        }
                    , parameters = []
                    , initialPrincipal = principal
                    , currentDate = Date.fromTime 0
                    , showAdvanced = False
                    , uid = 0
                    , shareLink = ""
                    }
            in
            Expect.false "Expected the calculation to not yield NaN."
                (AccumulatedInterest.accumulatedInterest model
                    |> maxResult
                    |> isNaN
                )
