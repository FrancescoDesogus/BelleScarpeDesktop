# Hello, I'm a comment

TEMPLATE = app
TARGET = BelleScarpeDesktop

QT = core gui serialport quick declarative qml sql

QTPLUGIN += QSQLMYSQL

greaterThan(QT_MAJOR_VERSION, 4): QT += widgets

SOURCES += \
    main.cpp \
    serialreaderthread.cpp \
    windowmanager.cpp \
    shoe.cpp \
    shoedatabase.cpp

HEADERS += \
    serialreaderthread.h \
    windowmanager.h \
    shoe.h \
    shoedatabase.h

RESOURCES += \
    resources.qrc


OTHER_FILES += \
    main.qml \
    ViewManager.qml \
    ViewManagerLogic.js \
    ShoeView.qml \
