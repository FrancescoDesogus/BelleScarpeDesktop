import QtQuick 2.0

Rectangle {
    id: container

    property variant listModel;
    property string backgroundColor: "white"
    property string containerBackgroundColor: "grey"

    property string title: "Titolo"

    property var selectedElements: [];

    //Altezza e larghezza sono definite al momento della definizione

    color: listContainer.visible ? "#eaeaea" : containerBackgroundColor


    FontLoader {
        id: metroFont;
        source: "qrc:segeo-wp.ttf"
    }

    Text {
        id: filterTitle

        anchors.verticalCenter: container.verticalCenter
        anchors.left: container.left
        anchors.leftMargin: 20 * scaleX

        text: title
        color: listContainer.visible ? "black" : textColor
        font.family: metroFont.name
        font.pointSize: 14
        font.letterSpacing: 1.3
        font.weight: Font.Bold
    }

    Text {
        id: filterArrow

        anchors.right: container.right
        anchors.rightMargin: 5 * scaleX
        anchors.verticalCenter: container.verticalCenter

        text: "<"
        rotation: listContainer.visible ? 270 : 90
        color: textColor
        font.family: metroFont.name
        font.pointSize: 14
        font.letterSpacing: 1.3
        font.weight: Font.Bold
    }

    MouseArea {
        anchors.fill: parent

        onClicked: {
            if(!listContainer.visible)
                openList()
            else
                closeList()
        }
    }

    Rectangle {
        id: listContainer

        width: container.width
        height: 250 * scaleY

        anchors.bottom: container.top
        color: backgroundColor


        transformOrigin: Item.Bottom

        visible: false

        opacity: 0


        Behavior on opacity {
            NumberAnimation {
                duration: 250

                onRunningChanged: {
                    if(!running && listContainer.opacity == 0)
                        listContainer.visible = false
                }
            }
        }

        ListView {
            id: filterList

            anchors.fill: parent

            model: listModel

            clip: true

            boundsBehavior: Flickable.StopAtBounds

            orientation: ListView.Vertical
            spacing: 2 * scaleY


            //Il delegate usa un component creato ad hoc
            delegate: Rectangle {
                id: textContainer

                width: container.width
                height: itemText.height

                color: "transparent"

                Text {
                    id: itemText
                    text: modelData
                    font.family: metroFont.name
                    font.pointSize: 12
                    font.weight: Font.Normal
                    font.letterSpacing: 1.2
    //                color: "#9FB7BF"
                    color: "white"
                    anchors.left: parent.left
                    anchors.leftMargin: 15 * scaleX
                    anchors.top: parent.top
                    width: container.width - (10 * scaleX)
                    elide: Text.ElideRight
                }


                MouseArea {
                    anchors.fill: parent;

                    onClicked: {
                        textContainer.color = "ligthblue"
                    }

                }
            }


            //Quando inizia il movimento della lista da parte dell'utente devo bloccare il timer che fa scomparire la scrollbar
            onMovementStarted: {
                //Eseguo il codice solo se la barra è visibile
                if(verticalScrollBar.visible)
                {
                    //Rimetto l'opacità della barra al valore di default, qualora non fosse già così
                    verticalScrollBar.barOpacity = verticalScrollBar.defaultOpacity

                    //Termino il timer, qualora fosse in esecuzione
                    fadeOutTimer.stop()
                }
            }

            //Quando finisce il movimento della lista da parte dell'utente devo mandare in esecuzione il timer
            //che fa scomparire la scrollbar
            onMovementEnded: {
                if(verticalScrollBar.visible)
                    fadeOutTimer.restart()
            }
        }


        ScrollBar {
            id: verticalScrollBar
            flickable: filterList
            position: "left"
            handleSize: 3
            listBackgroundColor: backgroundColor
            handleColorNormal: "grey"
            handleColorPressed: "red"

            onBarClicked: {
                //Rimetto l'opacità della barra al valore di default, qualora non fosse già così
                verticalScrollBar.barOpacity = verticalScrollBar.defaultOpacity

                //Termino il timer, qualora fosse in esecuzione
                fadeOutTimer.stop()

                //Notifico l'esterno che è avvenuto un click
                container.touchEventOccurred()
            }

            onBarReleased: {
                if(verticalScrollBar.visible)
                    fadeOutTimer.restart()
            }
        }
    }

    //Timer che si occupa di far sparire la ScrollBar dopo un tot di tempo dal termine dell'input utente
    Timer {
        id: fadeOutTimer
        interval: 1000 //1 secondo
        running: true //Faccio partire il timer all'inizio del programma
        repeat: false

        //Quando scatta il timer, porto l'opacità della barra a zero
        onTriggered: verticalScrollBar.barOpacity = 0
    }

    function openList()
    {
        listContainer.visible = true
        listContainer.opacity = 1;
    }

    function closeList()
    {
        listContainer.opacity = 0;
    }
}
