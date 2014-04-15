# Hello, I'm a comment

TEMPLATE = app
TARGET = BelleScarpeDesktop

QT = core gui serialport quick declarative qml

greaterThan(QT_MAJOR_VERSION, 4): QT += widgets

#SOURCES += \
#    main.cpp \
#    firstwindow.cpp \
#    mythread.cpp

#RESOURCES += \
#    resources.qrc

#OTHER_FILES += \
#    Cell.qml \
#    ViewManager.qml \
#    main.qml \
#    ViewManagerLogic.js \
#    SecondScreen.qml \
#    FirstScreen.qml

#HEADERS += \
#    firstwindow.h \
#    mythread.h

SOURCES += \
    main.cpp \
    serialreaderthread.cpp \
    windowmanager.cpp

HEADERS += \
    serialreaderthread.h \
    windowmanager.h

RESOURCES += \
    resources.qrc


OTHER_FILES += \
    main.qml \
    ViewManager.qml \
    ViewManagerLogic.js \
    ShoeView.qml \
