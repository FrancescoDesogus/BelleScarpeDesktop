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


    Text {
        text: "I'm a timeout screen, pleased to make your acquaintance."

        anchors.centerIn: parent
    }


    transform: Rotation {
        origin.x: 0
        origin.y: container.height/2

        axis.x: 0
        axis.y: 1
        axis.z: 0

        angle: 0
    }

    LoadIndicator {
        id: loadIndicator

        anchors.fill: parent
    }

    onTransitionFromRFIDincoming: {
        loadIndicator.running = true
    }

    onTransitionFromRFIDStarted: {
        loadIndicator.running = false
    }
}
