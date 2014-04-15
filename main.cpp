
#include <QApplication>
#include <QDebug>

#include <serialreaderthread.h>
#include <windowmanager.h>
#include <shoedatabase.h>

//Ciao sono un commento, tipo
int main(int argc, char *argv[])
{
    QApplication app(argc, argv);

    ShoeDatabase db;
    db.open();
    db.getAllShoes();
    db.close();

    WindowManager *view = new WindowManager();

    view->setupScreen();


    SerialReaderThread thread;

    QObject::connect(&thread, SIGNAL(codeArrived(char*)), view, SLOT(getCode(char*)));

    thread.start();

    return app.exec();
}

