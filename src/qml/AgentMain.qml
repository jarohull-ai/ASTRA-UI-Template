// ASTRA UI template — agent console.
//
// Same glass language as the dashboard shell, arranged for a conversation:
// session rail, transcript with streamed replies and tool traces, a runtime
// panel on the right and the shared state strip along the bottom.
//
// Context properties: `feed` (AgentModel) and `i18n` (Translator).
import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

ApplicationWindow {
    id: win
    width: 1180; height: 850
    minimumWidth: 780; minimumHeight: 560
    visible: true
    title: qsTr("ASTRA · Agent console")
    color: "transparent"
    Material.theme: Material.Dark
    Material.accent: feed.accent

    property color accent: feed.accent
    property string clockText: ""
    property int revision: 0

    Connections { target: feed; function onMessagesChanged() { win.revision++ } }
    Timer {
        interval: 1000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: win.clockText = new Date().toLocaleTimeString(Qt.locale(), "HH:mm:ss")
    }
    Shortcut { sequence: "Q"; onActivated: Qt.quit() }
    Shortcut { sequence: "Escape"; onActivated: feed.stop() }
    Shortcut { sequence: "N"; onActivated: feed.newSession() }
    Shortcut { sequence: "?"; onActivated: help.open() }
    Shortcut {
        sequence: "Ctrl+L"
        onActivated: { input.forceActiveFocus(); input.selectAll() }
    }

    Rectangle {
        anchors.fill: parent
        radius: 22
        color: Qt.rgba(.018, .035, .055, feed.glass)
        border.color: "#31444d"
        clip: true

        Rectangle {
            x: parent.width * .5; y: -420; width: 900; height: 900; radius: 450; opacity: .10
            gradient: Gradient {
                GradientStop { position: 0; color: win.accent }
                GradientStop { position: 1; color: "transparent" }
            }
        }
        Rectangle {
            x: -300; y: parent.height - 300; width: 750; height: 750; radius: 375; opacity: .08
            gradient: Gradient {
                GradientStop { position: 0; color: "#588bff" }
                GradientStop { position: 1; color: "transparent" }
            }
        }
        Canvas {
            anchors.fill: parent; opacity: .17
            onWidthChanged: requestPaint(); onHeightChanged: requestPaint()
            onPaint: {
                var c = getContext("2d"); c.reset(); c.fillStyle = "#5f8797";
                for (var x = 18; x < width; x += 28)
                    for (var y = 18; y < height; y += 28) c.fillRect(x, y, 1, 1);
            }
        }

        ColumnLayout {
            anchors.fill: parent; anchors.margins: 28; spacing: 16

            // ---------- header ----------
            RowLayout {
                Layout.fillWidth: true; spacing: 14
                Rectangle {
                    width: 38; height: 38; radius: 11; color: "#163136"; border.color: win.accent
                    Text {
                        anchors.centerIn: parent; text: "\u039B"
                        font.pixelSize: 26; font.weight: Font.Light; color: win.accent
                    }
                }
                ColumnLayout {
                    spacing: 1
                    Text { text: qsTr("A S T R A   A G E N T"); font.pixelSize: 19; font.weight: Font.DemiBold; color: "#eff9ff" }
                    Text {
                        text: qsTr("AGENT CONSOLE / LOCAL RUNTIME")
                        font.pixelSize: 9; font.letterSpacing: 1.6; color: "#7898a5"
                    }
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: win.clockText; color: "#9bb8c2"; font.family: "monospace"
                    font.pixelSize: 14; visible: win.width > 940
                }
                Rectangle {
                    implicitWidth: modelText.implicitWidth + 24; implicitHeight: 26; radius: 13
                    color: "#122d2b"; border.color: "#285a50"
                    Text {
                        id: modelText
                        anchors.centerIn: parent; text: feed.modelLabel
                        color: win.accent; font.family: "monospace"; font.pixelSize: 10
                    }
                }
                Button {
                    text: qsTr("New session")
                    onClicked: { feed.newSession(); input.forceActiveFocus() }
                }
                ToolButton {
                    text: "\u2699"; font.pixelSize: 20; onClicked: settings.open()
                    ToolTip.text: qsTr("Language"); ToolTip.visible: hovered
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: "#25414a" }

            // ---------- body ----------
            RowLayout {
                Layout.fillWidth: true; Layout.fillHeight: true; spacing: 14

                // sessions
                ColumnLayout {
                    Layout.preferredWidth: 208; Layout.maximumWidth: 224
                    Layout.fillHeight: true; spacing: 8
                    visible: win.width > 1000
                    Text {
                        text: qsTr("SESSIONS"); color: "#52737e"
                        font.family: "monospace"; font.pixelSize: 9; font.letterSpacing: 1.4
                    }
                    Repeater {
                        model: feed.sessions
                        Rectangle {
                            required property var modelData
                            required property int index
                            Layout.fillWidth: true
                            implicitHeight: 62
                            radius: 12
                            color: Qt.rgba(.035, .065, .085, feed.glass)
                            border.width: 1
                            border.color: index === feed.current
                                          ? Qt.rgba(win.accent.r, win.accent.g, win.accent.b, .45)
                                          : "#1e3a43"
                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 11
                                spacing: 2
                                RowLayout {
                                    spacing: 6
                                    Rectangle {
                                        width: 5; height: 5; radius: 3
                                        color: modelData.dot === "active" ? win.accent : "#4d6b76"
                                    }
                                    Text {
                                        text: modelData.title
                                        color: index === feed.current ? "#eaf6fb" : "#a9c2cc"
                                        font.pixelSize: 12; elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                    Text {
                                        text: modelData.updated
                                        color: "#52737e"; font.family: "monospace"; font.pixelSize: 9
                                    }
                                }
                                Text {
                                    text: modelData.subtitle
                                    color: "#6f8f99"; font.pixelSize: 10
                                    elide: Text.ElideRight; Layout.fillWidth: true
                                }
                            }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: feed.pickSession(index) }
                        }
                    }
                    Item { Layout.fillHeight: true }
                    Text {
                        Layout.fillWidth: true
                        text: qsTr("Layout, glass and the strip come from ASTRA UI Template.")
                        color: "#4f6f7a"; font.pixelSize: 10; wrapMode: Text.WordWrap
                    }
                }

                // transcript + composer
                ColumnLayout {
                    Layout.fillWidth: true; Layout.fillHeight: true; spacing: 10

                    Rectangle {
                        Layout.fillWidth: true; Layout.fillHeight: true
                        radius: 18
                        color: Qt.rgba(.035, .065, .085, feed.glass * .92)
                        border.color: Qt.rgba(win.accent.r, win.accent.g, win.accent.b, .16)
                        clip: true

                        ListView {
                            id: transcript
                            objectName: "transcriptView"
                            anchors.fill: parent
                            anchors.margins: 14
                            spacing: 8
                            bottomMargin: 10
                            model: feed.messages
                            boundsBehavior: Flickable.StopAtBounds
                            delegate: ChatBubble {
                                required property int index
                                message: { win.revision; return feed.messageAt(index) }
                                accent: win.accent
                                glass: feed.glass
                            }
                            // Follow the stream: re-pin to the bottom while text is
                            // still arriving, because delegate heights settle a frame
                            // after the model changes.
                            Timer {
                                interval: 120; running: feed.streaming; repeat: true
                                onTriggered: transcript.positionViewAtEnd()
                            }
                            onContentHeightChanged: positionViewAtEnd()
                            onCountChanged: Qt.callLater(positionViewAtEnd)
                            Connections {
                                target: feed
                                function onMessagesChanged() { Qt.callLater(transcript.positionViewAtEnd) }
                                // The final layout pass lands a frame after the stream
                                // closes, so pin once more when the dust settles.
                                function onStreamingChanged() { pinTimer.restart() }
                            }
                            Timer {
                                id: pinTimer; interval: 90
                                onTriggered: transcript.positionViewAtEnd()
                            }
                            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                        }
                    }

                    // composer
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 54
                        radius: 16
                        color: Qt.rgba(.035, .065, .085, feed.glass)
                        border.color: input.activeFocus
                                      ? Qt.rgba(win.accent.r, win.accent.g, win.accent.b, .55)
                                      : "#25414a"

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 16
                            anchors.rightMargin: 10
                            spacing: 10
                            Text {
                                text: "\u203A"; color: win.accent
                                font.family: "monospace"; font.pixelSize: 18
                            }
                            TextField {
                                id: input
                                Layout.fillWidth: true
                                placeholderText: feed.streaming ? qsTr("streaming… press Esc to stop")
                                                                : qsTr("Ask the agent, or type status / test / patch")
                                font.pixelSize: 13
                                background: Item {}
                                color: "#e7f3f8"
                                onAccepted: {
                                    if (feed.streaming) return;
                                    if (text.trim().length === 0) return;
                                    feed.send(text);
                                    text = "";
                                }
                                Component.onCompleted: forceActiveFocus()
                            }
                            Button {
                                text: feed.streaming ? qsTr("Stop") : qsTr("Send")
                                highlighted: !feed.streaming
                                onClicked: {
                                    if (feed.streaming) { feed.stop(); return; }
                                    if (input.text.trim().length === 0) return;
                                    feed.send(input.text);
                                    input.text = "";
                                    input.forceActiveFocus();
                                }
                            }
                        }
                    }
                    Text {
                        text: feed.hint; color: "#52737e"
                        font.family: "monospace"; font.pixelSize: 9
                    }
                }

                // runtime panel
                ColumnLayout {
                    Layout.preferredWidth: 236; Layout.maximumWidth: 260
                    Layout.fillHeight: true; spacing: 10
                    visible: win.width > 860

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: runtime.implicitHeight + 32
                        radius: 16
                        color: Qt.rgba(.035, .065, .085, feed.glass)
                        border.color: Qt.rgba(win.accent.r, win.accent.g, win.accent.b, .18)
                        ColumnLayout {
                            id: runtime
                            anchors.fill: parent
                            anchors.margins: 16
                            spacing: 10
                            Text {
                                text: qsTr("RUNTIME"); color: "#52737e"
                                font.family: "monospace"; font.pixelSize: 9; font.letterSpacing: 1.4
                            }
                            Text {
                                text: feed.model; color: "#e7f3f8"; font.pixelSize: 13
                                elide: Text.ElideRight; Layout.fillWidth: true
                            }
                            RowLayout {
                                Layout.fillWidth: true
                                Text {
                                    text: qsTr("CONTEXT"); color: "#52737e"
                                    font.family: "monospace"; font.pixelSize: 9
                                }
                                Item { Layout.fillWidth: true }
                                Text {
                                    text: Math.round(100 * feed.contextUsed / Math.max(1, feed.contextMax)) + "%"
                                    color: win.accent; font.family: "monospace"; font.pixelSize: 10
                                }
                            }
                            Rectangle {
                                Layout.fillWidth: true; height: 5; radius: 3; color: "#16333b"
                                Rectangle {
                                    height: parent.height; radius: 3
                                    width: parent.width * Math.min(1, feed.contextUsed / Math.max(1, feed.contextMax))
                                    color: win.accent
                                }
                            }
                            GridLayout {
                                columns: 2; columnSpacing: 14; rowSpacing: 6; Layout.fillWidth: true
                                Repeater {
                                    model: [
                                        { k: qsTr("TOKENS IN"), v: feed.tokensIn },
                                        { k: qsTr("TOKENS OUT"), v: feed.tokensOut },
                                        { k: qsTr("TURNS"), v: feed.turns },
                                        { k: qsTr("TOOL RUNS"), v: feed.toolRuns }
                                    ]
                                    ColumnLayout {
                                        required property var modelData
                                        spacing: 0
                                        Text {
                                            text: modelData.k; color: "#52737e"
                                            font.family: "monospace"; font.pixelSize: 9
                                        }
                                        Text {
                                            text: modelData.v; color: "#e7f3f8"
                                            font.pixelSize: 16; font.weight: Font.Light
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: tools.implicitHeight + 32
                        radius: 16
                        color: Qt.rgba(.035, .065, .085, feed.glass)
                        border.color: "#1e3a43"
                        ColumnLayout {
                            id: tools
                            anchors.fill: parent
                            anchors.margins: 16
                            spacing: 9
                            Text {
                                text: qsTr("TOOLS"); color: "#52737e"
                                font.family: "monospace"; font.pixelSize: 9; font.letterSpacing: 1.4
                            }
                            Repeater {
                                model: feed.tools
                                RowLayout {
                                    required property var modelData
                                    Layout.fillWidth: true
                                    spacing: 8
                                    Rectangle {
                                        width: 5; height: 5; radius: 3
                                        color: modelData.enabled ? win.accent : "#4d6b76"
                                    }
                                    Text {
                                        text: modelData.name; color: "#c4dae2"
                                        font.family: "monospace"; font.pixelSize: 11
                                        Layout.fillWidth: true
                                    }
                                    Text {
                                        text: modelData.enabled ? qsTr("on") : qsTr("off")
                                        color: modelData.enabled ? win.accent : "#6b7683"
                                        font.family: "monospace"; font.pixelSize: 9
                                    }
                                }
                            }
                        }
                    }
                    Item { Layout.fillHeight: true }
                }
            }

            // ---------- state strip ----------
            StateStrip {
                id: stripPanel
                readonly property bool hasData: feed.strip && Object.keys(feed.strip).length > 0
                Layout.fillWidth: true
                Layout.preferredHeight: hasData ? 136 : 0
                visible: hasData
                glass: feed.glass; accent: win.accent
                s: { win.revision; return feed.strip }
            }

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: qsTr("LOCAL RUNTIME  /  demo script  /  no network calls")
                    color: "#678893"; font.family: "monospace"; font.pixelSize: 10
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: qsTr("ESC  stop     Ctrl+L  focus input     N  new session     ?  help")
                    color: "#678893"; font.pixelSize: 10
                }
            }
        }
    }

    Drawer {
        id: settings
        edge: Qt.RightEdge; width: 320; height: win.height
        background: Rectangle { color: "#101c24"; border.color: "#36515c" }
        ColumnLayout {
            anchors.fill: parent; anchors.margins: 24; spacing: 14
            Text { text: qsTr("Console settings"); color: "#e6f7ff"; font.pixelSize: 22 }
            Text { text: qsTr("Language"); color: win.accent; font.pixelSize: 13 }
            ComboBox {
                Layout.fillWidth: true
                readonly property var codes: ["auto", "en", "pl"]
                model: [qsTr("Automatic (Omarchy)"), "English", "Polski"]
                currentIndex: Math.max(0, codes.indexOf(i18n.choice))
                onActivated: i18n.choice = codes[currentIndex]
            }
            Text {
                Layout.fillWidth: true; wrapMode: Text.WordWrap
                text: qsTr("Catalogs live in src/i18n. Add a language by dropping <code>.json next to pl.json.")
                color: "#8eaab5"; font.pixelSize: 12
            }
            Item { Layout.fillHeight: true }
            Button { text: qsTr("Close"); onClicked: settings.close() }
        }
    }

    Popup {
        id: help
        anchors.centerIn: parent; width: 400; modal: true; padding: 24
        ColumnLayout {
            spacing: 12
            Text { text: qsTr("Agent console controls"); color: "white"; font.pixelSize: 20 }
            Text {
                text: qsTr("TYPE  a prompt, ENTER sends\nESC  stops the stream\nN  starts a new session\nCtrl+L  focus the input\n\nReplies come from a canned script in AgentModel::answerFor(). Tool rows are simulated.")
                color: "#b9d0d9"; font.pixelSize: 13
            }
            Button { text: qsTr("Got it"); onClicked: help.close() }
        }
    }
}
