import QtQuick 2.0

Rectangle {

    id: container
    FontLoader { id: webFont; source: "http://dev.bowdenweb.com/a/fonts/segoe/wp/segeo-wp.ttf" }

    /** Proprietà fisse, che non verranno cambiate all'esterno **/
    property string evenColor: "#EBEBEB"
    property string oddColor: "#FCFCFC"
    property string defaultColor: "#00000000"
    property int fontSize: 20
    property int margin: 40 * scaleX

    property int sizeItemHeight: (15*scaleY) + (60 * scaleY)
    property int defaultRectangleHeight: 100 * scaleY
    property int rectangleHeight: (numberOfSizeLines < 2) ? (defaultRectangleHeight + (sizeItemHeight/6)) : defaultRectangleHeight

    /** Proprietà variabili che potrebbero essere cambiate all'esterno **/
    property string general: "Generale"
    property string testo: "Testo"
    property int numberOfSizeLines: 2
    property bool isEven: true;

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

//    color: (isEven) ? (evenColor) : (oddColor)
    color: defaultColor
    height: rectangleHeight
    width: parent.width

    Text {
        id: generalText
        text: general
        font.family: webFont.name
        font.pointSize: fontSize
        font.weight: Font.Light
//        font.letterSpacing: 1.2
        color: "#9FB7BF"
        anchors.top: container.top
        anchors.topMargin: 20 * scaleY
        anchors.left: container.left
    }

    Text {
        id: text
        text: testo
        font.family: webFont.name
        font.pointSize: fontSize
//        font.letterSpacing: 1.2
        color: "#111111"
        anchors.left: generalText.left
        anchors.top: generalText.bottom
        anchors.topMargin: 5 * scaleY
    }
}
