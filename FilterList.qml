import QtQuick 2.0

Rectangle {
    id: container

    property variant listModel;

    FontLoader {
        id: metroFont;
        source: "qrc:segeo-wp.ttf"
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
            height: itemText.height * scaleY


            Text {
                id: itemText
                text: modelData
                font.family: metroFont.name
                font.pointSize: 12
                font.weight: Font.Normal
                font.letterSpacing: 1.2
                color: "#9FB7BF"
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

    //Timer che si occupa di far sparire la ScrollBar dopo un tot di tempo dal termine dell'input utente
    Timer {
        id: fadeOutTimer
        interval: 1000 //1 secondo
        running: true //Faccio partire il timer all'inizio del programma
        repeat: false

        //Quando scatta il timer, porto l'opacità della barra a zero
        onTriggered: verticalScrollBar.barOpacity = 0
    }
}
