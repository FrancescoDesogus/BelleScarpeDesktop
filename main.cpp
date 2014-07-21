
#include <QApplication>
#include <QDebug>
#include <QString>
#include <QDeclarativePropertyMap>
#include <QVariant>
#include <QDir>
#include <QQmlContext>

#include <serialreaderthread.h>
#include <windowmanager.h>
#include <shoedatabase.h>


int main(int argc, char *argv[])
{
    QApplication app(argc, argv);


    WindowManager view;

    view.setupScreen();


//    app.setOverrideCursor(QCursor( Qt::BlankCursor ));



    return app.exec();
}

