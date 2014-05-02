import QtQuick 2.0


Rectangle {
    property int thumbnailWidth: 140
    property int thumbnailHeight: 140
    property int thumbnailHalvedHeight: thumbnailHeight / 2


    id: superContainer
//    property Rectangle view1               : null;
//    width: 600 * scaleX
//    anchors.verticalCenter: parent.verticalCenter
    height: parent.height
//    width: parent.width
    width: 800 * scaleX //Deve essere somma della larghezza della tuhmbnail list e dell'immagine della (bella) scarpa


    Rectangle {
        id: listBackground
//        anchors.verticalCenter: view1.verticalCenter
        anchors.verticalCenter: superContainer.verticalCenter
        visible: true;
        width: 170 * scaleX
        height: 1080 * scaleY
        color: "#DDDDDD"



        Item {
            id: listContainer
            anchors.fill: parent
//            y: calculateListPosition()


//            Rectangle {
//                id: prova
////                height: (500 / listView.count) * scaleY
////                height: (superContainer.height/2 - 70*listView.count)
//                height: calculateListPosition()
//                width: parent.width
//                visible: false
//                z: -1
//            }

            ListView {
                id: listView
                height: listBackground.height
//                height: thumbnailHeight * listView.count //Con questo non si attiva la scrollbar
                width: listBackground.width
                orientation: "Vertical"
                y: calculateListPosition()
//                clip: true


                anchors {
//                    fill: parent
//                    left: view1.left
//                    left: superContainer.left
//                    top: prova.bottom
                    leftMargin: 20 * scaleX
                }

                model: myModel
                delegate: Component {

                    Image {
                        id: thumbnail
                        source: "file:///" + model.modelData.source
                        width: thumbnailHeight * scaleX
                        height: thumbnailWidth * scaleY

                        MouseArea {
                            anchors.fill: parent
                            onClicked: console.log(listView.visibleArea.heightRatio)
//                            onClicked: mainImage.source = thumbnail.source
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

        anchors.verticalCenter: parent.verticalCenter
        anchors.left: listBackground.right
    }


    function calculateListPosition()
    {
        var listHalvedHeigth = thumbnailHalvedHeight * listView.count

        if(listHalvedHeigth*2 > superContainer.height)
            return 0
        else
            return (superContainer.height/2 - listHalvedHeigth)
    }

}
