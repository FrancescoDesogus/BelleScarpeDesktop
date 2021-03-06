import QtQuick 2.0

/*
 * Questo component rappresenta un singolo elemento visivo della lista di SimilarShoesList. E' stato necessario creare un file solo
 * per questo per poter creare una copia visiva degli elementi selezionati della lista (più info in SimilarShoesList.qml).
 * Qua dentro sono stabilite le proprietà generali, mentre quelle dipendenti da fattori esterni sono dichiarati al momento dell'uso
 * di questo component
 */
Rectangle {
    id: suggestionContainer

    //Font da usare
    property FontLoader textFont;

    //Proprietà che variano da scarpa a scarpa
    property string thumbnailSource;
    property string brandText;
    property string modelText;
    property string priceText;

    //Booleano per indicare se il component è usato per la lista delle scarpe simili o per quelle filtrate; in tal caso cambiano
    //alcuni dettagli visivi. Di default è usato con il look per le scarpe simili
    property bool filtered: false;


    //Proprietà per la lista delle scarpe simili
    property real similarImageWidth: 150 * scaleX
    property real similarImageHeight: 120 * scaleY
    property real similarTitleFontPointSize: 14
    property real similarTextFontPointSize: 12
    property real similarTopMargin: 7 * scaleY
    property real similarLeftMargin: 5 * scaleX

    //Proprietà per la lista delle scarpe filtrate
    property real filteredImageWidth: 120 * scaleX
    property real filteredImageHeight: 100 * scaleY
    property real filteredTitleFontPointSize: 12
    property real filteredTextFontPointSize: 11
    property real filteredTopMargin: 7 * scaleY
    property real filteredLeftMargin: 12 * scaleX

    //Dato che deve essere possibile accedere al separator da fuori, uso un alias
    property alias separator: separator

    radius: filtered ? 5 : 0

    Image {
        id: similarThumbnail
        antialiasing: true
        source: thumbnailSource
        width: filtered ? filteredImageWidth : similarImageWidth
        height: filtered ? filteredImageHeight : similarImageHeight
        fillMode: Image.PreserveAspectFit
        anchors.right: suggestionContainer.right
        anchors.rightMargin: 5 * scaleX
        anchors.verticalCenter: suggestionContainer.verticalCenter
    }

    Text {
        id: t1
        anchors.left: suggestionContainer.left
        anchors.leftMargin: filtered ? filteredLeftMargin : similarLeftMargin
        font.letterSpacing: 1.2
        color: "#9FB7BF"
        text: brandText + " " + modelText
        font.family: textFont.name
        font.pointSize: filtered ? filteredTitleFontPointSize : similarTitleFontPointSize
        font.weight: Font.Light
        width: suggestionContainer.width - (10 * scaleX)
        elide: Text.ElideRight
    }

    Text {
        id: brand
        anchors.top: t1.bottom
        anchors.topMargin: filtered ? filteredTopMargin : similarTopMargin
        anchors.left: suggestionContainer.left
        anchors.leftMargin: filtered ? filteredLeftMargin : similarLeftMargin
        text: brandText
        font.family: textFont.name
        font.pointSize: filtered ? filteredTextFontPointSize : similarTextFontPointSize
        font.weight: Font.Light
        width: suggestionContainer.width - (10 * scaleX)
        elide: Text.ElideRight
    }

    Text {
        id: model
        anchors.top: brand.bottom
        anchors.topMargin: filtered ? filteredTopMargin : similarTopMargin
        anchors.left: suggestionContainer.left
        anchors.leftMargin: filtered ? filteredLeftMargin : similarLeftMargin
        text: modelText
        font.family: textFont.name
        font.pointSize: filtered ? filteredTextFontPointSize : similarTextFontPointSize
        font.weight: Font.Light
        width: suggestionContainer.width - (10 * scaleX)
        elide: Text.ElideRight
    }

    Text {
        id: price
        anchors.top: model.bottom
        anchors.topMargin: filtered ? filteredTopMargin : similarTopMargin
        anchors.left: suggestionContainer.left
        anchors.leftMargin: filtered ? filteredLeftMargin : similarLeftMargin
        text: priceText + "€"
        font.family: textFont.name
        font.pointSize: filtered ? filteredTextFontPointSize : similarTextFontPointSize
        font.weight: Font.Light
        width: suggestionContainer.width - (10 * scaleX)
        elide: Text.ElideRight
    }

    Rectangle {
        id: separator
        width: parent.width
        height: (1 * scaleY)
        color: "#9FB7BF"
        anchors.bottom: suggestionContainer.bottom
        anchors.bottomMargin: -(1 * scaleY)
        visible: !filtered
    }


}
