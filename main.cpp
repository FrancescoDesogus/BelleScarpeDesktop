
#include <QApplication>
#include <QDebug>
#include <QString>
#include <QDeclarativePropertyMap>
#include <QVariant>
#include <QDir>
#include <QQmlContext>
#include "dataobject.h"

#include <serialreaderthread.h>
#include <windowmanager.h>
#include <shoedatabase.h>

//Ciao sono un commento, tipo
int main(int argc, char *argv[])
{
    QApplication app(argc, argv);


    WindowManager *view = new WindowManager();

    // Retrieve the path to the app's working directory
    QString imagesPath = QDir::currentPath() + "/debug/shoes_media/1/skyscape2.jpg";

    QList<QObject*> dataList;
    dataList.append(new DataObject(imagesPath));
    dataList.append(new DataObject(imagesPath));
    dataList.append(new DataObject(imagesPath));
    dataList.append(new DataObject(imagesPath));
    dataList.append(new DataObject(imagesPath));
    dataList.append(new DataObject(imagesPath));
    dataList.append(new DataObject(imagesPath));
    dataList.append(new DataObject(imagesPath));
    dataList.append(new DataObject(imagesPath));
    dataList.append(new DataObject(imagesPath));
    dataList.append(new DataObject(imagesPath));
    dataList.append(new DataObject(imagesPath));
    dataList.append(new DataObject(imagesPath));
    dataList.append(new DataObject(imagesPath));
    dataList.append(new DataObject(imagesPath));
    dataList.append(new DataObject(imagesPath));
    dataList.append(new DataObject(imagesPath));
    dataList.append(new DataObject(imagesPath));
    dataList.append(new DataObject(imagesPath));
    dataList.append(new DataObject(imagesPath));
    dataList.append(new DataObject(imagesPath));
    dataList.append(new DataObject(imagesPath));
    dataList.append(new DataObject(imagesPath));
    dataList.append(new DataObject(imagesPath));
    dataList.append(new DataObject(imagesPath));
    dataList.append(new DataObject(imagesPath));

//    qDebug() << imagesPath;
    view->rootContext()->setContextProperty("imagesPath", imagesPath);
    view->rootContext()->setContextProperty("myModel", QVariant::fromValue(dataList));
    view->setupScreen();

//    SerialReaderThread thread;

//    QObject::connect(&thread, SIGNAL(codeArrived(char*)), view, SLOT(getCode(char*)));

//    thread.start();

    return app.exec();
}

