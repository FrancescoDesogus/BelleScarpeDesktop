import QtQuick 2.0

Rectangle
{
    id: container

    width: parent.width
    height: parent.height


    property bool isClickAllowed: true


    signal transitionFromRFIDincoming()

    signal transitionFromRFIDStarted()
    signal transitionFromRFIDEnded()

    signal errorOccurred();


    FontLoader { id: metroFont; source: "qrc:segeo-wp.ttf" }

    Rectangle {
        id: topRectangle

        width: container.width
        height: 180 * scaleY

        anchors.top: container.top

        color: "#9FB7BF"

        Text {
            id: shopName
            text: "BelleScarpeCod"
            font.family: metroFont.name
            font.pointSize: 50
    //        font.letterSpacing: 1.2
//            color: "#111111"
            color: "white"
            anchors.left: topRectangle.left
            anchors.leftMargin: 400 * scaleX
            anchors.bottom: topRectangle.bottom

//            width: topRectangle.width - (10 * scaleX)

            elide: Text.ElideRight
        }
    }

    Text {
        id: text
        text: "Appoggia una scarpa sopra il lettore per visualizzare informazioni su di essa"
        font.family: metroFont.name
        font.pointSize: 20
        color: "#111111"

        anchors.top: topRectangle.bottom
        anchors.topMargin: 160 * scaleY

        anchors.horizontalCenter: container.horizontalCenter
//            width: topRectangle.width - (10 * scaleX)

        elide: Text.ElideRight
    }

    Text {
        id: errorText
        text: "Non è stato possibile recuperare la scarpa scelta!"
        font.family: metroFont.name
        font.pointSize: 17
        color: "#f97474"

        opacity: 0

        anchors.top: text.bottom
        anchors.topMargin: 260 * scaleY

        anchors.horizontalCenter: container.horizontalCenter

        elide: Text.ElideRight

        Behavior on opacity {
            NumberAnimation {
                duration: 250
            }
        }
    }


    Rectangle {
        id: bottomRectangle

        width: container.width
        height: 100 * scaleY

        anchors.bottom: container.bottom


        color: "#9FB7BF"
    }


    Rectangle {
        id: blackBackgroundRectangle

        property LoadIndicator loadIndicator: busyIndicator

        anchors.fill: parent

        color: "black"

        opacity: 0
        visible: false

        Behavior on opacity {
            NumberAnimation {
                duration: 250
            }
        }

        LoadIndicator {
            id: busyIndicator

            anchors.fill: parent
        }

    }


    transform: Rotation {
        origin.x: 0
        origin.y: container.height/2

        axis.x: 0
        axis.y: 1
        axis.z: 0

        angle: 0
    }

    onErrorOccurred: {
        errorText.opacity = 1

        blackBackgroundRectangle.visible = false
        blackBackgroundRectangle.opacity = 0
        blackBackgroundRectangle.loadIndicator.running = false
    }



    onTransitionFromRFIDincoming: {
        blackBackgroundRectangle.visible = true
        blackBackgroundRectangle.opacity = 0.5
        blackBackgroundRectangle.loadIndicator.running = true

        errorText.opacity = 0
    }

    onTransitionFromRFIDStarted: {
        blackBackgroundRectangle.visible = false
        blackBackgroundRectangle.opacity = 0
        blackBackgroundRectangle.loadIndicator.running = false
    }
}
