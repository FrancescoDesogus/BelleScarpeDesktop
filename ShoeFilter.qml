import QtQuick 2.0


/* Component che rappresenta il pannello per filtrare le scarpe che compare in basso */
Rectangle {
    id: container

    //Dimensioni totali di tutto il pannello e il suo colore di background
    property real filterPanelWidth: 1920 * scaleX
    property real filterPanelHeight: 300 * scaleY
    property string filterPanelbackgroundColor: "#686868"

    //Dimensioni del rettangolo draggabile e il suo colore di background
    property real draggingRectangleWidth: 350 * scaleX
    property real draggingRectangleHeight: 41 * scaleY
    property string draggingRectangleBackgroundColor: "#686868"

    //Dimensioni di ogni entry della lista delle scarpe filtrate
    property real shoeListElementWidth: 350 * scaleX
    property real shoeListElementHeight: filteredList.height - (2 * scaleY)

    //Colore per il testo delle combo box
    property string textColor: "#EDEDED"

    //Riferimento ad il rettangolo di background che deve essere grande tutto lo schermo ed invisibile; è usato per far si che
    //quando si preme fuori dal pannello il rettangolo intercetti l'input e chiuda il pannello stesso
    property Rectangle backgroundRectangle

    //Booleano per indicare se il pannello è aperto o no
    property bool isOpen: false

    //Booleano per indicare se è stata fatta almeno una ricerca (di default non è così); serve per sapere se mostrare un messaggio
    //di invito alla ricerca se il model della lista dei risultati è vuoto (la prima volta) oppure se mostrare un messaggio di errore
    property bool hasAlreadyFilteredShoes: false

    //Booleano per indicare se il pannello ha fatto la richiesta di filtrare scarpe e adesso sta aspettando i risultati
    property bool isFilteringShoes: false

    //Colore di sfondo per i filtri
    property string filtersColorBackground: "#989898"


    /**************************************************************
     * Signal emessi verso l'esterno
     **************************************************************/

    //Signal che scatta quando viene rilevato un qualsiasi evento touch nell'interfaccia; serve per riazzerare il timer
    //che porta alla schermata di partenza dopo un tot di tempo di inattività
    signal touchEventOccurred()

    /* Questo signal indica che è stata premuta una nuova scarpa e che bisogna creare una nuova view che la visualizzi;
     * passa come parametro l'id della scarpa toccata e il riferimento alla FlipableSurface che corrisponde alla scarpa
     * selezionata (è una copia visiva della list entry selezionata) */
    signal needShoeIntoContext(int id, variant shoeSelectedFlipable)


    //Questo signal scatta quando si preme per filtrare le scarpe ed è usato per informare l'esterno dell'evento; vengono
    //passati come parametri le liste contenenti i filtri per ogni categoria di filtri; le liste possono essere vuote
    signal needToFilterShoes(variant brandList, variant categoryList, variant colorList, variant sizeList, variant sexList, int minPrice, int maxPrice)



    //L'intero container ha associata una MouseArea che ha il solo scopo di emettere il signal touchEventOccurred(), in modo
    //da avvisare chi userà il component ShoeImagesList che è stato ricevuto un touch event
    MouseArea {
        anchors.fill: parent
        onClicked: container.touchEventOccurred()
    }

    FontLoader { id: metroFont; source: "qrc:segeo-wp.ttf" }

    //Rettangolo che "sporge" per essere draggato
    Rectangle {
        id: draggingRectangle

        width: draggingRectangleWidth
        height: draggingRectangleHeight

        color: draggingRectangleBackgroundColor
        radius: 6

        anchors.bottom: container.bottom
        anchors.horizontalCenter: container.horizontalCenter

        Behavior on y {
            NumberAnimation {
                easing.type: Easing.OutSine
                duration: 150
            }
        }

        //Rettangolo messo alla base in modo da avere la parte di sopra con radius e la parte di sotto senza
        Rectangle {
            anchors.bottom: draggingRectangle.bottom
            width: parent.width
            height: 10 * scaleY
            color: draggingRectangle.color
        }

        Text {
            id: arrow
            text: "«"
            font.family: metroFont.name
            font.pointSize: 16

            rotation: 90
            anchors.top: parent.top
            anchors.topMargin: -9 * scaleY
            anchors.horizontalCenter: parent.horizontalCenter

            color: textColor
        }

        Text {
            text: "Filtra Scarpe"            
            font.family: metroFont.name
            font.pointSize: 9
            font.letterSpacing: 1.2

            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            color: textColor
        }


        //MouseArea per gestire il dragging
        MouseArea {
            id: clickableArea

            //Booleano per indicare se si sta trascinando il rettangolo quando lo si è premuto, oppure se si è solo clickato
            //su di esso senza trascinarlo e poi si è staccato il dito dallo schermo
            property bool hasMoved: false;

            //Coordinata iniziale del mouse durante un evento di dragging
            property int startY;

            //Posizione iniziale del rettangolo durante un evento di dragging
            property int startingRectangleY;

            //Coordinata y precedente durante le fasi di dragging; cambia seguendo il dito
            property int previousY;


            anchors.fill: draggingRectangle

            //Setto le proprietà che determinano verso dove e quanto si può draggare il rettangolo
            drag.target: draggingRectangle
            drag.axis: Drag.YAxis
            drag.maximumY: -draggingRectangle.height
            drag.minimumY: -filterPanelHeight

            //Quando si preme sul rettangolo...
            onPressed: {
                //...salvo la coordinata iniziale del mouse...
                startY = mouse.y

                //...e la posizione iniziale del rettangolo
                startingRectangleY = draggingRectangle.y

                //Elimino l'anchor del rettangolo, in modo che possa essere effettivamente trascinato
                draggingRectangle.anchors.bottom = undefined

                //Segnalo anche che è avvenuto un evento touch
                container.touchEventOccurred()
            }

            //Per gestire il dragging e aprire/chiudere il pannello correttamente, salvo la y della MouseArea ogni volta che cambia
            //mentre si sta premendo il rettangolo; in questo modo posso poi capire in che direzione si stava trascinando il rettangolo
            onMouseYChanged: {
                previousY = mouse.y

                /* Se non ci si era ancora mossi e la y iniziale è diversa da quella attuale, vuol dire che adesso ci si è spostati
                 * e quindi lo segnalo; serve per capire quando si fa un click senza dragging sul rettangolo; in tal caso infatti
                 * scatterebbe lo stesso onMouseYChanged anche se di fatto la y non è cambiata; c'è bisogno quindi di un booleano
                 * per capire quando quella situazione avviene */
                if(!hasMoved && startY != previousY)
                    hasMoved = true
            }

            //Quando si rilascia il dito è il momento in cui si decide se aprire o chiudere il pannello
            onReleased: {
                /* Caso in cui si clicka sul rettangolo una sola volta, senza trascinare. Questo accade quando la y precedente
                 * è uguale a quella attuale, mentre non ci si è ancora mossi (è importante che non ci si sia ancora mossi, in
                 * quanto si potrebbe trascinare il dito per poi tornare ad una posizione "ferma" e che farebbe scattare questa
                 * if anche se non dovrebbe) */
                if(previousY == mouse.y && !hasMoved)
                {
                    //Al click, se il pannello era aperto, lo chiudo; altrimenti lo apro
                    if(isOpen)
                        closePanel()
                    else
                        openPanel()

                    //Termino qua la funzione, avendo trovato a cosa corrispondeva l'evento
                    return;
                }


                /* Caso in cui il rettangolo è stato trascinato un po' e poi è ritornato alla posizione di partenza; in tal caso,
                 * bisogna riportare tutto alla posizione iniziale e non fare altro. Questo evento accade quando la posizione
                 * del rettangolo attuale è uguale a quella che aveva inizialmente e ci si è mossi */
                if(draggingRectangle.y == startingRectangleY && hasMoved)
                {
                    //Se il pannello era aperto, lo riapro (in realtà appunto era già aperto, ma chiamando la funzione
                    //mi assicuro che vengano fatte le cose che servono quando il pannello è aperto); viceversa se era chiuso
                    if(isOpen)
                        openPanel()
                    else
                        closePanel()

                    //Termino qua la funzione, avendo trovato a cosa corrispondeva l'evento
                    return;
                }

                /* Caso in cui il rettangolo è stato trascinato un po' e poi il dito è stato rilasciato mentre era in movimento.
                 * In questo caso, controllo l'ultima y salvata con quella attuale: se era minore, vuol dire che si stava
                 * trascinando il rettangolo verso l'alto, e quindi lo apro; altrimenti è il contrario, e quindi lo chiudo */
                if(previousY <= mouse.y)
                    openPanel()
                else
                    closePanel()
            }
        }
    }



    /* Questa FlipableSurface è usata per mostrare la transizione di flipping quando si seleziona una scarpa. Il funzionamento
     * è analogo a quello usato in SimiliarShoesList.qml, quindi i commenti dei dettagli sono lasciati la */
    FlipableSurface {
        id: flipableSurface

        visible: false

        front: SimilarShoesDelegate {
            id: delegateCopy

            //Inizialmente setto solo dei valori costanti, indipendenti dalla scarpa e uguali per ogni entry della lista
            height: shoeListElementHeight
            width: shoeListElementWidth
            textFont: metroFont

            //Segnalo che questo delegate è usato nella lista delle scarpe filrate
            filtered: true
        }


        /* Dato che ci sono gli "smoother" a destra e a sinistra della lista delle scarpe, durante le transizioni quando si preme
         * su una scarpa (e quindi quando flipableSurface diventa visibile per effettuare la transizione) bisogna farli scomparire
         * e poi ricomparire se e quando la schermata torna ad essere mostrata, in modo che l'entry della lista clickata non finisca
         * sopra uno smoother durante la transizione al contrario (in tal caso finirebbe sopra lo smoothere poi subito sotto
         * all'improvviso, rendendo l'aspetto visivo per niente "smooth") */
        onVisibleChanged: {
            //Se la flipableSurface diventa visibile, e la lista non era all'inizio (e quindi il leftSmoother è visibile),
            //nascondo lo smoother
            if(visible && !filteredList.atXBeginning)
                leftSmoother.opacity = 0
            /* Se quando la transizione è terminata (e quindi la flipableSurface non è più visibile) la lista non si trova
             * all'inizio, e quindi il leftSmoother prima era visibile, devo farlo ricomparire. Non basta mettere l'opacità a 1
             * perchè il binding che lo faceva apparire/scomparire quando ci si spostava nella lista (definito al momento
             * della dichiarazione dello smoother) si era rotto quando gli era stata messa l'opacità a 0.
             * Quindi, invece di settare l'opacità a 1, ripristino il binding con la funzione apposita, in modo che d'ora in avanti
             * continui a lavorare correttamente come stava facendo prima della transizione */
            else if(!visible && !filteredList.atXBeginning)
                leftSmoother.opacity = Qt.binding(function() { return filteredList.atXBeginning ? 0 : 1 })

            //Stesso discorso di sopra per il rightSmoother
            if(visible && !filteredList.atXEnd)
                rightSmoother.opacity = 0
            else if(!visible && !filteredList.atXEnd)
                rightSmoother.opacity = Qt.binding(function() { return filteredList.atXEnd ? 0 : 1 })
        }

        function createCopy(toCopy)
        {
            delegateCopy.color = toCopy.color

            delegateCopy.thumbnailSource = toCopy.thumbnailSource
            delegateCopy.modelText = toCopy.modelText
            delegateCopy.brandText = toCopy.brandText
            delegateCopy.priceText = toCopy.priceText

            var localCoordinates = toCopy.mapToItem(container, 0, 0)

            flipableSurface.x = localCoordinates.x
            flipableSurface.y = localCoordinates.y

            return flipableSurface;
        }
    }

    //Rettangolo che contiene il pannello vero e proprio; sta' sotto il rettangolo draggabile
    Rectangle {
        id: filterPanel

        width: filterPanelWidth
        height: filterPanelHeight


        //MouseArea che ha il solo scopo di emettere il signal touchEventOccurred()
        MouseArea {
            anchors.fill: parent
            onClicked: container.touchEventOccurred()
        }

        color: filterPanelbackgroundColor

        anchors.top: draggingRectangle.bottom
        anchors.horizontalCenter: container.horizontalCenter

        //Combo box per le marche filtrabili
        FilterList {
            id: brandsFilterList

            title: "Marca"

            anchors.top : filterPanel.top
            anchors.topMargin: 15 * scaleY
            anchors.left: filterPanel.left
            anchors.leftMargin: 20 * scaleX

            width: 200 * scaleX
            height: 55 * scaleY

            //Inserisco come model l'array contenente le marche creato da C++
            listModel: filters.allBrandsModel
            backgroundColor: filtersColorBackground
            containerBackgroundColor: filtersColorBackground

            //Se avviene un evento touch, propago il signal verso l'esterno
            onTouchEventOccurred: container.touchEventOccurred()
        }

        //Combo box per le categorie filtrabili
        FilterList {
            id: categoryFilterList

            title: "Categoria"

            anchors.top : filterPanel.top
            anchors.topMargin: 15 * scaleY
            anchors.left: brandsFilterList.right
            anchors.leftMargin: 40 * scaleX

            width: 200 * scaleX
            height: 55 * scaleY

            listModel: filters.allCategoriesModel
            backgroundColor: filtersColorBackground
            containerBackgroundColor: filtersColorBackground

            onTouchEventOccurred: container.touchEventOccurred()
        }

        //Combo box per i colori filtrabili
        FilterGrid {
            id: colorFilterList

            title: "Colore"

            colorGrid: true

            anchors.top : filterPanel.top
            anchors.topMargin: 15 * scaleY
            anchors.left: categoryFilterList.right
            anchors.leftMargin: 40 * scaleX

            width: 250 * scaleX
            height: 55 * scaleY

            gridCellHeight: 76 * scaleY
            gridCellWidth: 76 * scaleX

            listModel: filters.allColorsModel
            backgroundColor: filtersColorBackground
            containerBackgroundColor: filtersColorBackground

            onTouchEventOccurred: container.touchEventOccurred()
        }

        //Combo box per le taglie filtrabili
        FilterGrid {
            id: sizeFilterList

            title: "Taglia"

            colorGrid: false

            anchors.top : filterPanel.top
            anchors.topMargin: 15 * scaleY
            anchors.left: colorFilterList.right
            anchors.leftMargin: 40 * scaleX

            width: 250 * scaleX
            height: 55 * scaleY

            gridCellHeight: 57 * scaleY
            gridCellWidth: 57 * scaleX

            listModel: filters.allSizesModel
            backgroundColor: filtersColorBackground
            containerBackgroundColor: filtersColorBackground

            onTouchEventOccurred: container.touchEventOccurred()
        }

        //Combo box per il sesso
//        FilterList {
//            id: sexFilterList

//            title: "Sesso"

//            anchors.top : filterPanel.top
//            anchors.topMargin: 15 * scaleY
//            anchors.left: sizeFilterList.right
//            anchors.leftMargin: 50 * scaleX

//            width: 200 * scaleX
//            height: 55 * scaleY

//            listModel: ListModel {
//                ListElement {
//                    name: "Uomo"
//                }

//                ListElement {
//                    name: "Donna"
//                }
//            }

//            backgroundColor: filtersColorBackground
//        containerBackgroundColor: filtersColorBackground

//            onTouchEventOccurred: container.touchEventOccurred()
//        }

        //Rettangolo contenente le checkbox per il sesso
        Rectangle {
            id: sexFilterList

            //Creo qui l'array degli elementi selezionati, così che sia prelevabile ed utilizzabile
            //nella funzione di filtraggio
            property var selectedElements: [];

            //Alcune proprietà generali che dovranno essere uguali per entrambe le checkbox
            property double leftCheckboxMargin: 10 * scaleX //Distanza del testo dalla checkbox
            property int fontPointSize: 12 //dimensione del testo
            property int checkboxHW: 23 //altezza e larghezza delle checkbox (sono uguali e scalate direttamente dove usate)
            property string textColor: "#FFFFFF" //Colore del testo

            color: filtersColorBackground //Colore di sfondo di tutto il rettangolo

            anchors.top : filterPanel.top
            anchors.topMargin: 15 * scaleY
            anchors.left: sizeFilterList.right
            anchors.leftMargin: 40 * scaleX

            width: 220 * scaleX
            height: 55 * scaleY

            radius: 2

            //Mini rettangolo solo per checkbox + testo relativo al filtro "Uomo"
            Rectangle {
                id: uomoFilter

                //Proprietà per capire se è selezionato o meno
                property bool isSelected: false

                color: sexFilterList.color

                //Per far si che siano identiche le checkbox, la loro larghezza sarà
                //la metà del rettangolo contenitore
                width: sexFilterList.width / 2
                height: sexFilterList.height

                anchors.left: sexFilterList.left
                anchors.leftMargin: 8 * scaleX //distanza dal bordo a sinistra
                anchors.verticalCenter: sexFilterList.verticalCenter

                //Checkbox
                Image {
                    id: checkUomo

                    //l'immagine cambia in base alla selezione
                    source: uomoFilter.isSelected ? "qrc:///qml/checkbox_selected.png" : "qrc:///qml/checkbox_unselected.png"
                    fillMode: Image.PreserveAspectFit

                    width: sexFilterList.checkboxHW * scaleX
                    height: sexFilterList.checkboxHW * scaleY

                    anchors.left: uomoFilter.left
                    anchors.verticalCenter: uomoFilter.verticalCenter
                }

                //Testo
                Text {
                    id: textUomo

                    color: sexFilterList.textColor

                    text: "Uomo"

                    font.family: metroFont.name
                    font.pointSize: sexFilterList.fontPointSize

                    anchors.left: checkUomo.right
                    anchors.leftMargin: sexFilterList.leftCheckboxMargin
                    anchors.verticalCenter: uomoFilter.verticalCenter
                }

                MouseArea {
                    anchors.fill: parent

                    onClicked: {
                        //appena premo deve cambiare la selezione
                        uomoFilter.isSelected = !uomoFilter.isSelected

                        //Adesso, dopo che ho cliccato, vedo se è selezionato o meno
                        if(uomoFilter.isSelected){
                            //Aggiungo l'elemento alla lista degli elementi selezionati per i filtri
                            sexFilterList.selectedElements.push(textUomo.text)
                        }
                        else {
                            //Devo rimuovere l'elemento dalla lista degli elementi selezionati; recupero il suo indice nell'array
                            var index = sexFilterList.selectedElements.indexOf(textUomo.text)

                            //Rimuovo l'elemento
                            sexFilterList.selectedElements.splice(index, 1)
                        }
                    }
                }
            }

            //Mini rettangolo solo per checkbox + testo relativo al filtro "Donna"
            Rectangle {
                id: donnaFilter

                //Proprietà per capire se è selezionato o meno
                property bool isSelected: false

                color: sexFilterList.color

                //Per far si che siano identiche le checkbox, la loro larghezza sarà
                //la metà del rettangolo contenitore
                width: sexFilterList.width / 2
                height: sexFilterList.height

                anchors.left: uomoFilter.right
                anchors.leftMargin: 10 * scaleX
                anchors.verticalCenter: sexFilterList.verticalCenter

                //Checkbox
                Image {
                    id: checkDonna

                    //l'immagine cambia in base alla selezione
                    source: donnaFilter.isSelected ? "qrc:///qml/checkbox_selected.png" : "qrc:///qml/checkbox_unselected.png"
                    fillMode: Image.PreserveAspectFit
                    width: sexFilterList.checkboxHW * scaleX
                    height: sexFilterList.checkboxHW * scaleY

                    anchors.left: donnaFilter.left
                    anchors.verticalCenter: donnaFilter.verticalCenter
                }

                //Testo
                Text {
                    id: textDonna

                    color: sexFilterList.textColor

                    text: "Donna"
                    font.family: metroFont.name
                    font.pointSize: sexFilterList.fontPointSize

                    anchors.left: checkDonna.right
                    anchors.leftMargin: sexFilterList.leftCheckboxMargin
                    anchors.verticalCenter: donnaFilter.verticalCenter
                }

                MouseArea {
                    anchors.fill: parent

                    onClicked: {
                        //appena premo deve cambiare la selezione
                        donnaFilter.isSelected = !donnaFilter.isSelected

                        //Adesso, dopo che ho cliccato, vedo se è selezionato o meno
                        if(donnaFilter.isSelected){
                            //Aggiungo l'elemento alla lista degli elementi selezionati per i filtri
                            sexFilterList.selectedElements.push(textDonna.text)
                        }
                        else {
                            //Devo rimuovere l'elemento dalla lista degli elementi selezionati; recupero il suo indice nell'array
                            var index = sexFilterList.selectedElements.indexOf(textDonna.text)

                            //Rimuovo l'elemento
                            sexFilterList.selectedElements.splice(index, 1)
                        }
                    }
                }
            }
        }


        //Slider per scegliere il range del prezzo. Visivamente rappresenta il rettangolo più chiaro che c'è sotto lo slider
        Rectangle {
            id: priceRangeSliderContainer

            //Proprietà che contengono il valore min e max selezionati in un dato momento
            property int min: filters.priceRangeModel[0]
            property int max: filters.priceRangeModel[1]

            //Dimensioni e raggio dei due dot
            property real dotWidth: 20 * scaleX;
            property real dotHeight: 20 * scaleY;
            property int dotRadius: 20;

            //colori dei dot
            property string dotNormalBackground: "#A0A0A0"
            property string dotPressedBackground: "#D8D8D8"

            //Coordinate minime e massime che i dot possono raggiungere
            property real minX: -dotWidth/2
            property real maxX: priceRangeSliderContainer.width - dotWidth/2

            //Coordinate dei dot; servono per essere accedute dall'esterno
            property real leftDotX: leftDot.x
            property real rightDotX: rightDot.x


            width: 230 * scaleX
            height: 10 * scaleY

            radius: 2

            anchors.bottom: sexFilterList.bottom
            anchors.bottomMargin: 10 * scaleY
            anchors.left: sexFilterList.right
            anchors.leftMargin: 110 * scaleX

            //Colore più chiaro per il rettangolo esterno (che sta' "sotto" i pallini ed il rettangolo centrale)
            color: "#d9d1d1"

            Text {
                id: priceFilterTitle

                color: "White"

                text: "Prezzo"
                font.family: metroFont.name
                font.pointSize: 13.5
                font.letterSpacing: 1.2
                font.weight: Font.Bold

                anchors.horizontalCenter: priceRangeSliderContainer.horizontalCenter
                anchors.bottom: priceRangeSliderContainer.top
                anchors.bottomMargin: 9 * scaleY
            }

            //Mouse area per far spostare il dot più vicino alla zona clickata quando si preme sulla parte parte dello slider più chiara
            MouseArea {
                anchors.fill: parent

                onPressed: {
                    /* Le coordinate arrivano ad una grandezza massima pari alla lunghezza del container; dato che anche i dot sono
                     * inseriti dentro il container, le loro coordinate sono date in base adesso. Di conseguenza è possibile
                     * comparare direttamente la coordinata clickata con la posizione dei dot per capire quale è il dot più vicino.
                     * Se la coordinata del mouse è maggiore della posizione del dot di destra, vuol dire che si è premuto alla sua
                     * destra, e quindi il dot più vicino è quello destro; nel caso, sposto il pallino nel punto clickato (meno
                     * la larghezza del pallino a metà per centrare il pallino dove si è clickato).
                     * Altrimenti, è stato premuto a sinistra del dot di sinistra, quindi sposto quello */
                    if(mouse.x > rightDot.x)
                        rightDot.x = mouse.x - rightDot.width/2
                    else
                        leftDot.x = mouse.x - rightDot.width/2

                    //Segnalo che c'è stato un evento touch
                    container.touchEventOccurred()
                }
            }


            //Rettangolo tra i due dot; cambia forma in base a come si spostano i dot
            Rectangle {
                id: rectangleBetweenDots

                //Inizialmente ha le stesse dimensioni del container principale
                width: priceRangeSliderContainer.width
                height: priceRangeSliderContainer.height


                //Colore più scuro
                color: "#99807a7a"

                //Mouse area per far spostare il dot più vicino alla zona clickata quando si preme sul rettangolo
                MouseArea {
                    anchors.fill: parent

                    onPressed: {
                        var offset = (mouse.x + leftDot.x - leftDot.width/2)

                        /* Dato che la larghezza del rettangolo tra i dot cambia forma, ed in particolare cambia posizione quando
                         * si sposta il dot di sinistra, le coordinate del mouse date non sono mai fisse e non sono nel range
                         * che va da 0 alla larghezza totale dello slider, come accadeva per il container. Di conseguenza, per capire
                         * quale è il dot più vicino al punto clickato è necessario riportare le misure in modo assoluto.
                         * La variabile offset contiene la coordinata del mouse riportata in piano assoluto, quindi direttamente
                         * confrontabile con le coordinate dei due dot */
                        if(rightDot.x - offset > offset - leftDot.x)
                            leftDot.x = offset
                        else
                            rightDot.x = offset

                        //Segnalo che c'è stato un evento touch
                        container.touchEventOccurred()
                    }
                }
            }

            //Dot di sinistra
            Rectangle {
                id: leftDot

                width: priceRangeSliderContainer.dotWidth
                height: priceRangeSliderContainer.dotHeight
                radius: priceRangeSliderContainer.dotRadius

                anchors.verticalCenter: priceRangeSliderContainer.verticalCenter

                //Sposto un po' il dot in negativo inizialmente in modo che sia un po' fuori dal rettangolo
                x: priceRangeSliderContainer.minX
                y: -5 * scaleY

                color: priceRangeSliderContainer.dotNormalBackground

                //MouseArea per abilitare il dragging
                MouseArea {
                    id: leftDotMouseArea
                    anchors.fill: parent

                    drag.target: leftDot
                    drag.axis: Drag.XAxis

                    //I limiti del drag sono a sinistra quello che sarebbe lo 0 del dot, a destra il dot di sinistra
                    drag.minimumX: priceRangeSliderContainer.minX
                    drag.maximumX: rightDot.x

                    /* Quando si preme sul dot, impongo che sia messo sopra l'altro. In questo modo se per esempio porto entrambi
                     * i dot in uno dei due estremi, posso sempre tornare indietro (cioè premendo l'accozzaglia dei 2 dot verrà
                     * sempre premuto l'ultimo dei dot trascinati, in modo da non rimanere bloccati nell'estremo) */
                    onPressed: {
                        leftDot.z = 1
                        rightDot.z = 0

                        //Segnalo che c'è stato un evento touch
                        container.touchEventOccurred()

                        leftDot.color = priceRangeSliderContainer.dotPressedBackground
                        leftDot.scale = 1.15
                    }

                    onReleased: {
                        leftDot.color = priceRangeSliderContainer.dotNormalBackground
                        leftDot.scale = 1.0
                    }
                }

                //Quando si sposta il dot bisogna cambiare la grandezza del rettangolo tra i due dot, in modo che parta
                //sempre dal left dot
                onXChanged: {
                    /* Il piano di coordinate tra il rettangolo e il dot è lo stesso, ed il range va da 0 fino alla lunghezza massima
                     * dello slider. Quando sposto il leftDot quindi sposto anche il punto di partenza del rettangolo che sta' in mezzo
                     * in modo che lo segue */
                    rectangleBetweenDots.x = x

                    //Cambio poi la lunghezza del rettangolo, tenendo conto che il dot di destra può essere spostato. Se il dot
                    //di destra è fermo nell'estremo destro, (priceRangeSliderContainer.width - rightDot.x) vale zero
                    rectangleBetweenDots.width = priceRangeSliderContainer.width - x - (priceRangeSliderContainer.width - rightDot.x)

                    /* Calcolo il valore che deve avere il punto in una data x: calcolo la differenza tra i valori massimo e minimo,
                     * quindi prezzo max - prezzo min; moltiplico tutto per la x attuale del punto; infine divido tutto per la x
                     * massima dello slider e per evitare che il minimo sia 0, riaggiungo il range inferiore al risultato */
                    var partialValue = Math.round((((filters.priceRangeModel[1] - filters.priceRangeModel[0]) * leftDot.x) / (priceRangeSliderContainer.width - rightDot.width/2)))

                    //Dato che il leftDot può assumere valori negativi, nell'estremo sinistro si potrebbero ottenere valori negativi
                    //quando in realtà non dovrebbero esserci; se questo è il caso, riporto il valore a zero
                    if(partialValue < 0)
                        partialValue = 0;

                    //Al valore parziale, che corrispondeva all'incremento nello spostamento, sommo il valore minimo per ottenere
                    //il valore attuale
                    var currentValue = partialValue + parseInt(filters.priceRangeModel[0])

                    //Salvo qual è il nuovo valore minimo
                    priceRangeSliderContainer.min = currentValue

                    //Infine setto il testo sopra il dot con il valore ottenuto
                    leftPrice.text = currentValue
                }
            }


            Rectangle {
                id: leftPriceRectangle

                anchors.right: priceRangeSliderContainer.left
                anchors.rightMargin: 17 * scaleX
                anchors.verticalCenter: priceRangeSliderContainer.verticalCenter

                width: 50 * scaleX
                height: 30 * scaleY
                radius: 3

                color: filtersColorBackground
                Text {
                    id: leftPrice

                    anchors.centerIn: leftPriceRectangle

                    color: "white"

                    visible: true

                    /* Quando il componente è stato creato, gli assegno come testo il prezzo minimo (contenuto nel primo posto
                     * dell'array passato da C++). Non lo faccio immediatamente alla creazione in quanto per motivi
                     * arcani viene chiamato l'onXChanged del leftDot all'inizio con valori anomali che farebbero comparire
                     * il prezzo massimo invece che quello minimo */
                    Component.onCompleted:  {
                        leftPrice.text = filters.priceRangeModel[0]

                        //Salvo anche il valore minimo correntemente selezionato, perchè anche questo altrimenti risulta sfasato
                        priceRangeSliderContainer.min = filters.priceRangeModel[0]
                    }
                }
            }

            //Dot di destra
            Rectangle {
                id: rightDot

                width: priceRangeSliderContainer.dotWidth
                height: priceRangeSliderContainer.dotHeight
                radius: priceRangeSliderContainer.dotRadius

                anchors.verticalCenter: priceRangeSliderContainer.verticalCenter

                //Sposto un po' il dot inizialmente in modo che sia un po' fuori dal rettangolo verso destra
                x: priceRangeSliderContainer.maxX
                y: -5 * scaleY


                color: priceRangeSliderContainer.dotNormalBackground

                MouseArea {
                    anchors.fill: parent

                    drag.target: rightDot
                    drag.axis: Drag.XAxis
                    drag.minimumX: leftDot.x
                    drag.maximumX: priceRangeSliderContainer.maxX

                    onPressed: {
                        leftDot.z = 0
                        rightDot.z = 1

                        container.touchEventOccurred()
                        rightDot.color = priceRangeSliderContainer.dotPressedBackground
                        rightDot.scale = 1.15
                    }

                    onReleased: {
                        rightDot.color = priceRangeSliderContainer.dotNormalBackground
                        rightDot.scale = 1.0
                    }
                }

                //Quando si sposta il dot, bisogna cambiare la larghezza del rettangolo al centro in modo che sia uguale alla
                //posizione del dot di destra, tenendo conto che il left dot può essere spostato e quindi anche il rettangolo
                onXChanged: {
                    rectangleBetweenDots.width = x - rectangleBetweenDots.x

                    //Calcolo anche il nuovo valore da mostrare, in modo analogo a quanto fatto per il leftDot
                    var partialValue = Math.round((((filters.priceRangeModel[1] - filters.priceRangeModel[0]) * rightDot.x) / (priceRangeSliderContainer.width - rightDot.width/2)))

                    if(partialValue < 0)
                        partialValue = 0;

                    var currentValue = partialValue + parseInt(filters.priceRangeModel[0])

                    priceRangeSliderContainer.max = currentValue

                    rightPrice.text = currentValue
                }                
            }

            //Testo col limite massimo del prezzo
            Rectangle {
                id: rightPriceRectangle

                anchors.left: priceRangeSliderContainer.right
                anchors.leftMargin: 15 * scaleX
                anchors.verticalCenter: priceRangeSliderContainer.verticalCenter

                width: 50 * scaleX
                height: 30 * scaleY
                radius: 3

                color: filtersColorBackground

                Text {
                    id: rightPrice

                    anchors.centerIn: rightPriceRectangle
                    //Il range dei prezzi min/max è passato da C++ sotto forma di array; il limite massimo è messo in seconda posizione
                    text: filters.priceRangeModel[1]
                    color: "white"
                }
            }

            /* Funzione per settare la x del leftDot. Serve per far si che si possa spostare il leftDot dall'esterno; è una cosa
             * brutta ma deve essere fatta perchè quando si preme la primissima volta il bottone per filtrare le scarpe si resetano
             * tutti i component, compresi i dot, che tornano allo stato iniziale. Per far si che si rimangano dove sono, occorre
             * recuperare rimettere la x che avevano prima della ricerca, e questo deve essere fatto dall'esterno */
            function setLeftDotX(x)
            {
                leftDot.x = x
            }


            /* Funzione per settare la x del rightDot */
            function setRightDotX(x)
            {
                rightDot.x = x
            }
        }

        //Bottone per eseguire il filtro
        Rectangle {
            id: filterButton

            width: 150 * scaleX
            height: 60 * scaleY

            color: "grey"            
            border.color: "#FFFFFF"

            radius: 4

//            gradient: Gradient {
//                GradientStop {
//                    position: 0.14;
//                    color: "#000000";
//                }
//                GradientStop {
//                    position: 0.53;
//                    color: "#ffffff";
//                }
//            }

            anchors.top: filterPanel.top
            anchors.topMargin: 15 * scaleY
            anchors.left: priceRangeSliderContainer.right
            anchors.leftMargin: 100 * scaleX

            Text {
                id: filterButtonText

                text: "Filtra"
                font.family: metroFont.name
                font.pointSize: 15
                font.letterSpacing: 1.3
                font.weight: Font.Bold

                color: "#FFFFFF"

                anchors.centerIn: parent
            }

            MouseArea {
                anchors.fill: parent

                //Quando il bottone è premuto...
                onClicked: {
                    //...controllo se c'è già una ricerca attualmente in corso o se non è possibile clickare;
                    //nel caso non faccio nulla, altrimenti...
                    if(container.isFilteringShoes || !isClickAllowed)
                        return;

                    //...recupero le liste degli elementi selezionati per ogni combo box (possono essere vuote)
                    var brandList = brandsFilterList.selectedElements;
                    var categoryList = categoryFilterList.selectedElements;
                    var colorList = colorFilterList.selectedElements;
                    var sizeList = sizeFilterList.selectedElements;
                    var sexList = sexFilterList.selectedElements;

                    //Recupero anche il range di prezzi da considerare
                    var minPrice = priceRangeSliderContainer.min;
                    var maxPrice = priceRangeSliderContainer.max;

                    /* C'è un bug assurdo quando si effetua la prima ricerca in una schermata: in pratica gli elementi
                     * selezionati nelle varie combo box e gli slider tornano alle loro posizioni di default subito dopo la
                     * ricerca (che viene fatta normalmente); quindi una seconda ricerca verrebbe fatta come se non ci fosse
                     * alcun filtro attivo, a meno che non vengano rimessi. Accade solo alla primissima ricerca e non ho capito
                     * assolutamente perchè, so solo che è dovuto al fatto che il model della lista dei risultati viene sovrascritto
                     * con un nuovo model da C++. Per fixxare il problema, uso una soluzione tarocca: subito dopo la prima ricerca
                     * rimetto i valori dei filtri com'erano prima della ricerca.
                     * Nel caso dei due dot dello slider dei prezzi, per rimetterli dov'erano devo recuperare la loro posizione
                     * prima della ricerca */
                    if(!container.hasAlreadyFilteredShoes)
                    {
                        //Salvo le posizioni dei dot prima della ricerca
                        var leftDotX = priceRangeSliderContainer.leftDotX
                        var rightDotX = priceRangeSliderContainer.rightDotX
                    }

                    //Emetto infine il signal che avvisa l'esterno della ricerca, passando tutti i parametri recuperati sopra
                    container.needToFilterShoes(brandList, categoryList, colorList, sizeList, sexList, minPrice, maxPrice);

                    //Nascondo il testo di feedback, qualora fosse presente
                    feedbackText.visible = false

                    //Nascondo la lista, qualora fosse presente
                    filteredList.opacity = 0

                    //Attivo l'indicatore di caricamento
                    loadIndicator.running = true

                    //Segnalo che si sta eseguendo una ricerca, in modo tale da non permetterne altre fino a quando questa non finisce
                    container.isFilteringShoes = true;


                    /* Se questa è la prima ricerca, per via del bug assurdo descritto poco più sopra, devo rimettere i filtri
                     * che c'erano prima della ricerca nei vari componenti coinvolti, che altrimenti tornerebbero
                     * al loro valore di default */
                    if(!container.hasAlreadyFilteredShoes)
                    {
                        //Rimetto tutti i valori selezionati nelle varie combo box
                        brandsFilterList.selectedElements = brandList;
                        categoryFilterList.selectedElements = categoryList;
                        colorFilterList.selectedElements = colorList;
                        sizeFilterList.selectedElements = sizeList;
                        sexFilterList.selectedElements = sexList;

                        //Setto con le apposite funzioni le posizioni dei dot dello slider dei prezzi, in modo che si
                        //posizionino dove erano prima della ricerca
                        priceRangeSliderContainer.setLeftDotX(leftDotX);
                        priceRangeSliderContainer.setRightDotX(rightDotX);

                        //Segnalo quindi è stata fatta almeno una ricerca
                        hasAlreadyFilteredShoes = true;
                    }
                }

                onPressed: {
                    filterButton.color = "white"
                    filterButton.border.color = filterPanelbackgroundColor
                    filterButtonText.color = "grey"

                }

                onReleased: {
                    filterButton.color = "grey"
                    filterButton.border.color = "white"
                    filterButtonText.color = "white"
                }
            }
        }


        //Contenitore della lista delle scarpe filtrate
        Rectangle {
            id: listContainer
            anchors.horizontalCenter: filterPanel.horizontalCenter
            anchors.bottom: filterPanel.bottom
            anchors.bottomMargin: 50 * scaleY
            width: filterPanel.width
            height: 150 * scaleY

            color: "#00000000"


            //MouseArea che ha il solo scopo di emettere il signal touchEventOccurred()
            MouseArea {
                anchors.fill: parent
                onClicked: container.touchEventOccurred()
            }

            /* Item che contiene l'indicatore di caricamento, visibile e animato quando si stanno recuperando dati dal database.
             * E' creato come Item perchè così posso renderlo grande quanto tutto il padre (il container della lista) senza
             * che però risulti visibile; questo aiuta per centrare l'indicatore di caricamento nel container della lista.
             * Per rendere visibile l'indicatore è sufficente settare "running" su true */
            Item {
                id: loadIndicator

                anchors.fill: parent

                property bool running: false
                property string imageSource: "qrc:/images/busy.png"

                //Rendo visibile il tutto solo se sta effettivamente caricando
                visible: running

                Image {
                    id: image

                    anchors.centerIn: parent

                    source: loadIndicator.imageSource

                    //Animazioni eseguite in parallelo; la prima rende visibile l'indicatore con un fade in, la seconda
                    //lo fa ruotare per l'eternità
                    ParallelAnimation {
                        running: loadIndicator.running

                        NumberAnimation { target: image; property: "opacity"; from: 0.0; to: 1.0; duration: 200 }
                        NumberAnimation { target: image; property: "rotation"; from: 0; to: 360; loops: Animation.Infinite; duration: 1200 }
                    }
                }
            }



            //Testo da mostrare al posto della lista quando questa è vuota per un motivo o per l'altro
            Text {
                id: feedbackText

                //Rispetivamente, il messaggio da mostrare inizialmente ed il messaggio di errore quando non ci sono risultati
                property string initialText: "Seleziona i filtri da usare e premi il pulsante per effettuare una ricerca"
                property string errorText: "Nessuna scarpa trovata"

                //Se è stata fatta almeno una ricerca in passato, mostro un messaggio di errore, altrimenti il testo niziale
                text: hasAlreadyFilteredShoes ? errorText : initialText

                font.family: metroFont.name
                font.pointSize: 15
                font.letterSpacing: 1.3
                font.weight: Font.Bold

                color: textColor

                anchors.centerIn: parent
            }


            //Lista che mostra i risultati delle scarpe filtrate
            ListView {
                id: filteredList

                //La lista è grande quanto tutto il container
                anchors.fill: listContainer
                anchors.leftMargin: container.calculateListPosition()

                /* La lista utilizza un model che proviene da C++ e coniene di volta in volta i risultati trovati; di conseguenza,
                 * questo model verrà cambiato da C++ all'occorenza. Per capire quando effettivamente il model è cambiato (essendo
                 * i dati presi in modo asincrono) utilizzo l'apposito signal "onModelChanged". Quando scatta, so che è stato
                 * cambiato il model da C++ e adesso bisogna visualizzare la lista */
                onModelChanged: {
                    //Il modello ricevuto da C++ può essere vuoto qualora non ci fossero risultati (o problemi nel prendere i dati);
                    //nel caso, mostro il testo di feedback, che avrà il messaggio "nessuna scarpa trovata"
                    if(filteredList.count == 0)
                        feedbackText.visible = true

                    //Adesso devo far comparire (o ricomparire) la lista, che sarà aggiornata automaticamente con le nuove scarpe;
                    //la rendo quindi visibile qualora non lo fosse già e porto l'opacità a 1 causando l'animazione di fade in
                    filteredList.visible = true
                    filteredList.opacity = 1

                    //Blocco l'indicatore di caricamento, che sparisce
                    loadIndicator.running = false

                    //Mi segno che il pannello non sta caricando scarpe dal database
                    container.isFilteringShoes = false;
                }


                //Metto un behavior per eseguire un'animazione quando cambia l'opacità
                Behavior on opacity {
                    NumberAnimation {
                        duration: 200

                        onRunningChanged: {
                            //Se l'animazione era per far scomparire la lista, e l'animazione è ora conclusa, rendo invisibile la lista
                            if(!running && filteredList.opacity == 0)
                                filteredList.visible = false
                        }
                    }
                }


                //Attivo lo scrolling della lista supera la larghezza del suo container
                boundsBehavior: filteredList.width < listContainer.width ? Flickable.StopAtBounds : Flickable.DragOverBounds

                //La lista è abilitata solo se è possibile premere sugli elementi (non è possibile subito dopo che si è premuto
                //su una scarpa causando quindi una transizione)
                enabled: isClickAllowed

                //Il modello della lista, contenente i path delle immagini da mostrare, è preso da C++ ed è uguale a quello della lista
                //contenente le thumbnail
                model: filteredShoesModel

                clip: true

                //Il delegate usa un component creato ad hoc
                delegate: SimilarShoesDelegate {
                    id: filteredContainer

                    height: shoeListElementHeight
                    width: shoeListElementWidth
                    textFont: metroFont

                    //Setto le varie proprietà della scarpa in questione
                    thumbnailSource: modelData.thumbnail
                    modelText: modelData.model
                    brandText: modelData.brand
                    priceText: modelData.price

                    //Segnalo che questo tipo di delegate è per la visualizzazione di scarpe filtrate
                    filtered: true

                    //Al click bisogna apire la nuova schermata con la scarpa clickata. Il funzionamento è analogo a quanto accade
                    //in SimiliarShoesList.qml, quindi i commenti riguardo i dettagli sono lasciati la
                    MouseArea {
                        anchors.fill: parent;

                        onClicked: {
                            if(isClickAllowed) {
                                container.touchEventOccurred();

                                filteredList.positionViewAtIndex(index, ListView.Contain)

                                var shoeSelectedFlipable = flipableSurface.createCopy(filteredContainer)
                                shoeSelectedFlipable.frontListItem = filteredContainer
                                shoeSelectedFlipable.parent = container
                                container.needShoeIntoContext(modelData.id, shoeSelectedFlipable)

                                filteredList.currentIndex = index
                            }
                        }
                    }
                }

                orientation: ListView.Horizontal
                spacing: 9 * scaleX
            }
        }


        //Smoother sinistro che compare a sinistra della lista quando la si scorre verso destra
        Rectangle {
            id: leftSmoother
            width: filteredList.height
            height: filteredList.height

            anchors.left: listContainer.left
            anchors.verticalCenter: listContainer.verticalCenter
            rotation: -90
            opacity: filteredList.atXBeginning ? 0 : 1

            gradient: Gradient {
                     GradientStop { position: 0.0; color: filterPanel.color }
                     GradientStop { position: 1.0; color: "#00000000" }
                 }

            Behavior on opacity {
                NumberAnimation {
                    duration: 600;
                    easing.type: Easing.OutQuad
                }
            }
        }

        //Smoother destro che compare a sinistra della lista quando la si scorre verso destra
        Rectangle {
            id: rightSmoother
            width: filteredList.height
            height: filteredList.height

            anchors.right: listContainer.right
            anchors.verticalCenter: listContainer.verticalCenter
            rotation: 90
            opacity: filteredList.atXEnd ? 0 : 1

            gradient: Gradient {
                     GradientStop { position: 0.0; color: filterPanel.color }
                     GradientStop { position: 1.0; color: "#00000000" }
                 }

            Behavior on opacity {
                NumberAnimation {
                    duration: 600;
                    easing.type: Easing.OutQuad
                }
            }
        }

        Rectangle {
            id: titleUnderline

            height: 1 * scaleY
            width: listContainer.width
            anchors.bottom: listContainer.top
            anchors.bottomMargin: 10 * scaleY
            anchors.horizontalCenter: listContainer.horizontalCenter
        }
    }


    /* Funzione che effettua il necessario per aprire il pannello dei filtri */
    function openPanel()
    {
        arrow.text = "»"
        draggingRectangle.y = 0 - filterPanelHeight

        //Dichiaro che ora il pannello è aperto
        isOpen = true

        //Riporto su false il booleano che serve per decifrare gli eventi della MouseArea, in modo che sia pronto all'uso in seguito
        clickableArea.hasMoved = false

        //Rendo visibile il background che serve ad intercettare gli input fuori dal panel (è visibile ma ha opacità pari a 0)
        backgroundRectangle.visible = true
    }

    /* Funzione che effettua il necessario per chiudere il pannello dei filtri; è usata anche dall'esterno in ShoeView */
    function closePanel()
    {
        arrow.text = "«"
        draggingRectangle.y = -draggingRectangle.height

        //Faccio scomparire il rettangolo sullo sfondo
        backgroundRectangle.visible = false

        //Dichiaro che ora il pannello è chiuso
        isOpen = false

        //Riporto su false il booleano che serve per decifrare gli eventi della MouseArea, in modo che sia pronto all'uso in seguito
        clickableArea.hasMoved = false

        //Chiudo anche eventuali liste aperte
        brandsFilterList.closeList();
        categoryFilterList.closeList();
        colorFilterList.closeList();
        sizeFilterList.closeList();
//        sexFilterList.closeList();
    }


    /* Funzione che calcola la posizione da cui deve partire la ListView contenente le scarpe filtrate (in sostanza calcola la
     * coordinata x che la lista deve avere). Il funzionamento è identico a quello in ShoeImagesList per la lista delle thumbnail,
     * solo che in questo caso è tutto riportato in orizzontale (i commenti sono messi la) */
    function calculateListPosition()
    {
        /* Nota: calcolo la lunghezza della lista manualmente e non uso filteredList.width perchè a furia di cambiare il model
         * della lista in base alle ricerche si altera il valore del width diventando più grande di quello che è (anche se di fatto
         * gli elementi sono pochi). Dato che non so perchè lo faccia o come risolverlo, calcolo la lunghezza manualmente
         * tenendo conto di quanti elementi ci sono nella lista, della lunghezza di ciascuno e dello spacing tra di essi */
        var listWidth = (container.shoeListElementWidth) * filteredList.count + (filteredList.spacing * (filteredList.count - 1));

        if(listWidth >= listContainer.width)
            return 0;

        return (listContainer.width/2 - listWidth/2);
    }
}
