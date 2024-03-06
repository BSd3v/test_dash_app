from dash import Dash, dcc, html, Input, Output, no_update, State
import plotly.graph_objects as go
import pandas as pd

# Small molcule drugbank dataset
Source = 'https://raw.githubusercontent.com/plotly/dash-sample-apps/main/apps/dash-drug-discovery/data/small_molecule_drugbank.csv'

df = pd.read_csv(Source, header=0, index_col=0)

fig = go.Figure(data=[
    go.Scatter(
        x=df["LOGP"],
        y=df["PKA"],
        mode="markers",
        marker=dict(
            colorscale='viridis',
            color=df["MW"],
            size=df["MW"],
            colorbar={"title": "Molecular<br>Weight"},
            line={"color": "#444"},
            reversescale=True,
            sizeref=45,
            sizemode="diameter",
            opacity=0.8,
        )
    )
])

# turn off native plotly.js hover effects - make sure to use
# hoverinfo="none" rather than "skip" which also halts events.
fig.update_traces(hoverinfo="none", hovertemplate=None)

fig.update_layout(
    xaxis=dict(title='Log P'),
    yaxis=dict(title='pkA'),
    plot_bgcolor='rgba(255,255,255,0.1)'
)

app = Dash(__name__, external_scripts=[{'src': "https://ajax.googleapis.com/ajax/libs/jquery/3.6.0/jquery.min.js"}])

server = app.server

app.layout = html.Div([
    dcc.Graph(id="graph-basic-2", figure=fig, clear_on_unhover=True),
    dcc.Tooltip(id="graph-tooltip"),
    dcc.Store(id='graph-basic-2-data', data=df.to_dict('records'))
])

app.clientside_callback(
    """
    function showHover(hv, data) {
        if (hv) {
            //demo only shows the first point, but other points may also be available          
            pt = hv["points"][0]
            bbox = pt["bbox"]
            num = pt["pointNumber"]

            df_row = data[num]
            img_src = df_row['IMG_URL']
            name = df_row['NAME']
            form = df_row['FORM']
            desc = df_row['DESC']
            if (desc.length > 300) {
                desc = desc.substring(0,100) + '...'
            }

            img = jQuery(
                "<img>", {
                    src: img_src,
                    style: "width:100%"
                }
            )

            ttl = jQuery("<h2>", {text: name})
            form = jQuery("<p>", {text: form})
            desc = jQuery("<p>", {text: desc})

            newDiv = jQuery("<div>", {
                style: 'width:200px;white-space:normal'
            })

            $(newDiv).append(img)
            $(newDiv).append(ttl)
            $(newDiv).append(form)
            $(newDiv).append(desc)

            $('#graph-tooltip').empty()

            $('#graph-tooltip').append($(newDiv))

            return [true, bbox]
        }
        return [false, dash_clientside.no_update]
    }
    """,
    Output("graph-tooltip", "show"),
    Output("graph-tooltip", "bbox"),
    Input("graph-basic-2", "hoverData"),
    State('graph-basic-2-data', 'data')
)

if __name__ == "__main__":
    app.run_server(debug=True)