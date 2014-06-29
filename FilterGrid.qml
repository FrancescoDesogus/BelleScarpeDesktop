import QtQuick 2.0


/*
 * Questo component è usato per selezionare i filtri da applicare nella ricerca delle scarpe e rappresenta sostanzialmente
 * una combo box al cui interno è contenuto una GridView per selezionare gli elementi
 */
Rectangle {
    id: container

    //Sringa che compare quando la combo box è chiusa
    property string title: "Titolo"

    //Model che contiene gli elementi selezionabili da mostrare nella combo box
    property variant listModel;

    //Array contenente gli elementi selezionati in un dato momento; viene recuperato quando il bottone per filtrare è premuto
    property var selectedElements: [];


    property string textColor: "black"
    property string backgroundColor: "white"
    property string containerBackgroundColor: "grey"


    //Proprietà dimensionali della singola cella della griglia
    property int gridCellHeight: 80 * scaleY
    property int gridCellWidth: 80 * scaleX

    //Proprietà che decide quale delegate utilizzare
    property bool colorGrid: true


    /**************************************************************
     * Signal emessi verso l'esterno
     **************************************************************/

    //Signal che scatta quando viene rilevato un qualsiasi evento touch nell'interfaccia; serve per riazzerare il timer
    //che porta alla schermata di partenza dopo un tot di tempo di inattività
    signal touchEventOccurred()


    color: listContainer.visible ? "#eaeaea" : containerBackgroundColor
    radius: 2

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
        anchors.rightMargin: 16 * scaleX
        anchors.verticalCenter: container.verticalCenter

        text: "<"
        rotation: 90

        color: listContainer.visible ? "black" : textColor
        font.family: metroFont.name
        font.pointSize: 14
        font.letterSpacing: 1.2
        font.weight: Font.Bold

        Behavior on rotation {
            NumberAnimation {
                duration: 100
            }
        }
    }

    MouseArea {
        id: containerMouseArea
        anchors.fill: parent

        onClicked: {
            if(!listContainer.visible)
                openList()
            else
                closeList()

            //Segnalo all'esterno che c'è stato un evento touch
            container.touchEventOccurred()
        }

        onPressed: {
            filterArrow.color = "black"
            filterTitle.color = "black"
            container.color = "white"
        }

        onReleased: {

            if(containerMouseArea.containsMouse){
                if(listContainer.visible){
                    filterArrow.color = textColor
                    filterTitle.color = textColor
                    container.color = containerBackgroundColor
                }
                else {
                    filterArrow.color = "black"
                    filterTitle.color = "black"
                    container.color = "#eaeaea"
                }
            }
            else {
                if(listContainer.visible){
                    filterArrow.color = "black"
                    filterTitle.color = "black"
                    container.color = "#eaeaea"
                }
                else {
                    filterArrow.color = textColor
                    filterTitle.color = textColor
                    container.color = containerBackgroundColor
                }
            }
        }
    }

    //Contenitore della lista degli elementi selezionabili
    Rectangle {
        id: listContainer

        width: container.width
        height: 250 * scaleY

        anchors.bottom: container.top
        color: backgroundColor

        //Di default la lista non è visibile; lo diventa quando si preme la base della combo box
        visible: false

        //Nonostante la lista sia inizialmente invisibile, metto comunque l'opacità a 0 per far si che la appaia l'animazione
        //di fade in la prima volta che si preme sulla combo box
        opacity: 0

        //Animazione per far comparire/scomparire la lista quando si preme la base della combo box
        Behavior on opacity {
            NumberAnimation {
                duration: 250

                onRunningChanged: {
                    //Se l'animazione era per far scomparire la lista, e l'animazione è ora conclusa, rendo invisibile la lista
                    if(!running && listContainer.opacity == 0)
                        listContainer.visible = false
                }
            }
        }

        //Lista contenente gli elementi selezionabili
        GridView {
            id: filterList

            anchors.fill: parent
            anchors.topMargin: verticalScrollBar.width
            anchors.bottomMargin: verticalScrollBar.width
            anchors.leftMargin: verticalScrollBar.width + 1 * scaleX

            boundsBehavior: verticalScrollBar.visible == false ? Flickable.StopAtBounds : Flickable.DragOverBounds

            clip: true
            model: listModel

            Component {
                id: colorDelegate

                Rectangle {
                   id: mainRectangle

                   //Booleano per indicare se l'elemento in questione è stato selezionato
                   property bool isSelected: false

                   width: gridCellWidth
                   height: gridCellHeight

                   radius: 2

                   color: getColor(modelData)

                   //Funzione burda provvisoria per i colori
                   function getColor(color)
                   {
                       switch(color)
                       {
                       case "Nero":
                           return "black"
                       case "Grigio":
                           return "grey"
                       case "Rosso":
                           return "red"
                       case "Bianco":
                           return "white"
                       case "Giallo":
                           return "yellow"
                       case "Blu":
                           return "blue"
                       case "Marrone":
                           return "#805d2d"
                       }
                    }


                   //MouseArea per gestire la selezione dell'elemento per i filtri
                   MouseArea {
                       anchors.fill: parent;

                       onClicked: {
                           //Se l'item clickato non era selezionato, adesso lo è
                           if(!isSelected)
                           {
                               mainRectangle.border.color = "steelblue"
                               mainRectangle.border.width = 3

                               //Aggiungo l'elemento alla lista degli elementi selezionati per i filtri
                               selectedElements.push(modelData)

                               //Segnalo che l'elemento è ora selezionato
                               isSelected = true
                           }
                           else
                           {
                               mainRectangle.border.color = "transparent"

                               //Devo rimuovere l'elemento dalla lista degli elementi selezionati; recupero il suo indice nell'array
                               var index = selectedElements.indexOf(modelData)

                               //Rimuovo l'elemento
                               selectedElements.splice(index, 1)

                               //Segnalo che l'elemento non è più selezionato
                               isSelected = false
                           }

                           //Segnalo all'esterno che c'è stato un evento touch
                           container.touchEventOccurred()
                       }

                   }
               }
            }

            Component {
                id: sizeDelegate

                Rectangle {
                   id: mainRectangle

                   width: gridCellWidth
                   height: gridCellHeight

                   //Booleano per indicare se l'elemento in questione è stato selezionato
                   property bool isSelected: false

                   color: "white"

                   radius: 3

                   Text {
                       id: itemText

                       text: modelData

                       font.family: metroFont.name
                       font.pointSize: 10
                       font.weight: Font.Normal
                       font.letterSpacing: 1.2
                       color: "#333333"

                       anchors.centerIn: parent
                   }

                   //MouseArea per gestire la selezione dell'elemento per i filtri
                   MouseArea {
                       anchors.fill: parent;

                       onClicked: {
                           //Se l'item clickato non era selezionato, adesso lo è
                           if(!isSelected)
                           {
                               mainRectangle.border.color = "steelblue"
                               mainRectangle.border.width = 3

                               //Aggiungo l'elemento alla lista degli elementi selezionati per i filtri
                               selectedElements.push(itemText.text)

                               //Segnalo che l'elemento è ora selezionato
                               isSelected = true
                           }
                           else
                           {
                               mainRectangle.border.color = "transparent"

                               //Devo rimuovere l'elemento dalla lista degli elementi selezionati; recupero il suo indice nell'array
                               var index = selectedElements.indexOf(itemText.text)

                               //Rimuovo l'elemento
                               selectedElements.splice(index, 1)

                               //Segnalo che l'elemento non è più selezionato
                               isSelected = false
                           }

                           //Segnalo all'esterno che c'è stato un evento touch
                           container.touchEventOccurred()
                       }

                   }
               }
            }

            delegate: colorGrid ? colorDelegate : sizeDelegate

            cellWidth: gridCellWidth + (2 * scaleX)
            cellHeight: gridCellHeight + (2 * scaleY)


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

        //Scrollbar annessa alla lista, qualora occorresse
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

    /* Funzione per aprire la lista. L'apertura porta ad una animazione di fade in */
    function openList()
    {
        //Rendo visibile la lista...
        listContainer.visible = true

        //...e porto l'opacità a 1, che prima era a 0 (questo fa triggerare l'animazione di fade in per via del "Behavior on opacity")
        listContainer.opacity = 1;

        //Ruoto la freccia, causando un'animazione per via del "Behavior on rotation"
        filterArrow.rotation = 270
    }

    /* Funzione per chiudere la lista. La chiusura porta ad una animazione di fade out */
    function closeList()
    {
        //Porto l'opacità a 0, causando l'animazione. Al termine dell'animazione, il container della lista diventa invisibile
        //del tutto grazie a "listContainer.visible = false" (occorre farlo al termine dell'animazione, altrimenti questa non appare)
        listContainer.opacity = 0;

        //Ruoto la freccia, causando un'animazione per via del "Behavior on rotation"
        filterArrow.rotation = 90

        //Se la lista è chiusa, riporto il colore allo stato originale
        filterArrow.color = textColor
        filterTitle.color = textColor
        container.color = containerBackgroundColor
    }
}
