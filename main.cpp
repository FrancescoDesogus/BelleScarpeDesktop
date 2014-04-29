
#include <QApplication>
#include <QDebug>

#include <serialreaderthread.h>
#include <windowmanager.h>
#include <shoedatabase.h>
#include <arduino.h>

#include <vector>


int main(int argc, char *argv[])
{
    QApplication app(argc, argv);

    ShoeDatabase db;
    db.open();

    Shoe* shoe = db.getShoeFromId(2);

    shoe->toString();

    std::vector<Shoe*> similiarShoes = db.getSimiliarShoes(shoe->getId(), shoe->getSex(), shoe->getCategory());

    for(std::vector<int>::size_type i = 0; i != similiarShoes.size(); i++)
    {
        similiarShoes[i]->toString();
    }

    db.close();




    WindowManager *view = new WindowManager();

    view->setupScreen();



    SerialReaderThread thread;

    QObject::connect(&thread, SIGNAL(codeArrived(QString)), view, SLOT(getCode(QString)));

    thread.start();

    return app.exec();
}

