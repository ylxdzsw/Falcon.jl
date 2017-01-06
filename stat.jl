function with_template(f::Function, io::IO)
    io << open(read, rel"template.html") << f << "</body></html>"
end

function plot_stat{T<:Number}(f::IO, xvar::Variable{T}, xdata::Vector{T})
    with_template(f) do f
        f << """<section class="scen">"""
        f << """<div id="histogram-$(xvar.name)" class="plotly-graph-div"></div>"""
        f << """<script>
            Plotly.newPlot("histogram-$(xvar.name)", [
                { x: $(json"$xdata"), type: "histogram" }
            ], {
                title: "$(xvar.name) Histogram",
                margin: { r:80, l:80, b:80, t:100 },
                xaxis: { title: "$(xvar.name)" }
            })
        </script>"""

        f << "</section>"
    end
end

function plot_stat{T<:Number, S<:Number}(f::IO, xvar::Variable{T}, yvar::Variable{S}, xdata::Vector{T}, ydata::Vector{S})
    with_template(f) do f
        f << """<section class="scen">"""
        f << """<div id="scatter-$(yvar.name)-$(xvar.name)" class="plotly-graph-div"></div>"""
        f << """<script>
            Plotly.newPlot("scatter-$(yvar.name)-$(xvar.name)", [
                { x: $(json"$xdata"), y: $(json"$ydata"), type: "scatter" }
            ], {
                title: "$(yvar.name) ~ $(xvar.name)",
                margin: { r:80, l:80, b:80, t:100 },
                xaxis: { title: "$(xvar.name)" }
                yaxis: { title: "$(yvar.name)" }
            })
        </script>"""

        f << "</section>"
    end
end
