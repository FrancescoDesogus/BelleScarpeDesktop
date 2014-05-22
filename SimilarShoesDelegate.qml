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

    property bool filtered: false;


    //Proprietà per la lista delle scarpe simili
    property real similarImageWidth: 150 * scaleX
    property real similarImageHeight: 120 * scaleY
    property real similarTitleFontPointSize: 14
    property real similarTextFontPointSize: 12
    property real similarTopMargin: 7 * scaleY
    property real similarLeftMargin: 0

    //Proprietà per la lista delle scarpe filtrate
    property real filteredImageWidth: 130 * scaleX
    property real filteredImageHeight: 100 * scaleY
    property real filteredTitleFontPointSize: 13
    property real filteredTextFontPointSize: 12
    property real filteredTopMargin: 16 * scaleY
    property real filteredLeftMargin: 7 * scaleX

    //Dato che deve essere possibile accedere al separator da fuori, uso un alias
    property alias separator: separator

    radius: filtered ? 4 : 0

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
        width: filtered ? (parent.width - (9 * scaleX)) : parent.width
        height: (1 * scaleY)
        color: filtered ? "#AEAEAE" : "#9FB7BF"
        anchors.bottom: suggestionContainer.bottom
        anchors.bottomMargin: -(1 * scaleY)
        anchors.right: filtered ? suggestionContainer.right : undefined
    }

    Rectangle {
        id: separatorFiltered
        height: parent.height - (10 * scaleY)
        width: 1 * scaleX
        color: "#AEAEAE"
        anchors.right: suggestionContainer.right
        anchors.rightMargin: -(1 * scaleX)
        anchors.bottom: suggestionContainer.bottom
        visible: filtered
    }
}
