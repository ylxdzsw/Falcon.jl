function page(f::Function, io::IO)
    io << open(read, rel"template.html") << f << "</body></html>"
end

function section(f::Function, io::IO)
    io << """<section class="scen">""" << f << "</section>"
end

function plot(f::Function, io::IO, title::AbstractString)
    io << """<div id="$title" class="plotly-graph-div"></div>"""
    io << """<script>Plotly.newPlot("$title",""" << f << """)</script>"""
end

function var(io::IO, name, data)
    io << """<script>window.$name=$(json"$data")</script>"""
end

function plot_stat{T<:Number}(f::IO, xvar::Variable{T}, xdata::Vector{T})
    x = xvar.name

    page(f) do f
        var(f, x, xdata)

        section(f) do f
            title = "histogram-$x"

            plot(f, title) do f
                f << """[
                    { x: $x, type: 'histogram' }
                ], {
                    title: '$title',
                    xaxis: { title: '$x' },
                }"""
            end
        end

    end
end

function plot_stat{T<:Number, S<:Number}(f::IO, xvar::Variable{T}, yvar::Variable{S}, xdata::Vector{T}, ydata::Vector{S})
    x, y = xvar.name, yvar.name

    page(f) do f
        var(f, x, xdata)
        var(f, y, ydata)

        # section(f) do f
        #     title = "scatter-$y~$x"

        #     plot(f, title) do f
        #         f << """[
        #             { x: $x, y: $y, type: 'scatter', mode: 'markers', marker: { size: 2 } }
        #         ], {
        #             title: '$title',
        #             xaxis: { title: '$x' },
        #             yaxis: { title: '$y' },
        #         }"""
        #     end
        # end

    end
end
