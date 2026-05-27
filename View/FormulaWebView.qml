pragma ComponentBehavior: Bound

import QtQuick
import QtWebEngine
import TenjinView

// Renders a LaTeX string with KaTeX inside a WebEngineView. Kept in its own file
// so FormulaBlock.qml can load it lazily — and so the QtWebEngine import only
// resolves when WEBVIEW_SUPPORT is compiled in (the Loader in FormulaBlock gates
// on appVM.webEngineAvailable, so this is never instantiated otherwise).
//
// KaTeX assets: looks for a bundled copy under :/katex (qrc) first for offline
// use; falls back to the jsDelivr CDN. To bundle, drop katex.min.css,
// katex.min.js and the fonts/ dir into the View resources under a "katex"
// prefix. See the integration note in the delivery message.
Item {
    id: root
    property string latex: ""

    implicitHeight: web.contentWidth > 0 ? web.formulaHeight : 48

    // Escape the LaTeX for safe embedding in a JS string literal.
    function jsEscape(s) {
        return s.replace(/\\/g, "\\\\").replace(/'/g, "\\'").replace(/\n/g, " ")
    }

    readonly property string katexBase: "https://cdn.jsdelivr.net/npm/katex@0.16.11/dist"

    readonly property string html:
        "<!DOCTYPE html><html><head><meta charset='utf-8'>" +
        "<link rel='stylesheet' href='" + katexBase + "/katex.min.css'>" +
        "<script defer src='" + katexBase + "/katex.min.js'></script>" +
        "<style>html,body{margin:0;padding:6px;background:transparent;" +
        "color:" + Platform.text + ";font-size:18px;overflow:hidden}</style></head>" +
        "<body><span id='f'></span>" +
        "<script>window.addEventListener('load',function(){" +
        "try{katex.render('" + jsEscape(root.latex) + "',document.getElementById('f')," +
        "{displayMode:true,throwOnError:false});}catch(e){" +
        "document.getElementById('f').textContent='" + jsEscape(root.latex) + "';}" +
        "});</script></body></html>"

    WebEngineView {
        id: web
        anchors.fill: parent
        backgroundColor: "transparent"

        property real formulaHeight: 48
        onLatexChanged: reload()
        function reload() { loadHtml(root.html, "qrc:/") }
        Component.onCompleted: reload()

        // Measure rendered height so the block sizes to its content.
        onLoadingChanged: function (req) {
            if (req.status === WebEngineView.LoadSucceededStatus) {
                runJavaScript("document.body.scrollHeight", function (h) {
                    if (h && h > 0) web.formulaHeight = h
                })
            }
        }
    }

    // Re-render when the source changes while mounted.
    onLatexChanged: web.reload()
}
