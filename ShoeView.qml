import QtQuick 2.0

Rectangle {
    width: 1920 * scaleX
    height: 1080 * scaleY

    Rectangle {
        id: backButton
        x: 30
        y: 30
        width: 200 * scaleX
        height: 100 * scaleY
        border.width: 3
        radius: 5
        color: "green";

        Text {
            text: "back"
            color: "black"
            anchors.centerIn: parent
        }

        MouseArea {
             anchors.fill: parent
             onClicked: {
                 myViewManager.goBack();
             }
         }
    }

    Rectangle {
        anchors.left: backButton.right
        anchors.verticalCenter: backButton.verticalCenter
        width: 200 * scaleX
        height: 100 * scaleY
        border.width: 3
        radius: 5
        color: "lightgreen";

        Text {
            text: "next"
            color: "black"
            anchors.centerIn: parent
        }

        MouseArea {
             anchors.fill: parent
             onClicked: {
                 mainWindow.addView();
             }
         }
    }

    Rectangle {
        x: parent.width / 2
        y: parent.height / 2
        width: 200
        height: 200


        Text {
            text: qsTr("Don't you fucking dare click me")
            anchors.centerIn: parent
            font.bold: true
        }

        MouseArea {
             anchors.fill: parent
             onClicked: {
                 firstWindow.changeScreen("main.qml");
             }
         }
    }
}
