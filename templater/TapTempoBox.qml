import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3

/**
 * 1.0.0 Version initiale (tirée de TapTempo et séparation en TapTempoBox et TempoUnitBox)
 */

RowLayout {
    // id
    id: control

    // layout
    spacing: 5
    
    // control
    property var sizeMult: 1.5
    
    property var buttonColor: "#21be2b"
    property var buttonDownColor: "#17a81a"

    // returned values
    property var tempoText: { {
            var settings = lstMult.unitText;

            if (settings == undefined || tempo <= 0) {
                return null;
            }

            return lstMult.unitText + ' = ' + tempo;
        }
    }
    property var tempoValue: { {
            return tempo * tempomult;
        }
    }

    // inner data
    readonly property int averageOn: 5
    property var lastclicks: []
    property var tempo: -1
    property alias tempomult: lstMult.unitDuration

    property var tempoElement

    property var curSegment


    // Components
    TempoUnitBox {
        id: lstMult

        sizeMult: control.sizeMult

        implicitHeight: 40*sizeMult
        implicitWidth: 90

    }

    SpinBox {
        id: txtTempo
        Layout.preferredHeight: 40*sizeMult
        from: 0
        to: 360
        stepSize: 1

        editable: true

        font.pointSize: 8.6*sizeMult
        textFromValue: function (value) {
            var text = (value > 0) ? value : "";
            //debugO("textFromValue", text);
            return text;
        }

        valueFromText: function (text) {
            var val = (text === "") ? -1 : parseInt(text);
            if (isNaN(val))
                val = -1;
            // debugO("valueFromText", val);
            return val;
        }

        onValueChanged: tempo = value // triggers a Binding loop but without it manual modifications are not reported to the tempo variable

            Binding on value {
            value: tempo
        }

        validator: IntValidator {
            locale: txtTempo.locale.name
            bottom: 0
            top: txtTempo.to
        }

    }
    Button {
        id: btnTap
        text: "Tap!"

        font.pointSize: 10*sizeMult

        background: Rectangle {
            implicitWidth: 40*sizeMult
            implicitHeight: 40*sizeMult
            color: btnTap.down ? buttonDownColor : buttonColor
            radius: 4
        }

        onClicked: {
            if (lastclicks.length == averageOn)
                lastclicks.shift(); // removing oldest one
            lastclicks.push(new Date());
            if (lastclicks.length >= 2) {
                var avg = 0;
                for (var i = 1; i < lastclicks.length; i++) {
                    avg += (lastclicks[i] - lastclicks[i - 1]);
                }
                console.log("total diffs: " + avg);
                avg = avg / (lastclicks.length - 1);
                console.log("avg diffs: " + avg);
                tempo = Math.round(60 * 1000 / avg);
                //debugO("--tempo", tempo);

            } else {
                tempo = -1;
            }

        }
    }

}