using Documenter
using PredictionMarketABM
using Plots

makedocs(;
    warnonly = true,
    sitename = "PredictionMarketABM",
    format = Documenter.HTML(
        assets = [
            asset(
            "https://fonts.googleapis.com/css?family=Montserrat|Source+Code+Pro&display=swap",
            class = :css
        )
        ],
        collapselevel = 1
    ),
    modules = [
        PredictionMarketABM,
        Base.get_extension(PredictionMarketABM, :PlotsExt)
        #Base.get_extension(PredictionMarketABM, :NamedArraysExt)
    ],
    pages = [
        "Home" => "index.md",
        "Example" => "example.md",
        "API" => "api.md"
    ]
)

deploydocs(repo = "github.com/itsdfish/PredictionMarketABM.jl.git")
