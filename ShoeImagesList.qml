import QtQuick 2.0


Item {

    property Rectangle view1               : null;

    Rectangle {
        id: listBackground
        anchors.verticalCenter: view1.verticalCenter
        visible: true;
        width: 170 * scaleX
        height: 1080 * scaleY
        color: "#DDDDDD"

        Item {
            id: listContainer
            anchors.fill: parent

            ListView {
                id: listView
                height: listBackground.height
                width: listBackground.width
                orientation: "Vertical"

                anchors {
                    fill: parent
                    left: view1.left
                    leftMargin: 20 * scaleX
                }

                model: myModel
                delegate: Component {

                    Image {
                        id: thumbnail
                        source: "file:///" + model.modelData.source
                        width: 140 * scaleX
                        height: 140 * scaleY

                        MouseArea {
                            anchors.fill: parent
                            onClicked: mainImage.source = thumbnail.source
                        }
                    }
                }

                focus: true
                spacing: 5
                visible: true
            }

            ScrollBar {
                    id: verticalScrollBar
                    flickable: listView
                }
        }
    }

    Image {
        id: mainImage
        width: 600 * scaleX
        height: 900  * scaleY
        clip: true
        visible: true
        fillMode: Image.PreserveAspectFit
        smooth: true
        source: "file:///" + imagesPath

        anchors.verticalCenter: view1.verticalCenter
        anchors.left: listBackground.right
    }

}
