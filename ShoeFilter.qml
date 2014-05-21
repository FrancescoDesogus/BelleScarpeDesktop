import QtQuick 2.0

Rectangle {
    id: container


    property real filterPanelWidth: 800 * scaleX
    property real filterPanelHeight: 500 * scaleY

    property real draggingRectangleWidth: 300 * scaleX
    property real draggingRectangleHeight: 25 * scaleY

    Rectangle {
        id: draggingRectangle

        width: draggingRectangleWidth
        height: draggingRectangleHeight

        color: "red"
        radius: 6

        Behavior on y {
            NumberAnimation {
                duration: 500
            }
        }

        Rectangle {
            anchors.bottom: parent.bottom
            width: parent.width
            height: 10 * scaleY
            color: parent.color
        }

        Text {
            text: "<"
            rotation: 90
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Text {
            text: "Filtra Scarpe"
            anchors.bottom: parent.bottom
    //            anchors.bottomMargin: 2
            anchors.horizontalCenter: parent.horizontalCenter
        }

        MouseArea {
            id: clickable
            anchors.fill: filterPanel

            drag.target: filterPanel
            drag.axis: Drag.YAxis

            onPressed: {
                filterPanel.anchors.bottom = undefined
                filterPanel.anchors.horizontalCenter = undefined
            }

            onReleased: {
                filterPanel.anchors.bottom = container.bottom
                filterPanel.anchors.horizontalCenter = container.horizontalCenter
            }
        }
    }

    Rectangle {
        id: filterPanel

        width: filterPanelWidth
        height: filterPanelHeight

//        x: 100
//        y: 100

        color: "black"

        anchors.top: draggingRectangle.bottom
    }
}
