import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Dialogs 1.2 // FileDialogs
import QtQuick.Window 2.3
import Qt.labs.folderlistmodel 2.2
import Qt.labs.settings 1.0
import QtQml 2.8
import MuseScore 3.0
import FileIO 3.0

/**********************************************
/*  1.0.0: Initial version
/*  1.1.0: List of the files already exisitng starting with the same letter
/**********************************************/
MuseScore {
    menuPath: "Plugins." + qsTr("Templater")
    version: "1.1.0"
    requiresScore: false
    description: qsTr("Create a new score based on exsiting template")
    pluginType: "dialog"

    Component.onCompleted: {
        if (mscoreMajorVersion >= 4) {
            mainWindow.title = qsTr("Templater");
            mainWindow.thumbnailName = "logoTemplater.png";
            // mainWindow.categoryCode = "batch-processing";
        }
    }

    MessageDialog {
        id: versionError
        visible: false
        title: qsTr("Unsupported MuseScore Version")
        text: qsTr("This plugin does not work with MuseScore 4.0.")
        onAccepted: {
            mainWindow.parent.Window.window.close();
        }
    }

    onRun: {
        // check MuseScore version
        if (mscoreMajorVersion < 3 || mscoreMajorVersion > 3) { // we should really never get here, but fail at the imports above already
            mainWindow.visible = false
                versionError.open()
        }

        console.log(pathSettings.myTemplates)
        console.log(pathSettings.myScores)

        if (settings.iPath === "")
            settings.iPath = "file:///" + pathSettings.myTemplates;
        if (settings.ePath === "")
            settings.ePath = "file:///" + pathSettings.myScores;

        var f = importFrom.text;
        console.log("Template folder: " + f);
        files.folder = f;
        candidates.folder=exportTo.text;

        files.showDirs = false;
        files.showFiles = true;
        candidates.showDirs = false;
        candidates.showFiles = true;

    }

    id: mainWindow

    // `width` and `height` allegedly are not valid property names, works regardless and seems needed?!
    width: mainRow.childrenRect.width + mainRow.anchors.margins * 2
    height: mainRow.childrenRect.height + mainRow.anchors.margins * 2

    ColumnLayout {
        id: mainRow
        spacing: 2
        anchors.margins: 20

        GridLayout {
            Layout.margins: 20
            columnSpacing: 5
            rowSpacing: 5
            columns: 2

            Label {
                text: qsTranslate("Ms::TemplateBrowser", "Custom Templates") + ":"
            }

            RowLayout {
                spacing: 5

                ComboBox {
                    Layout.preferredWidth: 200

                    id: lstModels

                    model: files

                    textRole: "fileBaseName" // définit ce qui va être affiché dans le champ

                    delegate: ItemDelegate {
                        contentItem: Text {
                            text: fileBaseName // définit ce qui va être affiché dans la liste
                            verticalAlignment: Text.AlignVCenter
                        }
                        highlighted: lstModels.highlightedIndex === index
                    }

                }
                TextField {
                    Layout.preferredWidth: 300
                    id: importFrom
                    text: ""
                    color: sysDisabledPalette.shadow
                    enabled: false
                }
                Button {
                    text: qsTranslate("ScoreComparisonTool", "Browse") + "..."
                    onClicked: {
                        sourceFolderDialog.open()
                    }
                }
            }
            Label {
                text: qsTranslate("Ms::MuseScore", "Save As") + ":"
                Layout.bottomMargin: 20
            }

            RowLayout {
                spacing: 5

                Layout.bottomMargin: 20

                    TextField {
                        Layout.preferredWidth: 200
                        id: exportName
                        text: ""
                        selectByMouse: true

                        states: [
                            State {
                                name: "error"
                                PropertyChanges {
                                    target: exportName;
                                    color: "red"
                                    ToolTip.visible: hovered
                                    ToolTip.text: qsTr("The file %1 already exists").arg(fileDest.source)
                                }
                            },
                            State {
                                name: "valid"
                                PropertyChanges {
                                    target: exportName;
                                }
                            }
                        ]

                        onTextChanged: {
                            checkFileTimer.restart();
                        }

                        // Candidates filenames
                        Popup {
                            id: popup
                            x: 0
                            y: parent.implicitHeight
                            width: 400
                            height: Math.min(
                                contentItem.implicitHeight, 
                                parent.Window.height - topMargin - bottomMargin
                                ,300)

                            modal: false  
                            focus: false // don't take the focus. Let the user keep on typing 
                            closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent
                            
                            background: Rectangle {
                                color: sysActivePalette.window
                            }

                            contentItem: 
                            ListView {
                                model: candidates
                                visible: true
                                width: parent.width
                                anchors.margins: 0
                                anchors.fill: parent
                                implicitHeight: contentHeight
                                clip: true

                                Rectangle {
                                    z: 10
                                    width: parent.width
                                    height: parent.height
                                    color: "transparent"
                                    border.color: sysActivePalette.mid
                                }
                                
                                delegate: ItemDelegate {
                                    text: fileName
                                    width: parent.width
                                    
                                    property var fileExt: getFileSuffix(fileName)
                                    
                                    font.italic: fileExt!=="mscz"

                                
                                    // palette.text: (fileExt==="mscz")?sysActivePalette.text:sysActivePalette.mid
                                    
                                    onClicked: {
                                        exportName.text = fileBaseName;
                                        popup.close();
                                    }
                                }
                            }
                        }


                    }
                    
                
                TextField {
                    Layout.preferredWidth: 300
                    id: exportTo
                    text: ""
                    color: sysDisabledPalette.shadow
                    enabled: false
                }
                Button {
                    text: qsTranslate("ScoreComparisonTool", "Browse") + "..."
                    onClicked: {
                        targetFolderDialog.open()
                    }
                }
            }

            Label {
                text: mscoreMajorVersion > 3 ? qsTranslate("project", "Title") + ":"
                 : qsTranslate("NewWizard", "Title") + ":"
            }

            TextField {
                Layout.preferredWidth: 400
                id: title
                text: ""
                selectByMouse: true
            }

            Label {
                text: mscoreMajorVersion > 3 ? qsTranslate("project", "Subtitle") + ":"
                 : qsTranslate("NewWizard", "Subtitle") + ":"
            }

            TextField {
                Layout.preferredWidth: 400
                id: subtitle
                text: ""
                selectByMouse: true
            }

            Label {
                text: mscoreMajorVersion > 3 ? qsTranslate("project", "Composer") + ":"
                 : qsTranslate("NewWizard", "Composer") + ":" 
            }

            TextField {
                Layout.preferredWidth: 400
                id: composer
                text: ""
                selectByMouse: true
            }

            Label {
                text: mscoreMajorVersion > 3 ? qsTranslate("project", "Lyricist") + ":"
                 : qsTranslate("NewWizard", "Lyricist") + ":"
            }

            TextField {
                Layout.preferredWidth: 400
                id: lyricist
                text: ""
                selectByMouse: true
            }

            Label {
                text: mscoreMajorVersion > 3 ? qsTranslate("project", "Copyright") + ":"
                 : qsTranslate("NewWizard", "Copyright") + ":"
            }

            TextField {
                Layout.preferredWidth: 400
                id: copyright
                text: ""
                selectByMouse: true
            }

            Label {
                text: mscoreMajorVersion > 3 ? qsTranslate("project", "Tempo")
                 : qsTranslate("Ms::NewWizardKeysigPage", "Tempo")+":"
                Layout.topMargin: 20
            }

            TapTempoBox {
                id: tapTempo
                sizeMult: 1
                Layout.topMargin: 20
                buttonColor: sysActivePalette.mid
                buttonDownColor: sysActivePalette.shadow
            }
        }// GroupLayout
        Item {
            Layout.alignment: Qt.AlignBottom | Qt.AlignLeft
            Layout.fillWidth: true
            Layout.rightMargin: 10
            Layout.leftMargin: 10
            Layout.topMargin: 5
            Layout.preferredHeight: btnrow.implicitHeight
            RowLayout {
                id: btnrow
                spacing: 5
                anchors.fill: parent
                Item { // spacer
                    id: spacer
                    implicitHeight: 10
                    Layout.fillWidth: true
                }

                Button {
                    id: ok
                    enabled: (exportName.text !== "") && (lstModels.currentIndex !== -1)
                    text: qsTr("Create")
                    onClicked: {
                        work();

                    } // onClicked
                } // ok
                Button {
                    id: cancel
                    text: /*qsTr("Cancel")*/ qsTranslate("QPlatformTheme", "Close")
                    onClicked: {
                        mainWindow.parent.Window.window.close();
                    }
                } // Cancel
            } // RowLayout
        } // Item
    } // ColumnLayout
    
    // Plugin settings
    Settings {
        id: settings
        category: "TemplaterPlugin"
        property alias iPath: importFrom.text // import path
        property alias ePath: exportTo.text // export path
        property alias title: title.text
        property alias subtitle: subtitle.text
        property alias composer: composer.text
        property alias lyricist: lyricist.text
        property alias copyright: copyright.text
    }
    
    // MuseScore default values
    Settings {
        id: pathSettings
        category: "application/paths"
        property var myTemplates
        property var myScores
    }


    FileDialog {
        id: sourceFolderDialog
        title: qsTranslate("Ms::PreferenceDialog", "Choose Template Folder")
        selectFolder: true
        folder: Qt.resolvedUrl(importFrom.text);

        onAccepted: {
            importFrom.text = sourceFolderDialog.folder.toString();
            files.folder = importFrom.text;
        }
        onRejected: {
            console.log("No source folder selected")
        }

    } // sourceFolderDialog

    FileDialog {
        id: targetFolderDialog
        title: qsTr("Choose Destination Folder")
        selectFolder: true
        folder: Qt.resolvedUrl(exportTo.text);

        onAccepted: {
            exportTo.text = targetFolderDialog.folder.toString();
            candidates.folder = exportTo.text;
        }

        onRejected: {
            console.log("No target folder selected")
        }
    } // targetFolderDialog

    FileIO {
        id: fileDest
        source: { {
                var dest = urlToPath(exportTo.text);
                if (!dest.endsWith('/'))
                    dest += '/';
                dest = dest + exportName.text;
                if (!exportName.text.endsWith(".mscx") && !exportName.text.endsWith(".mscz")) {
                    dest = dest + ".mscz";
                }
                console.log("--> " + dest);
                return dest;
            }
        }

    }

    // FolderListModel for the models 
    FolderListModel {
        id: files
        nameFilters: ["*.mscz"]
    }

    // FolderListModel for the candidate targets 
    FolderListModel {
        id: candidates
        nameFilters: { {
                var similar = exportName.text;
                if (!exportName.text.endsWith(".mscx") && !exportName.text.endsWith(".mscz")) {
                    similar = similar + "*.*";
                }
                console.log("==> " + similar);
                return [similar];
            }
        }
    }

    function urlToPath(urlString) {
        var s;
        if (urlString.startsWith("file:///")) {
            var k = urlString.charAt(9) === ':' ? 8 : 7
                s = urlString.substring(k)
        } else {
            s = urlString
        }
        return decodeURIComponent(s);
    }

    function resetDefaults() {}
    // resetDefaults


    SystemPalette {
        id: sysActivePalette;
        colorGroup: SystemPalette.Active
    }
    SystemPalette {
        id: sysDisabledPalette;
        colorGroup: SystemPalette.Disabled
    }

    function buildExportPath(dest, tag, value, missing) {
        if (!value || value.trim() === "") {
            if (missing) {
                value = missing;
            } else {
                return dest; // return as such
            }
        } else {
            value = createDefaultFileName(value, true); // allow whitespaces
        }
        return dest.replace(tag, value);
    }

    // work
    function work() {
        if (lstModels.currentIndex==-1) return;
        if (!exportName.text) return;
        
        var source = files.get(lstModels.currentIndex, "filePath");
        
        var dest = fileDest.source;
        var ext = getFileSuffix(dest);
        dest = dest.substring(0, dest.length - ext.length - 1);

        console.log("Exporting " + source + " to " + dest + "." + ext);
        if (fileDest.exists())
            console.log("!! file already exists");

        // Ouvre le template, le sauvegarde sous un autre nom et le ferme
        var score = readScore(source, true);
        writeScore(score, dest, ext);
        closeScore(score);

        // Ouvrir la copie
        score = readScore(dest + "." + ext);

        score.startCmd();

        // Mettre le tempo, les textes, ...
        if (tapTempo.tempoText != "") {
            var cursor = score.newCursor();
            cursor.rewind(Cursor.SCORE_START);
            var tempoElement;

            // 1) On essaye de voir s'il y a déjà un tempo qu'il faudrait modifier
            var segment = cursor.segment;

            for (var i = segment.annotations.length; i-- > 0; ) {
                if (segment.annotations[i].type === Element.TEMPO_TEXT) {
                    tempoElement = (segment.annotations[i]);
                    break;
                }
            }

            // 2) Sinon on en crée un
            if (tempoElement) {
                tempoElement.text = tapTempo.tempoText;
            } else {
                tempoElement = newElement(Element.TEMPO_TEXT);
                tempoElement.text = tapTempo.tempoText;
                cursor.add(tempoElement);
            }

            //changing of tempo can only happen after being added to the segment
            tempoElement.tempo = tapTempo.tempoValue;
            tempoElement.tempoFollowText = true; //allows for manual fiddling by the user afterwards
        }

        // Mettre les textes, ...
        if (title.text != "") {
            score.setMetaTag("workTitle", title.text);
            score.addText("title", title.text);
        }

        if (subtitle.text != "") {
            score.setMetaTag("subtitle", subtitle.text);
            score.addText("subtitle", subtitle.text);
        }

        if (composer.text != "") {
            score.setMetaTag("composer", composer.text);
            score.addText("composer", composer.text);
        }

        if (lyricist.text != "") {
            score.setMetaTag("lyricist", lyricist.text);
            score.addText("lyricist", lyricist.text);
        }

        if (copyright.text != "") {
            score.setMetaTag("copyright", copyright.text);
            //score.addText("copyright", copyright);
        }

        score.endCmd();

        mainWindow.parent.Window.window.close(); //Qt.quit()

    }

    // Timer for target file name entry.
    // - test for unicity
    // - list file names similar to what has been typed
    Timer {
        id: checkFileTimer
        interval: 10 // 10ms
        repeat: false
        running: false

        onTriggered: {
            // - check for unicity
            var valid = !fileDest.exists();
            console.log("Filename is valid ? " + valid);
            exportName.state = valid ? "valid" : "error";

            // - list the similar file names
            var show = false;
            if (exportName.text !== lastCandidate) {
                if (exportName.text !== "") {
                    if (candidates.count === 0)
                        show = false;
                    else if ((candidates.count === 1)
                         && (candidates.get(0, "fileBaseName") === exportName.text))
                        show = false;
                    else
                        show = true;
                }
            }
            if (show)
                popup.open();
            else
                popup.close();

            lastCandidate = exportName.text;
        }
    }

    property var lastCandidate: ""

    function getFileSuffix(fileName) {

        var n = fileName.lastIndexOf(".");
        var suffix = fileName.substring(n + 1);

        return suffix
    }

} // MuseScore