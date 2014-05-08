import QtQuick 2.0

Item
{
    id: container
    width: 650 * scaleX
    height: parent.height
    anchors.leftMargin: 10 * scaleX

    property int titleFontSize: 27
    property int fontSize: 16
    property int margin: 40 * scaleX
    property string evenColor: "#EBEBEB"
    property string oddColor: "#FCFCFC"

    /**
      Vai col vaneggio
      numberOfSizesPerLine: definisce il numero di taglie per singola linea (ad es 8 (da 39 a 46 compresi)
      numberOfSizeLines: mi dice invece quante linee di taglie saranno presenti, ad esempio se sono 8 o meno
                        taglie la linea sarà 1, se sono da 8 a 16 tagli le linee diventano 2. Ottengo questo numero
                        dividendo la dimensione della map contentente le teglie, per il numero di taglie per linea
                        e arrotondando tutto sempre per eccesso
      sizeItemHeight: definisce la dimensione di una singola linea, data dalla somma dello spacing verticale (15)
                      e dell'altezza del rettangolino contenente la taglia
      defaultRectangleHeight: definisce l'altezza standard delle linee contenenti i dettagli della scarpa
                              nel caso ci siano 2 linee delle taglie
      rectangleHeight: qui avviene la MAGIA!! Controllo se le linee delle taglie sono minori di 2, se si, ho una singola linea
                       quindi divido l'altezza della linea mancante per 7 (le linee dei dettagli e il titolo)
                       e sommo questa quantita divisa all'altezza standard, così da eguagliare l'altezza per tutte le 7 linee
                       se invece e linee sono 2 lascio l'altezza standard
    **/

    property int numberOfSizesPerLine: 8
    property int numberOfSizeLines: Math.ceil(Object.keys(shoe.sizes).length / numberOfSizesPerLine)
    property int sizeItemHeight: (15*scaleY) + (60 * scaleY)

    property int defaultRectangleHeight: 80 * scaleY
    property int rectangleHeight: (numberOfSizeLines < 2) ? (defaultRectangleHeight + (sizeItemHeight/6)) : defaultRectangleHeight

    Text {
        id: brand
        text: shoe.brand
        font.family: "Helvetica Neue"
        font.pointSize: titleFontSize
        color: "red"
        height: 70 * scaleY
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 20 * scaleY
    }

    Rectangle {
        id: brandMiniRectangle
        color: evenColor
        anchors.top:  brand.bottom
        height: rectangleHeight
        width: parent.width

        Text {
            id: brandMiniGeneral
            text: "Marca:"
            font.family: "Helvetica"
            font.pointSize: fontSize
            color: "black"
            anchors.left: brandMiniRectangle.left
            anchors.leftMargin: margin
            anchors.verticalCenter: brandMiniRectangle.verticalCenter
        }

        Text {
            id: brandMini
            text: shoe.brand
            font.family: "Helvetica"
            font.pointSize: fontSize
            color: "black"
            anchors.right: brandMiniRectangle.right
            anchors.rightMargin: margin
            anchors.verticalCenter: brandMiniRectangle.verticalCenter
        }
    }

    Rectangle {
        id: modelRectangle
        color: oddColor
        anchors.top:  brandMiniRectangle.bottom
        height: rectangleHeight
        width: parent.width

        Text {
            id: modelGeneral
            text: "Modello:"
            font.family: "Helvetica"
            font.pointSize: fontSize
            color: "black"
            anchors.left: modelRectangle.left
            anchors.leftMargin: margin
            anchors.verticalCenter: modelRectangle.verticalCenter
        }

        Text {
            id: model
            text: shoe.model
            font.family: "Helvetica"
            font.pointSize: fontSize
            color: "black"
            anchors.right: modelRectangle.right
            anchors.rightMargin: margin
            anchors.verticalCenter: modelRectangle.verticalCenter
        }
    }

    Rectangle {
        id: colorRectangle
        color: evenColor
        anchors.top:  modelRectangle.bottom
        height: rectangleHeight
        width: parent.width

        Text {
            id: colorGeneral
            text: "Colore:"
            font.family: "Helvetica"
            font.pointSize: fontSize
            color: "black"
            anchors.left: colorRectangle.left
            anchors.leftMargin: margin
            anchors.verticalCenter: colorRectangle.verticalCenter
        }

        Text {
            id: color
            text: shoe.color
            font.family: "Helvetica"
            font.pointSize: fontSize
            color: "black"
            anchors.right: colorRectangle.right
            anchors.rightMargin: margin
            anchors.verticalCenter: colorRectangle.verticalCenter
        }
    }

    Rectangle {
        id: categoryRectangle
        color: oddColor
        anchors.top:  colorRectangle.bottom
        height: rectangleHeight
        width: parent.width

        Text {
            id: categoryGeneral
            text: "Categoria:"
            font.family: "Helvetica"
            font.pointSize: fontSize
            color: "black"
            anchors.left: categoryRectangle.left
            anchors.leftMargin: margin
            anchors.verticalCenter: categoryRectangle.verticalCenter
        }

        Text {
            id: category
            text: shoe.category
            font.family: "Helvetica"
            font.pointSize: fontSize
            color: "black"
            anchors.right: categoryRectangle.right
            anchors.rightMargin: margin
            anchors.verticalCenter: categoryRectangle.verticalCenter
        }
    }

    Rectangle {
        id: sexRectangle
        color: evenColor
        anchors.top:  categoryRectangle.bottom
        height: rectangleHeight
        width: parent.width

        Text {
            id: sexGeneral
            text: "Sesso:"
            font.family: "Helvetica"
            font.pointSize: fontSize
            color: "black"
            anchors.left: sexRectangle.left
            anchors.leftMargin: margin
            anchors.verticalCenter: sexRectangle.verticalCenter
        }

        Text {
            id: sex
            text: shoe.sex
            font.family: "Helvetica"
            font.pointSize: fontSize
            color: "black"
            anchors.right: sexRectangle.right
            anchors.rightMargin: margin
            anchors.verticalCenter: sexRectangle.verticalCenter
        }
    }

    Rectangle {
        id: priceRectangle
        color: oddColor
        anchors.top:  sexRectangle.bottom
        height: rectangleHeight
        width: parent.width

        Text {
            id: priceGeneral
            text: "Prezzo:"
            font.family: "Helvetica"
            font.pointSize: fontSize
            color: "black"
            anchors.left: priceRectangle.left
            anchors.leftMargin: margin
            anchors.verticalCenter: priceRectangle.verticalCenter
        }

        Text {
            id: price
            text: shoe.price + "€"
            font.family: "Helvetica"
            font.pointSize: fontSize
            color: "black"
            anchors.right: priceRectangle.right
            anchors.rightMargin: margin
            anchors.verticalCenter: priceRectangle.verticalCenter
        }
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
        var y = priceRectangle.y + priceRectangle.height + (20 * scaleY);

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
            x = x + item.width + (7*scaleX);

            //Se la nuova x supera la larghezza disponibile del container...
            if(x > container.width)
            {
                //...la riazzero...
                x = startingX;

                //...ed incremento invece la y, per scendere di fila
                y = y + item.height + (15*scaleY);
            }

            //Di default si assume che la taglia sia disponibile; se non lo è, attivo lo stato relativo in modo che cambi il colore
            if(!sizes[size])
                item.state = item.unavailable;

            //Infine, inserisco il testo della taglia
            item.text = size;
        }
    }
}
