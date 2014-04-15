
#include <QApplication>
#include <QDebug>

#include <serialreaderthread.h>
#include <windowmanager.h>

//Ciao sono un commento, tipo
int main(int argc, char *argv[])
{
    QApplication app(argc, argv);


    WindowManager *view = new WindowManager();

    view->setupScreen();


    SerialReaderThread thread;

    QObject::connect(&thread, SIGNAL(codeArrived(char*)), view, SLOT(getCode(char*)));

    thread.start();

    return app.exec();
}

