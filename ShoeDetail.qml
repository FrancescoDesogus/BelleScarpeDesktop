import QtQuick 2.0

Item
{
    width: 100
    height: 62

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

        MouseArea {
            anchors.fill: parent
            onClicked: prova(shoe.sizes)
        }


    }

    function prova(anObject)
    {
        for (var prop in anObject)
        {
                    console.log("Object item:", prop, "=", anObject[prop])
                }

    }
}
