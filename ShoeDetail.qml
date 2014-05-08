import QtQuick 2.0

Item
{
    id: container
    width: 200 * scaleX
    height: parent.height

    Text {
        id: brand
        text: shoe.brand
        font.family: "Helvetica"
        font.pointSize: 24
        color: "red"
    }

    Text {
        id: model
        anchors.top: brand.bottom
        text: shoe.model
        font.family: "Helvetica"
        font.pointSize: 12
        color: "black"
    }

    Text {
        id: price
        anchors.top: model.bottom
        text: shoe.price + " €"
        font.family: "Helvetica"
        font.pointSize: 12
        color: "black"
    }

    Text {
        id: category
        anchors.top: price.bottom
        text: shoe.category
        font.family: "Helvetica"
        font.pointSize: 12
        color: "black"
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
        var y = 200;

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
            x = x + item.width + (1*scaleX);

            //Se la nuova x supera la larghezza disponibile del container...
            if(x > container.width)
            {
                //...la riazzero...
                x = startingX;

                //...ed incremento invece la y, per scendere di fila
                y = y + item.height + (1*scaleX);
            }

            //Di default si assume che la taglia sia disponibile; se non lo è, attivo lo stato relativo in modo che cambi il colore
            if(!sizes[size])
                item.state = item.unavailable;

            //Infine, inserisco il testo della taglia
            item.text = size;
        }
    }
}
