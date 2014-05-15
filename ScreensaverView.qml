import QtQuick 2.0

Rectangle
{
//    anchors.fill: parent
    width: parent.width
    height: parent.height

    Text {
        text: "I'm a timeout screen, pleased to make your acquaintance."

        anchors.centerIn: parent
    }


    transform: [
        Rotation {
            id: rotationNextView
            origin.x: 0
            origin.y: 0
            axis.x: 0; axis.y: 1; axis.z: 0     // set axis.y to 1 to rotate around y-axis
            angle: 0
        },
        Rotation {
             id: rotationCurrentView
             origin.x: 0
             origin.y: 0
             axis.x: 0; axis.y: 1; axis.z: 0     // set axis.y to 1 to rotate around y-axis
             angle: 0    // the default angle
        }
    ]

    states: [
        State {
            id: flipStateNextView
             name: "flipNextView"
             PropertyChanges { target: rotationNextView; angle: 0 }
    //             when: flipable.flipped
        },

        State {
            id: flipStateCurrentView
             name: "flipCurrentView"
             PropertyChanges { target: rotationCurrentView; angle: -180 }
        }
    ]

     transitions: [
         Transition {
             id: flipTransitionNextView

             to: "flipNextView"

             NumberAnimation {
                 target: rotationNextView;
                 property: "angle";
                 duration: 1000
            }

             onRunningChanged: {
                 console.log("ci sono?")
             }
        },

         Transition {
             id: flipTransitionCurrentView

             to: "flipCurrentView"

             NumberAnimation {
                 target: rotationCurrentView;
                 property: "angle";
                 duration: 1000
            }

             onRunningChanged: {
                 console.log("ci sono!")
             }
        }
     ]
}
