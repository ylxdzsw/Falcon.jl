function with_template(f::Function, io::IO)
    io << open(read, rel"template.html") << f << "</body></html>"
end

function plot_stat(f::IO, var::Variable{Int32}, data::Vector{Int32})
    with_template(f) do f
        f << """<section class="scen">"""
        f << """<div id="$(var.name)" class="plotly-graph-div"></div>"""
        f << """<script>
            Plotly.newPlot("$(var.name)", [
                { x: $(json"$data"), type: "histogram" },
            ], {
                title: "$(var.name)",
                margin: { r:80, l:80, b:80, t:100 },
                xaxis: { title: "$(var.name) Histogram" }
            })
        </script>"""
    end
end
