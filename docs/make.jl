using Documenter
using ABMPredictionMarkets
using Plots

makedocs(;
    warnonly = true,
    sitename = "ABMPredictionMarkets",
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
        ABMPredictionMarkets,
        Base.get_extension(ABMPredictionMarkets, :PlotsExt)
    ],
    pages = [
        "Home" => "index.md",
        "Examples" => [
            "Basic Example" => "basic_example.md",
            "Custom Example" => "custom_example.md"
        ],
        "API" => "api.md"
    ]
)

deploydocs(repo = "github.com/itsdfish/ABMPredictionMarkets.jl.git")
