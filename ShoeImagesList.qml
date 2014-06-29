import QtQuick 2.0
import QtWebKit 3.0

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
    property real thumbnailListContainerWidth: (thumbnailWidth + 30 * scaleX)

    //Dimensioni dell'immagine/video corrispondente alla thumbnail selezionata
    property real mainImageWidth: 500 * scaleX
    property real mainImageHeight: 800 * scaleY

    //Dimensioni del player di youtube corrispondente al video selezionato
    property real youtubePlayerWidth: 500 * scaleX
    property real youtubePlayerHeight: 500 * scaleY

    //Dimensioni totali di TUTTO il component definito in questo file. La larghezza è data dalla somma della larghezza della lista
    //e di quella dell'immagine principale, mentre l'altezza è pari a quella del padre (pari all'altezza dello schermo)
    property real totalComponentWidth: thumbnailListContainerWidth + mainImageWidth
    property real totalComponentHeight: parent.height



    /**************************************************************
     * Signal emessi verso l'esterno
     **************************************************************/

    //Signal che scatta quando si preme sulla mainImage; è usato da ShoeView per mostrare in focus l'immagine clickata
    signal mainImageClicked (int listIndex)

    //Signal che scatta quando viene rilevato un qualsiasi evento touch nell'interfaccia; serve per riazzerare il timer
    //che porta alla schermata di partenza dopo un tot di tempo di inattività
    signal touchEventOccurred()



    /**************************************************************
     * Proprietà e componenti figli
     **************************************************************/


    height: parent.height
    width: totalComponentWidth

    //L'intero container ha associata una MouseArea che ha il solo scopo di emettere il signal touchEventOccurred(), in modo
    //da avvisare chi userà il component ShoeImagesList che è stato ricevuto un touch event
    MouseArea {
        anchors.fill: parent
        onClicked: superContainer.touchEventOccurred()
    }


    //Rettangolo temporaneo per avere uno sfondo per la lista?
    Rectangle {
        id: listBackground
        visible: true;
        width: thumbnailListContainerWidth //Larghezza della lista, presa tenendo conto anche della scrollbar
        height: parent.height
        color: "#FBFBFB"


        //MouseArea che avvisa quando arrivano touch events
        MouseArea {
            anchors.fill: parent
            onClicked: superContainer.touchEventOccurred()
        }


        //Contenitore della lista delle thumbnail; comprende anche la scrollbar
        Item {
            id: listContainer
            anchors.fill: parent

            //MouseArea che avvisa quando arrivano touch events
            MouseArea {
                anchors.fill: parent
                onClicked: superContainer.touchEventOccurred()
            }

            //Lista contenente le thumbnail
            ListView {
                id: thumbnailList

                //L'altezza è calcolata in base a diversi aspetti; più info nella funzione
                height: calculateListViewHeight()
                width: listBackground.width

                //La lista è ancorata al genitore sulla sinistra in modo da fissarla al bordo sinistro dello schermo, definendo
                //un margine per lasciare spazio alla scrollbar
                anchors {
                    left: parent.left
                    leftMargin: verticalScrollBar.width + (2 * scaleX)
                }

                //Posizione y di partenza per la lista
                y: calculateListPosition()

                orientation: "Vertical"

                //Il clipping fa scomparire gli elementi della lista quando attraversano i bordi della stessa
                clip: true

                //Attivo lo scrolling della lista solo se si vede la scrollbar, ovvero se la lista è così lunga da superare
                //l'altezza dello schermo (e quindi abbastanza grande da far comparire la scrollbar)
                boundsBehavior: verticalScrollBar.visible == false ? Flickable.StopAtBounds : Flickable.DragOverBounds

                //Per mostrare quale thumbnail è stata selezionata utilizzo la proprietà highlight, definendo cosa mostrare;
                //in questo caso viene mostrato come componente un rettanglo
                highlight: Rectangle {
                    id: highlight
                    width: thumbnailWidth
                    height: thumbnailHeight
                    color: "#44ADB3C7" //Colore nero con opacità
//                    radius: 5
                    border.color: "#BFC4D6"
                    border.width: 2.5 * scaleX
                    smooth: true

                    //Imposto che il rettangolo venga posizionato nelle stesse coordinate della thumbnail selezionata, ma con
                    //coordinata z maggiore per mostrarlo davanti
                    y: thumbnailList.currentItem.y
                    x: thumbnailList.currentItem.x
                    z: thumbnailList.currentItem.z + 1

                    //Definisco cosa fare quando varia la y; in questo caso viene fatta un'animazione per muovere il rettangolo
                    //in modo che segua l'elemento attualmente selezionato
                    Behavior on y {
                        NumberAnimation {
                            duration: 300
                            easing.type: Easing.OutCirc
                        }
                    }
                }

                //Di default il rettangolo segue già l'elemento attualmente selezionato, ma l'animazione è troppo lenta... quindi
                //disattivo l'opzione visto che l'ho fatta manualmente più sopra
                highlightFollowsCurrentItem: false

                //Modello della lista; contiene le informazioni da visualizzare ed è creato in C++
                model: thumbnailModel

                //Delegate della lista; definisce COME le informazioni devono essere visualizzate; in questo caso
                //nella forma di immagini
                delegate: Component {
                    //Ogni membro della lista sarà ciò che viene definito qua dentro; in questo caso ogni elemento sarà formato
                    //da una singola immagine
                    Image {
                        id: thumbnail

                        /* Le thumbnail possono essere riferite ad immagini o a video. Nel caso dei video, l'informazione
                         * che viene passata dal model è l'id del video (quello che sta' dopo "watch?v=" nell'url di un video
                         * di youtube). Da quell'id si possono ottenere l'url per la thumbnail del video e l'url per mostrare
                         * il video vero e proprio; per le thumbnail della lista però è importante solo il primo link, quello
                         * che serve appunto per ottenere la thumbnail. Allo stesso tempo però serve poter ottenere l'id del video
                         * e basta, che comparirebbe nella url per la thumbnail ma sarebbe difficile e costoso recuperarlo.
                         * Quindi creo una proprietà che contiene la sorgente di default per la thumbnail; nel caso in cui sia una
                         * thumbnail di una immagine, si avrà che "thumbnail.source == thumbnail.defaultSource"; nel caso in cui
                         * la thumbnail sia di un video, le due saranno diverse in quanto thumbnail.source conterrà l'url per
                         * ottenere la thumbnail del video mentre thumbnail.defaultSource conterrà esclusivamente l'id del video */
                        property string defaultSource: modelData

                        /* Creo anche una proprietà per capire velocemente se la thumbnail si riferisce ad un video oppure no.
                         * Per capire se si tratta di un video sfrutto il fatto che per le immagini salvate in locale appare
                         * sempre "file://"; quindi controllo se la parola "file" compare nella stringa oppure no */
                        property bool isVideo: (String(modelData).indexOf("file") == -1)

                        /* Se la thumbnail è di un video, inserisco il link per prendere la thumbnail del video (il link
                         * è sempre uguale, e le thumbnail si trovano sempre con default.jpg); altrimenti inserisco il source
                         * preso pari pari dal modello, che conterrà il path per trovare l'immagine in locale */
                        source: isVideo ? ("http://img.youtube.com/vi/" + defaultSource + "/default.jpg") : defaultSource

                        width: thumbnailHeight
                        height: thumbnailWidth

                        antialiasing: true


                        fillMode: Image.PreserveAspectFit

                        //MouseArea per intercettare gli eventi touch in modo da cambiare immagine
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                //Cambio l'indice della lista; automaticamente verrà cambiata anche la mainImage
                                thumbnailList.currentIndex = index

                                /* Se l'elemento selezionato non è un video, riavvio il timer che scorre da solo la lista,
                                 * in modo da non rompere le palle all'utente che sta premendo sulla lista; se si tratta
                                 * di un video, il timer viene blocato */
                                if(!isVideo)
                                    thumbnailMoverTimer.restart()
                                else
                                    thumbnailMoverTimer.stop()

                                //Avviso inoltre all'esterno che c'è stato un evento touch
                                superContainer.touchEventOccurred()
                            }
                        }

                        //Immagine per il playButton di youtube, che appare in overlay solo se la thumbnail è di un video
                        Image {
                            id: playButton

                            anchors.centerIn: parent

                            source: "https://pbs.twimg.com/profile_images/378800000444930032/63c9e86bf8a62d59b4347c7828c47d67.png"

                            width: 40 * scaleX
                            height: 40 * scaleY

                            //Rendo visibile il playButon solo se la thumbnail in questione è di un video
                            visible: isVideo
                        }


                        /* Per far che il player dei video sia già pronto a mostrarli quando l'utente preme su uno di essi,
                         * al termine della creazione della thumbnail controllo se si tratta di un video e nel caso metto la url
                         * del video nel player, per forzarlo a caricarsi */
                        Component.onCompleted: {
                            //Se si tratta di un video, defaultSource conterrà l'id del video stesso
                            if(isVideo)
                                youtubePlayer.url = "qrc:///qml/youtubePlayer.html?" + defaultSource;
                        }
                    }
                }

                focus: true
                spacing: 5 * scaleY //Spazio tra ogni componente della lista

                /* Quando cambia l'indice della lista (ovvero quando si preme su una thumbnail, o il timer scatta e sposta l'indice
                 * da solo) a seconda che la thumbnail corrisponda ad un video cambio il filepath della mainImage con quello della
                 * thumbnail attualmente selezionata o cambio la url del youtubePlayer */
                onCurrentIndexChanged: {
                    if(thumbnailList.currentItem.isVideo)
                    {
                        //Se si tratta di un video, cambio la url del player con quella del video associato alla thumbnail, ma solo
                        //se non è uguale a quella già memorizzata nel player, per evitare caricamente inutili
                        var youtubeLink = "qrc:///qml/youtubePlayer.html?" + thumbnailList.currentItem.defaultSource;

                        if(youtubePlayer.url != youtubeLink)
                            youtubePlayer.url = youtubeLink;

                        //Rendo visibile il player e invisibile la mainImage, nel caso non lo fossero già
                        youtubePlayer.visible = true;
                        mainImage.visible = false;
                    }
                    else
                    {
                        //Altrimenti se si tratta della thumbnail di una immagine, cambio il source della mainImage...
                        mainImage.source = thumbnailList.currentItem.source;

                        //...e la rendo visibile, nascondendo il player
                        mainImage.visible = true;
                        youtubePlayer.visible = false;
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


            //La scrollbar è definita in un file a parte e compare solo se l'altezza della lista supera l'altezza dello schermo
            ScrollBar {
                id: verticalScrollBar
                flickable: thumbnailList
                position: "left"
                listBackgroundColor: listBackground.color

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
    }

    //Immagine di dettaglio della thumbnail attualmente selezionata
    Image {
        id: mainImage

        width: mainImageWidth
        height: mainImageHeight

        clip: true
        smooth: true

        //Rendo la mainImage visibile inizialmente solo se l'item correntemente selezionato nella lista non è un video
        visible: !thumbnailList.currentItem.isVideo

        //Questa impostazione mantiene l'aspect ratio dell'immagine a prescindere dalla sua grandezza
        fillMode: Image.PreserveAspectFit

        //Inserisco come immagine iniziale quella della thumbnail attualmente selezionata (che è la prima)
        source: thumbnailList.currentItem.source


        //Ancoro l'immagine a sinistra della lista delle thumbnail e al centro dell'altezza del padre (il superContainer)
        anchors {
            left: listBackground.right
            verticalCenter: parent.verticalCenter
        }

        //Creo una MouseArea per avvisare all'esterno che è stata premuta l'immagine, in modo da mostrarla ingrandita
        MouseArea {
            anchors.fill: parent
            onClicked: {
                //Emetto il signal apposito...
                superContainer.mainImageClicked(thumbnailList.currentIndex)

                //...ed emetto anche il signal che serve per avvisare che c'è stato un evento touch generico
                superContainer.touchEventOccurred()
            }
        }

        //In modo da mettere un'animazione quando cambia si cambia immagine nella thumbnail list, creo un "Behavior on source" in
        //modo che scatti ogni volta che si cambia il filepath della mainImage (e quindi quando si seleziona una thumbnail diversa)
        Behavior on source {

            //Creo un'animazione di fade in
            NumberAnimation {
                target: mainImage

                properties: "opacity"
                duration: 300

                from: 0
                to: 1
            }
        }
    }


    //Questa WebView carica un file html contenente un iframe che utilizza l'API di YouTube per mostrare il player apposito;
    //di fatto quindi questo elemento corrisponde al player di YouTube
    WebView {
        id: youtubePlayer

        //Inizialmente il player è visibile solo se l'item correntemente selezionato nella lista è un video
        visible:thumbnailList.currentItem.isVideo

        //La url iniziale è il video se l'elemento selezionato attualmente è un video, altrimenti una stringa vuota
        url: thumbnailList.currentItem.isVideo ? ("qrc:///qml/youtubePlayer.html?" + thumbnailList.currentItem.source) : ""


        width: youtubePlayerWidth
        height: youtubePlayerHeight

        //Posiziono il player a destra della lista
        anchors {
            left: listBackground.right
            leftMargin: 40 * scaleX
            verticalCenter: parent.verticalCenter
        }

        //Per far si che non si vedano cose che non si dovrebbero vedere mentre il player carica, lo nascondo mettendo l'opacità
        //a 0 quando inizia a caricare e la rimetto a 1 quando finisce
        onLoadingChanged: {
//            console.log("loadRequest.status: " + loadRequest.status)
            switch (loadRequest.status)
            {
            case WebView.LoadStartedStatus:
                opacity = 0
                return
            case WebView.LoadSucceededStatus:
                opacity = 1
                return
            case WebView.LoadStoppedStatus:
            case WebView.LoadFailedStatus:
                break
            }
        }
    }

    //Questo timer si occupa di cambiare la thumbnail attualmente selezionata dopo un tot di tempo che non si seleziona una thumbnail.
    //Il timer si avvia da solo non appena la view diventa visibile e si blocca quando diventa invisibile
    Timer {
        id: thumbnailMoverTimer
        interval: 6000 //6 secondi
        running: false
        repeat: true

        //Quando scatta il timer, se si è raggiunta la fine della lista la riazzero, altrimenti incremento l'indice
        onTriggered:  {
            if(thumbnailList.currentIndex == thumbnailList.count - 1)
                thumbnailList.currentIndex = 0;
            else
            {
                thumbnailList.incrementCurrentIndex();

                /* Se l'elemento attuale dopo l'incremento è un video, riazzero l'index della lista */
                if(thumbnailList.currentItem.isVideo)
                    thumbnailList.currentIndex = 0;
            }
        }
     }


    //Quando la view diventa visible, avvio (o riavvio) il timer che scorre la lista delle thumbnail; quando diventa
    //invisibile, lo blocco
    onVisibleChanged: {
        if(visible)
        {
            thumbnailMoverTimer.restart();

            //Riporto anche l'indice della lista all'elemento iniziale
            thumbnailList.currentIndex = 0;
        }
        else
            thumbnailMoverTimer.stop();
    }


    //Quando si crea una view dopo un codice RFID, il metodo onVisibleChanged non è chiamato, quindi inizialmente il timer non
    //si riavvia da solo; per questo motivo appena il component finisce di caricare lo avvio
    Component.onCompleted: thumbnailMoverTimer.restart();

    /*
     * Funzione che calcola l'altezza della ListView. Serve per dare il giusto spazio alla lista delle thumbnail, in modo
     * che la lista occupi lo spazio assolutamente necessario per contenerla e basta, in modo che il clipping quando si scorre
     * la lista oltre i suoi limiti avvenga in modo fluido.
     * Le grandezze usate nella funzione sono già tutte scalate, quindi non c'è bisogno di scalarle.
     */
    function calculateListViewHeight()
    {
        //Calcolo l'altezza della lista tenendo conto dell'altezza di ogni thumbnail e dello spacing tra ogni immagine
        var thumbnailListHeight = (thumbnailHeight * thumbnailList.count) + (thumbnailList.spacing * (thumbnailList.count - 1));

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
     * coordinata y che la lista deve avere).
     * Le grandezze usate nella funzione sono già tutte scalate, quindi non c'è bisogno di scalarle.
     */
    function calculateListPosition()
    {
        //Se l'altezza totale della lista supera l'altezza totale del contenitore della lista (che è pari all'altezza dello schermo),
        //allora restituisco 0 in modo tale che la lista venga posizionata all'origine
        if(thumbnailList.height >= listBackground.height)
            return 0;

        //Altrimenti calcolo l'altezza dimezzata della lista, data dall'altezza dimezzata di ogni thumbnail per il loro
        //numero più lo spacing dimezzato che c'è tra ogni componente
        var listHalvedHeigth = (thumbnailHalvedHeight) * thumbnailList.count + (thumbnailList.spacing/2 * (thumbnailList.count - 1));


        //Restituisco quindi la posizione vera e propria, che è data dall'altezza dello schermo dimezzata meno lo spazio
        //occupato dall'altezza dimezzata della lista
        return (listBackground.height/2 - listHalvedHeigth);
    }
}
