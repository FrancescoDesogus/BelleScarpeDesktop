#include "serialreaderthread.h"

#include <QDebug>
#include <QTimer>
#include <QSerialPort>
#include <QSerialPortInfo>
#include <stdlib.h>

//Costanti che definiscono la porta e i setaggi da usare
const QString SerialReaderThread::PORT_NAME = "COM5";
const int SerialReaderThread::BAUD_RATE = (int) QSerialPort::Baud9600;
const int SerialReaderThread::DATA_BITS = (int) QSerialPort::Data8;
const int SerialReaderThread::PARITY = (int) QSerialPort::NoParity;
const int SerialReaderThread::STOP_BITS = (int) QSerialPort::OneStop;

//Costanti inerenti al messaggio ricevuto dall'RFID reader
const int SerialReaderThread::CODE_SIZE = 10;
const int SerialReaderThread::CHECKSUM_SIZE = 2;


SerialReaderThread::SerialReaderThread(QObject *parent) :
    QThread(parent)
{

}


/**
 * @brief run() è il metodo che viene eseguito quando parte il thread. Corrisponde al main() del thread principale
 */
void SerialReaderThread::run()
{
    //Setto il nome della porta a cui è connesso l'RFID reader
    serialPort.setPort(QSerialPortInfo(SerialReaderThread::PORT_NAME));


    //Provo ad aprire la porta in modalità lettura
    if(serialPort.open(QIODevice::ReadOnly))
    {
        //Inserisco i setaggi da usare per la porta
        serialPort.setBaudRate(SerialReaderThread::BAUD_RATE);
        serialPort.setDataBits((QSerialPort::DataBits) SerialReaderThread::DATA_BITS);
        serialPort.setParity((QSerialPort::Parity) SerialReaderThread::PARITY);
        serialPort.setStopBits((QSerialPort::StopBits) SerialReaderThread::STOP_BITS);

        //Buffer in cui saranno inseriti i dati. La sua grandezza è tale da far si che i messaggi possano essere recuperati
        //nella loro interezza
        char buffer[100];

        /* Questo while si occupa di leggere periodicamente dalla porta, all'infinito. Il metodo waitForReadyRead() blocca tutto
         * fino a quando non ci sono altri dati da leggere, e nel caso ritorna true. Ritorna false se c'è stato un errore o se è
         * scattato il timeout, che in questo caso è settato su -1 per non avere proprio alcun timeout */
        while(!serialPort.waitForReadyRead(-1))
        {
            //Leggo al massimo sizeof(buffer) byte e metto il contenuto letto in buffer. Viene restituito il numero
            //effettivo di byte letti
            qint64 numBytesRead  = serialPort.read(buffer, sizeof(buffer));

            /* Se il numero di byte letti è maggiore di 0, vuol dire che è andato tutto bene e quindi faccio scattare il segnale
             * che avvisa il main thread dell'arrivo di un nuovo messaggio, e glielo passo. Le info su come codificare il messaggio
             * ricevuto le ho prese dal datasheet ufficiale dell'RFID reader (http://id-innovations.com/httpdocs/ID-3LA,ID-12LA,ID-20LA.pdf)
             * e da questa pagina: http://www.settorezero.com/wordpress/impariamo-ad-utilizzare-i-tags-rfid/ */
            if(numBytesRead > 0)
            {
                char code[SerialReaderThread::CODE_SIZE];

                //Recupero dal buffer il codice. Sommo 1 ad ogni 1 perchè il primo carattere contenuto nel buffer è il carattere di
                //start of text, che è da saltare
                for(int i = 0; i < SerialReaderThread::CODE_SIZE; i++)
                    code[i] = buffer[i+1];

                //Preso il codice, controllo se combacia col checksum contenuto sempre nel buffer; nel caso, emitto il signal per
                //avvisare il main thread del nuovo codice ricevuto
                if(checkChecksum(buffer, code))
                {
                    qDebug() << "SerialReaderThread:: checksum OK";
                    qDebug() << "SerialReaderThread:: code = " << code;

                    QString codeString = QString::fromUtf8(code);

                    emit codeArrived(codeString);
                }
                else
                    qDebug() << "SerialReaderThread:: Errore: la checksum del codice ricevuto non combacia con quella calcolata";
            }
        }

        //Se si esce dal loop vuol dire che c'è stato un problema, quindi stampo un messaggio e chiudo la porta
        qDebug() << "Serial thread exited the main loop... something is wrong... very wrong...";

        serialPort.close();
    }
    else
        qDebug() << "SerialReaderThread:: Errore: non è stato possibile aprire la porta dell'RFID reader";


    //L'exec() avvia il main loop del thread. Senza questo, il thread morirebbe conclusa l'esecuzione di run()
    exec();
}


