#include "serialreaderthread.h"

#include <QDebug>
#include <QTimer>

SerialReaderThread::SerialReaderThread(QObject *parent) :
    QThread(parent)
{

}


/* run() è il metodo che viene eseguito quando parte il thread. Corrisponde al main() del thread principale */
void SerialReaderThread::run()
{
    qDebug() << "Hello, I'm a thread and I was run";


    QTimer::singleShot(2000, this, SLOT(sendCode()));

    //L'exec() avvia il main loop del thread. Senza questo, il thread morirebbe conclusa l'esecuzione di run(), anche se c'è il timer attivo
    exec();
}


/* Slot chiamato alla scadenza del timer, che si occupa di emettere il signal per avvertire il thread principale che è arivato un messaggio */
void SerialReaderThread::sendCode()
{
    emit codeArrived("asdasd");
}
