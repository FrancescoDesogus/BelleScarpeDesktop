import QtQuick 2.0

Rectangle {
    id: view1
    color: "#EEEEEE"
    width: 1920 * scaleX
    height: 1080 * scaleY

    ShoeImagesList {
        id: imagesList
        view1: view1

    }
}
