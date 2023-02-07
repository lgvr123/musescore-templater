import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3

/**
 * 1.0.0 Version initiale tirée de TapTempo
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
            console.log("mult: " + tempomult);
            console.log("tempo: " + tempo);
            var settings = multipliers.find(function (e) {
                return e.mult === tempomult
            });

            if (settings == undefined || tempo <= 0) {
                return null;
            }

            return settings.sym + ' = ' + tempo;
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
    property var tempomult: 1

    property var tempoElement

    property var curSegment

    property var multipliers: [
        //mult is a tempo-multiplier compared to a crotchet
        {
            text: '\uECA2',
            mult: 4,
            sym: '<sym>metNoteWhole</sym>'
        }, // 1/1
        {
            text: '\uECA3 \uECB7',
            mult: 3,
            sym: '<sym>metNoteHalfUp</sym><sym>metAugmentationDot</sym>'
        }, // 1/2.
        {
            text: '\uECA3',
            mult: 2,
            sym: '<sym>metNoteHalfUp</sym>'
        }, // 1/2
        {
            text: '\uECA5 \uECB7 \uECB7',
            mult: 1.75,
            sym: '<sym>metNoteQuarterUp</sym><sym>metAugmentationDot</sym><sym>metAugmentationDot</sym>'
        }, // 1/4..
        {
            text: '\uECA5 \uECB7',
            mult: 1.5,
            sym: '<sym>metNoteQuarterUp</sym><sym>metAugmentationDot</sym>'
        }, // 1/4.
        {
            text: '\uECA5',
            mult: 1,
            sym: '<sym>metNoteQuarterUp</sym>'
        }, // 1/4
        {
            text: '\uECA7 \uECB7 \uECB7',
            mult: 0.875,
            sym: '<sym>metNote8thUp</sym><sym>metAugmentationDot</sym><sym>metAugmentationDot</sym>'
        }, // 1/8..
        {
            text: '\uECA7 \uECB7',
            mult: 0.75,
            sym: '<sym>metNote8thUp</sym><sym>metAugmentationDot</sym>'
        }, // 1/8.
        {
            text: '\uECA7',
            mult: 0.5,
            sym: '<sym>metNote8thUp</sym>'
        }, // 1/8
        {
            text: '\uECA9 \uECB7 \uECB7',
            mult: 0.4375,
            sym: '<sym>metNote16thUp</sym><sym>metAugmentationDot</sym><sym>metAugmentationDot</sym>'
        }, //1/16..
        {
            text: '\uECA9 \uECB7',
            mult: 0.375,
            sym: '<sym>metNote16thUp</sym><sym>metAugmentationDot</sym>'
        }, //1/16.
        {
            text: '\uECA9',
            mult: 0.25,
            sym: '<sym>metNote16thUp</sym>'
        }, //1/16
    ]

    // Components
    ComboBox {
        id: lstMult
        model: multipliers

        textRole: "text"

        // property var valueRole: "mult"
        property var comboValue: "mult"

        onActivated: {
            // loopMode = currentValue;
            tempomult = model[currentIndex][comboValue];
            console.log(tempomult);
        }

        Binding on currentIndex {
            value: multipliers.map(function (e) {
                return e[lstMult.comboValue]
            }).indexOf(tempomult);
        }

        implicitHeight: 40*sizeMult
        implicitWidth: 90

        font.family: 'MScore Text'
        font.pointSize: 10*sizeMult

        delegate: ItemDelegate {
            contentItem: Text {
                text: modelData[lstMult.textRole]
                verticalAlignment: Text.AlignVCenter
                font: lstMult.font
            }
            highlighted: multipliers.highlightedIndex === index

        }

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