# Questo file è una sorta di manifest del progetto

TEMPLATE = app # Il tipo di applicazione (potrebbe essere "library" ad esempio)
TARGET = BelleScarpeDesktop # Il nome che avrà l'eseguibile

QT = core gui serialport quick declarative qml sql # I moduli QT da usare per l'applicazione

QTPLUGIN += QSQLMYSQL # Plugin dedicato a SQL

greaterThan(QT_MAJOR_VERSION, 4): QT += widgets # Riga messa per supportare altre versioni di QT


# Cartelle dentro la cartella del progetto in cui cercare i file (attualmente non in uso
VPATH += sources headers qml


# Qua sotto c'è l'elenco dei file usati nel progetto. Se non sono riportati qua, non vengono visualizzati nell'albero del progetto
# a sinistra in QT Creator, però comunque vengono usati dall'applicazione
SOURCES += \
    main.cpp \
    serialreaderthread.cpp \
    windowmanager.cpp \
    shoe.cpp \
    shoedatabase.cpp \
    arduino.cpp \
    dataobject.cpp

HEADERS += \
    serialreaderthread.h \
    windowmanager.h \
    shoe.h \
    shoedatabase.h \
    arduino.h \
    dataobject.h

# This variable contains the list of all directories to look
# in to resolve dependencies. This will be used when crawling
# through included files.
DEPENDPATH += HEADERS

RESOURCES += \
    resources.qrc


OTHER_FILES += \
    main.qml \
    ViewManager.qml \
    ViewManagerLogic.js \
    ShoeView.qml \
    ScrollBar.qml \
    ShoeDetail.qml \
    ShoeImagesList.qml \
    SizeRectangle.qml \
    DetailRectangle.qml \
    ScreensaverView.qml \
    youtubePlayer.html \
    SimiliarShoesList.qml \
    FlipableSurface.qml \
    SimilarShoesDelegate.qml \
    ShoeFilter.qml \
    FilterList.qml \
    FilterGrid.qml
