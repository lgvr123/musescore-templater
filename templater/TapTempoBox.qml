import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3

/**
 * Exposed properties:
 * - tempo: the tempo value by unitDuration	[ReadWrite]
 * - unitDuration: the base duration selected (4 for a whole, 1 for a quarter, ...)  [ReadWrite]
 * - tempoText: a representation with Symbols of the selected tempo [ReadOnly]
 * - tempoValue: Quarter-based tempo value  [ReadOnly]
 * - unitFractionDenum: the denumerator of the fraction to use for durations [ReadOnly]
 *
 * Versions history
 * 1.0.0 Version initiale (tirée de TapTempo et séparation en TapTempoBox et TempoUnitBox)
 * 1.0.1 Nouvelle approche du Binding
 * 1.0.1 New setBeatBaseFromMarking function
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

    // input properties
    property alias tempoMult: lstMult.unitDuration
    property var tempo: -1

    // returned values
    readonly property var tempoText: { {
            var settings = lstMult.unitText;

            if (settings == undefined || tempo <= 0) {
                return null;
            }

            return lstMult.unitText + ' = ' + tempo;
        }
    }
    readonly property var tempoValue: { {
            return tempo * tempoMult;
        }
    }

    onTempoChanged: {
        //the tempo property changed from an external property set => we propagate this to the SpinBox
        if (!txtTempo._inOnActivated) {
            txtTempo.value=tempo;
        }
    }

    // inner data
    readonly property int averageOn: 5
    property var lastclicks: []

    property var tempoElement

    property var curSegment


    // Components
    TempoUnitBox {
        id: lstMult
        unitDuration: 1

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

        property var _inOnActivated: false

        onValueChanged: {
            _inOnActivated=true;
            tempo = value;
            _inOnActivated=false;
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

	/// Analyses tempo marking text to attempt to discover the base beat being used
	/// If a beat is NOT detected, it does nothing
	function setBeatBaseFromMarking(tempoMarking) {
	    // First look for metronome marking symbols
		var foundTempoText=tempoMarking.text.replace('<sym>space</sym>', '');
	    var foundMetronomeSymbols = foundTempoText.match(/(<sym>met.*<\/sym>)+/g);

	    // strip html tags and split around '='
		var data = foundTempoText.replace(/<.*?>/g,'').split('=');
		var tempo=parseInt(data[1]);
		if (isNaN(tempo)) tempo=0;


	    if (foundMetronomeSymbols !== null) {
            // Locate the index in our dropdown matching the found beatString
            for( var i = lstMult.multipliers.rowCount(); --i>=0 ; ) {
	            if (lstMult.multipliers.get(i).sym == foundMetronomeSymbols[0]) {
	                // Found this marking in the dropdown at metronomeMarkIndex
	                return {multiplier: lstMult.multipliers.get(i).mult, tempo: tempo};
	            }
            }
	    } else {
	        // Metronome marking symbols are substituted with their character entity if the text was edited
	        // UTF-16 range [\uECA0 - \uECB6] (double whole - 1024th)
	        for (var beatString, charidx = 0; charidx < foundTempoText.length; charidx++) {
	            beatString = foundTempoText[charidx];
	            if ((beatString >= "\uECA2") && (beatString <= "\uECA9")) {
	                // Found base tempo - continue looking for augmentation dots
	                while (++charidx < foundTempoText.length) {
	                    if (foundTempoText[charidx] == "\uECB7") {
	                        beatString += " \uECB7";
	                    } else if (foundTempoText[charidx] != ' ') {
	                        break; // No longer augmentation dots or spaces
	                    }
	                }
	                // Locate the index in our dropdown matching the found beatString

                    for( var i = lstMult.multipliers.rowCount(); --i>=0 ; ) {
                        if (lstMult.multipliers.get(i).text == beatString) {
                                    // Found this marking in the dropdown at metronomeMarkIndex
                            return {multiplier: lstMult.multipliers.get(i).mult, tempo: tempo};
                        }
                    }
	                break; // Done processing base tempo
	            }
	        }
	    }
	    return {multiplier: -1, tempo: tempo};
	}


}