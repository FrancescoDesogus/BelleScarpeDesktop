import QtQuick 2.0

/*
 * Contenitore principale; al suo interno ci sarà la lista delle thumbnail (compresa la scrollbar) e l'immagine/video
 * corrispondente alla thumbnail selezionata
 */
Rectangle {

    id: superContainer

    /**************************************************************
     * Costanti usate per definire le grandezze dei vari elementi
     **************************************************************/

    //Dimensioni di ogni thumbnail della lista
    property real thumbnailWidth: 140 * scaleX
    property real thumbnailHeight: 140 * scaleY
    property real thumbnailHalvedHeight: thumbnailHeight / 2

    //Larghezza totale della lista (tiene conto della larghezza della scrollbar)
    property real thumbnailListContainerWidth: (thumbnailWidth + 30) * scaleX

    //Dimensioni dell'immagine/video corrispondente alla thumbnail selezionata
    property real mainImageWidth: 600 * scaleX
    property real mainImageHeight: 900 * scaleY

    //Dimensioni totali di TUTTO il component definito in questo file. La larghezza è data dalla somma della larghezza della lista
    //e di quella dell'immagine principale, mentre l'altezza è pari a quella del padre (pari all'altezza dello schermo)
    property real totalComponentWidth: thumbnailListContainerWidth + mainImageWidth
    property real totalComponentHeight: parent.height



    signal mainImageClicked (string imageSource)



    height: parent.height
    width: totalComponentWidth

    //Rettangolo temporaneo per avere uno sfondo per la lista?
    Rectangle {
        id: listBackground
        visible: true;
        width: thumbnailListContainerWidth //Larghezza della lista, presa tenendo conto anche della scrollbar
        height: parent.height
        color: "#DDDDDD"


        //Contenitore della lista delle thumbnail; comprende anche la scrollbar
        Item {
            id: listContainer
            anchors.fill: parent

            //Lista contenente le thumbnail
            ListView {
                id: listView
                height: calculateListViewHeight() //L'altezza è calcolata in base a diversi aspetti; more info nella funzione
                width: listBackground.width
                orientation: "Vertical"
                y: calculateListPosition() //Posizione y di partenza per la lista
                clip: true //Il clipping fa scomparire gli elementi della lista quando attraversano i bordi della stessa


                //La lista è ancorata al genitore sulla sinistra in modo da fissarla al bordo sinistro dello schermo, definendo
                //un margine per lasciare spazio alla scrollbar
                anchors {
                    left: parent.left
                    leftMargin: 25 * scaleX
                }

                //Modello della lista; contiene le informazioni da visualizzare ed è creato in C++
                model: myModel

                //Delegate della lista; definisce COME le informazioni devono essere visualizzate; in questo caso
                //nella forma di immagini
                delegate: Component {
                    //Ogni membro della lista sarà ciò che viene definito qua dentro; in questo caso ogni elemento sarà formato
                    //da una singola immagine
                    Image {
                        id: thumbnail
                        source: "file:///" + model.modelData.source //Il path per l'immagine è preso dal modello, ricevuto da C++
                        width: thumbnailHeight
                        height: thumbnailWidth

                        //MouseArea per intercettare gli eventi touch in modo da cambiare immagine
                        MouseArea {
                            anchors.fill: parent
                            onClicked: mainImage.source = thumbnail.source
                        }
                    }
                }

                focus: true
                spacing: 5 //Spazio tra ogni componente della lista
            }

            //La scrollbar è definita in un file a parte e compare solo se l'altezza della lista supera l'altezza dello schermo
            ScrollBar {
                id: verticalScrollBar
                flickable: listView
            }
        }
    }

    //Immagine di dettaglio della thumbnail attualmente selezionata
    Image {
        id: mainImage
        width: mainImageWidth
        height: mainImageHeight
        clip: true
        fillMode: Image.PreserveAspectFit //Questa impostazione mantiene l'aspect ratio dell'immagine a prescindere dalla sua grandezza
        smooth: true
        source: "file:///" + imagesPath

        //Ancoro l'immagine a sinistra della lista delle thumbnail e al centro dell'altezza del padre (il superContainer)
        anchors {
            left: listBackground.right
            verticalCenter: parent.verticalCenter
        }

        MouseArea {
            anchors.fill: parent
            onClicked: superContainer.mainImageClicked(mainImage.source)
        }
    }



    /*
     * Funzione che calcola l'altezza della ListView. Serve per dare il giusto spazio alla lista delle thumbnail, in modo
     * che la lista occupi lo spazio assolutamente necessario per contenerla e basta, in modo che il clipping quando si scorre
     * la lista oltre i suoi limiti avvenga in modo fluido.
     * Le grandezze usate nella funzione sono già tutte scalate, quindi non c'è bisogno di scalarle.
     */
    function calculateListViewHeight()
    {
        //Numero di thumbnail presenti nella lista
        var thumbnailsCount = listView.count;

        //Calcolo l'altezza della lista tenendo conto dell'altezza di ogni thumbnail e dello spacing tra ogni immagine
        var thumbnailListHeight = (thumbnailHeight + listView.spacing * (thumbnailsCount - 1)) * thumbnailsCount;

        //Se l'altezza totale calcolata è minore dell'altezza del background (che è pari all'altezza dello schermo), allora
        //viene restituita questa altezza
        if(thumbnailListHeight < listBackground.height)
            return thumbnailListHeight;
        //Altrimenti, se l'altezza della lista supera l'altezza dello schermo, restituisco quest'ultima
        else
            return listBackground.height;
    }


    /*
     * Funzione che calcola la posizione da cui deve partire la ListView contenente le thumbnail (in sostanza calcola la
     * coordinata y che la lista deve avere.
     * Le grandezze usate nella funzione sono già tutte scalate, quindi non c'è bisogno di scalarle.
     */
    function calculateListPosition()
    {
        //Calcolo l'altezza dimezzata della lista, data dall'altezza dimezzata di ogni thumbnail per il loro numero
        var listHalvedHeigth = thumbnailHalvedHeight * listView.count;

        //Se l'altezza totale della lista supera l'altezza totale del contenitore della lista (che è pari all'altezza dello schermo),
        //allora restituisco 0 in modo tale che la lista venga posizionata all'origine
        if(listHalvedHeigth*2 > listBackground.height)
            return 0;
        //Altrimenti restituisco la posizione vera e propria, che è data dall'altezza dello schermo a metà meno lo spazio
        //occupato dall'altezza dimezzata della lista
        else
            return (listBackground.height/2 - listHalvedHeigth);
    }
}
