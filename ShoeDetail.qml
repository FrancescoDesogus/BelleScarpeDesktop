import QtQuick 2.0

Item
{
    FontLoader { id: metroFont; source: "qrc:segeo-wp.ttf" }
    id: container
    width: 500 * scaleX
    height: parent.height
    anchors.leftMargin: 100 * scaleX

    property int titleFontSize: 25

    /**
      Vai col vaneggio
      numberOfSizesPerLine: definisce il numero di taglie per singola linea (ad es 8 (da 39 a 46 compresi)
      numberOfSizeLines: mi dice invece quante linee di taglie saranno presenti, ad esempio se sono 8 o meno
                        taglie la linea sarà 1, se sono da 8 a 16 tagli le linee diventano 2. Ottengo questo numero
                        dividendo la dimensione della map contentente le teglie, per il numero di taglie per linea
                        e arrotondando tutto sempre per eccesso
    **/

    property int numberOfSizesPerLine: 8
    property int numeroDiLineeTaglia: Math.ceil(Object.keys(shoe.sizes).length / numberOfSizesPerLine)


    //Signal che scatta quando viene rilevato un qualsiasi evento touch nell'interfaccia; serve per riazzerare il timer
    //che porta alla schermata di partenza dopo un tot di tempo di inattività
    signal touchEventOccurred()

    //L'intero container ha associata una MouseArea che ha il solo scopo di emettere il signal touchEventOccurred(), in modo
    //da avvisare chi userà il component ShoeDetail che è stato ricevuto un touch event
    MouseArea {
        anchors.fill: parent
        onClicked: container.touchEventOccurred()
    }


    Text {
        id: brand
        text: shoe.brand
        font.family: metroFont.name
        font.pointSize: titleFontSize
        font.weight: Font.Normal
        font.letterSpacing: 1.2
        color: "#9FB7BF"
//        height: 50 * scaleY
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.topMargin: 20 * scaleY
    }

    Rectangle {
        id: separator
        width: parent.width
        height: 1 * scaleY
        color: "#9FB7BF"
        anchors.top: brand.bottom
        anchors.topMargin: 10 * scaleY
    }

    DetailRectangle {
        id: brandMini
        general: "Marca"
        testo: shoe.brand
        numberOfSizeLines: numeroDiLineeTaglia
        isEven: false
        anchors.top:  separator.bottom
        anchors.topMargin: 10 * scaleY
    }


    DetailRectangle {
        id: model
        general: "Modello"
        testo: shoe.model
        numberOfSizeLines: numeroDiLineeTaglia
        isEven: true
        anchors.top:  brandMini.bottom
    }

    DetailRectangle {
        id: color
        general: "Colore"
        testo: shoe.color
        numberOfSizeLines: numeroDiLineeTaglia
        isEven: false
        anchors.top:  model.bottom
    }

    DetailRectangle {
        id: category
        general: "Categoria"
        testo: shoe.category
        numberOfSizeLines: numeroDiLineeTaglia
        isEven: true
        anchors.top:  color.bottom
    }

    DetailRectangle {
        id: sex
        general: "Sesso"
        testo: shoe.sex
        numberOfSizeLines: numeroDiLineeTaglia
        isEven: false
        anchors.top:  category.bottom
    }

    DetailRectangle {
        id: price
        general: "Prezzo"
        testo: shoe.price +"€"
        numberOfSizeLines: numeroDiLineeTaglia
        isEven: true
        anchors.top:  sex.bottom
    }

    Text {
        id: taglie
        text: "Taglie Disponibili"
        font.family: metroFont.name
        font.pointSize: 23
        font.weight: Font.Normal
        font.letterSpacing: 1.2
        color: "#9FB7BF"
        anchors.left: parent.left
        anchors.top: price.bottom
//        anchors.topMargin: 20 * scaleY
        height: 48 * scaleY
    }

    Rectangle {
        id: separatorTaglie
        width: parent.width
        height: 1 * scaleY
        color: "#9FB7BF"
        anchors.top: taglie.bottom
//        anchors.topMargin: 5 * scaleY
    }



    //Quando il component ha finito di caricare, inserisco gli oggetti per la taglia; dato che gli oggetti sono da caricare per forza
    //dinamicamente, bisogna farlo solo quando il component è stato completato
    Component.onCompleted: showSizes(shoe.sizes)


    /*
     * Funzione che si occupa di generare tutti i component per mostrare le taglie della scarpa presenti
     */
    function showSizes(sizes)
    {
        //Creo il component dal file apposito
        var component = Qt.createComponent("SizeRectangle.qml");

        //Variabile che conterrà una singola istanza di "component"
        var item;

        //Valore della coordinata x iniziale
        var startingX = 0;

        //Coordinate di ogni item; i loro valori incrementano
        var x = startingX;
        var y = separatorTaglie.y + separatorTaglie.height + (24 * scaleY);

        //Scorro tutti gli elementi contenuti nella map "sizes"; la map contiene, per ogni stringa della taglia, un booleano
        //che indica se quella taglia è attualmente disponibile o meno
        for(var size in sizes)
        {
            //Creo l'istanza corrente del component e la inseriso all'interno di "container"
            item = component.createObject(container);

            //Lo posiziono nella scena
            item.x = x;
            item.y = y;

            //Incremento la coordinata, aggiungendo un margine di separazione tra un elemento e l'altro
            x = x + item.width + (6*scaleX);

            //Se la nuova x supera la larghezza disponibile del container...
            if(x > container.width)
            {
                //...la riazzero...
                x = startingX;

                //...ed incremento invece la y, per scendere di fila
                y = y + item.height + (10*scaleY);
            }


            //Di default si assume che la taglia sia disponibile; se non lo è, attivo lo stato relativo in modo che cambi il colore
            if(!sizes[size])
                item.isAvailable = false;

            //Infine, inserisco il testo della taglia
            item.text = size;
        }
    }
}