/**
 * @brief SerialReaderThread::checkChecksum calcola il checksum del codice ricevuto dall'RFID reader e lo confronta con
 *        il checksum ricevuto
 *
 * @param buffer contiene l'intero messaggio ricevuto dall'RFID reader; comprende quindi il codice e il checksum
 * @param code è il codice recuperato dal buffer
 *
 * @return true se le checksum combaciano, false altrimenti
 */
bool SerialReaderThread::checkChecksum(char *buffer, char *code)
{
    /* Il codice ricevuto è in realtà formato da coppie di 2 cifre esadecimali. Devo quindi convertire il valore di ogni coppia da
     * esadecimale al corrispettivo valore decimale, in modo da poter calcolare il checksum in seguito. La grandezza dell'array che
     * conterrà i valori decimali sarà data quindi dalla grandezza del codice diviso 2, essendo i valori da prendere a coppie */
    int codeSizeInDecimal = SerialReaderThread::CODE_SIZE / 2;

    //Preparo quindi l'array che conterrà i valori decimali
    int codeDecimal[codeSizeInDecimal];

    //Inserisco i valori decimali nell'array
    for(int i = 0; i < codeSizeInDecimal; i++)
    {
        //Prendo di volta in volta la coppia di valori esadecimali da da trasformare in un valore decimale
        char hexString[2] = {code[i*2], code[i*2 + 1]};

        //Uso il metodo strtlol per convertire una stringa contenente valori esadecimali nel corrispettivo decimale,
        //e lo inserisco nell'array
        codeDecimal[i] = (int) strtol(hexString, NULL, 16);
    }

    //Adesso che ho i valori decimali, posso calcolare la checksum, che dovrò confrontare con la checksum effettivamente ricevuta
    //dall'RFID reader. Inizializzo questa variabile a 0; conterrà il valore finale della checksum
    int checksumCalcolated = 0;

    /* Per calcolare la checksum bisogna eseguire lo XOR logico su tutti i valori decimali; il risultato è la checksum.
     * Se il codice fosse ad esempio "01 06 93 60 16", dopo la conversione in decimale avrei "1, 6, 147, 96, 22". Con questo, per
     * calcolare la checksum dovrei fare "1 XOR 6 XOR 147 XOR 96 XOR 22" il cui risultato è 226. In C++ lo XOR si fa con il carattere ^.
     * Con una for quindi scorro i valori decimali ed eseguo lo XOR su ogni carattere con il risultato precedentemente ottenuto */
    for(int i = 0; i < codeSizeInDecimal; i++)
        checksumCalcolated = checksumCalcolated ^ codeDecimal[i];


    /* Adesso devo recuperare la checksum contenuta nel buffer ricevuto dall'RFID reader. La checksum sarà formata da 2 caratteri,
     * che sono anch'essi da prendere come un numero esadecimale, che dovrò quindi convertire nel corrispettivo decimal.
     * Preparo quindi l'array che conterrà la stringa esadecimale, aggiungendo 1 alla grandezza perchè dovrò mettere 0 come
     * ultimissimo carattere; se non lo faccio, in seguito la conversione da esadecimale a decimale non funzionerebbe, e non ho
     * capito bene perchè nel caso della conversione dei valori esadecimali del codice questo non avevo avuto bisogno di
     * farlo eppure funzionava... */
    char checksumString[SerialReaderThread::CHECKSUM_SIZE + 1];

    //La checksum all'interno del buffer è subito dopo il codice, quindi calcolo l'offset
    int checksumStartingPosition = SerialReaderThread::CODE_SIZE + 1;

    //Inserisco nella stringa del checksum tutti i valori partendo dall'offset
    for(int i = 0; i < SerialReaderThread::CHECKSUM_SIZE; i++)
        checksumString[i] = buffer[checksumStartingPosition + i];

    //Come ultimissimo carattere della stringa inserisco 0, altrimenti la conversione da esadecimale a decimale non funzionerebbe
    checksumString[SerialReaderThread::CHECKSUM_SIZE] = 0;

    //Converto quindi la checksum da esadecimale al suo corrispettivo decimale
    int checksumGiven = (int) strtol(checksumString, NULL, 16);


    qDebug() << "SerialReaderThread:: checksumCalculated = " << checksumCalcolated;
    qDebug() << "SerialReaderThread:: checksum given = " << checksumGiven;

    //Adesso che ho sia la checksum calcolata che quella passata dall'RFID reader, controllo se sono uguali e restituisco il risultato
    return checksumCalcolated == checksumGiven;
}

/**
 * @brief SerialReaderThread::prepareToQuit è uno slot chiamato quando l'applicazione si sta chiudendo e questo thread deve
 *        essere terminato. Si occupa di fare i preparativi per terminare il thread e poi lo chiude (motivo per cui non si usa
 *        direttamente lo slot "quit()" di QThread)
 */
void SerialReaderThread::prepareToQuit()
{
    //Chiudo la porta seriale, che potrebbe essere ancora aperta
    serialPort.close();

    quit();
}

