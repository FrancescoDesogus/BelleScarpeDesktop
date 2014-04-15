
#include <QApplication>
#include <QDebug>

#include <serialreaderthread.h>
#include <windowmanager.h>


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

