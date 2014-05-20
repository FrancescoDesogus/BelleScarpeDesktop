import QtQuick 2.0

/*
 * Questo component rappresenta un singolo elemento visivo della lista di SimilarShoesList. E' stato necessario creare un file solo
 * per questo per poter creare una copia visiva degli elementi selezionati della lista (più info in SimilarShoesList.qml).
 * Qua dentro sono stabilite le proprietà generali, mentre quelle dipendenti da fattori esterni sono dichiarati al momento dell'uso
 * di questo component.
 */
Rectangle {
    id: suggestionContainer

    //Definisco solo l'altezza, in quanto la larghezza dipende dalla larghezza del container della lista, per cui è fissata dall'esterno
    height: 170 * scaleY

    //Font da usare
    property FontLoader textFont;

    //Proprietà che variano da scarpa a scarpa
    property string thumbnailSource;
    property string brandText;
    property string modelText;
    property string priceText;

    //Dato che deve essere possibile accedere al separator da fuori, uso un alias
    property alias separator: separator


    Behavior on color { ColorAnimation { duration: 100 }}

    Image {
        id: similarThumbnail
        antialiasing: true
        source: thumbnailSource
        width: 150 * scaleX
        height: 120 * scaleY
        fillMode: Image.PreserveAspectFit
        anchors.right: suggestionContainer.right
        anchors.rightMargin: 5 * scaleX
        anchors.verticalCenter: suggestionContainer.verticalCenter
    }

    Text {
        id: t1
        anchors.left: suggestionContainer.left
        font.letterSpacing: 1.2
        color: "#9FB7BF"
        text: brandText + " " + modelText
        font.family: textFont.name
        font.pointSize: 14
        font.weight: Font.Light
    }

    Text {
        id: brand
        anchors.top: t1.bottom
        anchors.topMargin: 7 * scaleY
        text: brandText
        font.family: textFont.name
        font.pointSize: 12
        font.weight: Font.Light
    }

    Text {
        id: model
        anchors.top: brand.bottom
        anchors.topMargin: 7 * scaleY
        text: modelText
        font.family: textFont.name
        font.pointSize: 12
        font.weight: Font.Light
    }

    Text {
        id: price
        anchors.top: model.bottom
        anchors.topMargin: 7 * scaleY
        text: priceText + "€"
        font.family: textFont.name
        font.pointSize: 12
        font.weight: Font.Light
    }

    Rectangle {
        id: separator
        width: parent.width
        height: 1 * scaleY
        color: "#9FB7BF"
        anchors.bottom: suggestionContainer.bottom
    }

}
