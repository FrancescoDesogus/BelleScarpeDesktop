import QtQuick 2.0
//import QtGraphicalEffects 1.0

Rectangle {
    id: container

    property real filterPanelWidth: 1920 * scaleX
    property real filterPanelHeight: 200 * scaleY

    property real draggingRectangleWidth: 300 * scaleX
    property real draggingRectangleHeight: 30 * scaleY

    property int startY: 0

    property Rectangle backgroundRectangle

    Rectangle {
        id: draggingRectangle

        width: draggingRectangleWidth
        height: draggingRectangleHeight

        color: "red"
        radius: 6

        anchors.bottom: container.bottom
        anchors.horizontalCenter: container.horizontalCenter

        Behavior on y {
            NumberAnimation {
                easing.type: Easing.OutSine
                duration: 150
            }
        }

        onYChanged:  {
            //L'opacità varia in base alla y del mouse, dopo la pressione
            backgroundRectangle.opacity = Math.abs((draggingRectangle.y / filterPanelHeight)/(3))
        }

        Rectangle {
            anchors.bottom: draggingRectangle.bottom
            width: parent.width
            height: 10 * scaleY
            color: parent.color
        }

        Text {
            id: arrow
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
            anchors.fill: draggingRectangle

            drag.target: draggingRectangle
            drag.axis: Drag.YAxis
            drag.maximumY: -draggingRectangle.height
            drag.minimumY: -filterPanelHeight

            onPressed: {
                startY = draggingRectangle.y
                draggingRectangle.anchors.bottom = undefined

                backgroundRectangle.visible = true


                if(startY == - Math.floor(draggingRectangle.height)){
                        backgroundRectangle.opacity = 0
                }
            }

            onReleased: {
                //Accenno il movimento verso il basso
                if(startY == - (Math.floor(filterPanelHeight))){
                    if(startY <= Math.round(draggingRectangle.y) + 1){
                        arrow.text = "<"
                        draggingRectangle.y = -draggingRectangle.height

                        //Faccio scomparire il rettangolo scuro sullo sfondo
                        backgroundRectangle.visible = false
                        backgroundRectangle.opacity = 0
                    }else{
                        arrow.text = ">"
                        draggingRectangle.y = 0 - filterPanelHeight
                    }
                }

                //Accenno il movimento verso l'alto
                if(startY == - (Math.floor(draggingRectangle.height))){
                    if(startY < Math.round(draggingRectangle.y)){
                        //se non ho sollevato il rettangolo, riabbasso il pannello
                        arrow.text = "<"
                        draggingRectangle.y = -draggingRectangle.height

                        //Faccio scomparire il rettangolo scuro sullo sfondo
                        backgroundRectangle.visible = false
                        backgroundRectangle.opacity = 0
                    }else if(startY >= Math.round(draggingRectangle.y)){
                        //Se invece la y iniziale è maggiore di quella attuale (e quindi il rettangolo è più in alto, sollevo il pannello
                        arrow.text = ">"
                        draggingRectangle.y = 0 - filterPanelHeight
                    }
                }
            }
        }
    }

    Rectangle {
        id: filterPanel

        width: filterPanelWidth
        height: filterPanelHeight

//        x: 100
//        y: 100

        color: "green"

        anchors.top: draggingRectangle.bottom
        anchors.horizontalCenter: container.horizontalCenter

        Text {
            text: "PENE"
            font.pointSize: 80
            font.letterSpacing: 20
            font.weight: Font.Bold
            color: "white"
            anchors.centerIn: filterPanel

        }
    }
}
