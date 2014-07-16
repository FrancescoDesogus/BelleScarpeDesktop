#include "serialreaderthread.h"

#include <QDebug>
#include <QCoreApplication>
#include <QSerialPort>
#include <QSerialPortInfo>
#include <stdlib.h>

//Costanti che definiscono la porta e i setaggi da usare
const QString SerialReaderThread::PORT_NAME = "COM7";
const int SerialReaderThread::BAUD_RATE = (int) QSerialPort::Baud9600;
const int SerialReaderThread::DATA_BITS = (int) QSerialPort::Data8;
const int SerialReaderThread::PARITY = (int) QSerialPort::NoParity;
const int SerialReaderThread::STOP_BITS = (int) QSerialPort::OneStop;


//Costanti inerenti al messaggio ricevuto dall'RFID reader. Rispettivamente: la lunghezza totale dei pacchetti mandati dal reader
//in byte, la lunghezza del tag RFID in byte all'interno del pacchetto escluso il checksum, la lughezza del checksum in byte
const int SerialReaderThread::PACKET_SIZE = 16;
const int SerialReaderThread::CODE_SIZE = 10;
const int SerialReaderThread::CHECKSUM_SIZE = 2;

//Costante che indica l'intervallo di tempo in millisecondi entro cui è possibile ricevere ulteriori pacchetti
//dopo averne ricevuto uno
const int SerialReaderThread::INTERVAL_BETWEEN_PACKETS = 1700;


/**
 * @brief SerialReaderThread::SerialReaderThread è il costruttore della classe. Si occupa di creare il thread per l'RFID e di
 *        spostare l'istanza della classe nel nuovo thread seguendo l'idea del worker-object
 *
 * @param parent il genitore della classe; è importante che sia la classe che crea una istanza di SerialReaderThread in quanto
 *        serve che il thread sia figlio di quella classe
 */
SerialReaderThread::SerialReaderThread(QObject *parent) :
    thread(new QThread(parent))
{
    //Sposto l'istanza della classe nel nuovo thread appena creato
    this->moveToThread(thread);

    //Connetto l'inizio dell'esecuzione del thread con il metodo che esegue il corpo della classe
    QObject::connect(thread, SIGNAL(started()), this, SLOT(run()));

    thread->start();


    //Avvio nel prompt dei comandi di windows questo comando. Senza ci sarebbe un warning riguardo il flow control, però
    //comunque funzionerebbe; in ogni caso, meglio metterlo
    system("mode com7: BAUD=9600 PARITY=n DATA=8 STOP=1 to=off dtr=off rts=off");
}

/**
 * @brief SerialReaderThread::~SerialReaderThread è il distruttore della classe; è chiamato quando l'istanza della classe presente
 *        in WIndowManager è eliminata, e si occupa di risolvere le cose lasciate in sospeso; in particolare chiude la porta seriale,
 *        blocca il timer di intervallo tra i pacchetti ricevuti e chiude il thread.
 *        NOTA: di queste 3 cose solo la chiusura della porta seriale viene effettivamente eseguita, in quanto il timer non può
 *        essere manipolato dato che il distruttore è eseguito nel main thread (in quanto è la che si fa la delete), ed i timer
 *        in Qt non possono essere manipolati all'infuori del thread in cui sono creati; di fatto non è un problema, perchè
 *        il timer verrà comunque eliminato dalle Qt, anche se questo causa un warning nella console.
 *        Per quanto riguarda la chiusura del thread, dato che il metodo run() di SerialReaderThread contiene un while infinito
 *        per la ricezione dei messaggi, non si schioda mai da questo e quindi non è possibile neanche chiudere con una quit() il
 *        thread fintanto che il while viene eseguito. Di fatto anche questo non è un problema, in quanto il thread verrà comunque
 *        disrutto dalle Qt; genera però un warning nella console
 */
SerialReaderThread::~SerialReaderThread()
{
    //Chiudo la porta seriale, che potrebbe essere ancora aperta
    serialPort.close();

    //Blocco il timer. Per quanto scritto nel brief del distruttore, questa chiamata non ha effetto; è lasciata
    //più come remainder del perchè
    timerInterval->stop();

    //Termino il thread. Per quanto scritto nel brief del distruttore, questa chiamata non ha effetto; è lasciata
    //più come remainder del perchè
    thread->quit();
}


/**
 * @brief run() è il metodo che viene eseguito quando parte il thread, e contiene un loop infinito che controlla e legge
 *        dalla porta seriale dell'RFID reader
 */
void SerialReaderThread::run()
{
    //Abilito la ricezione dei pacchetti
    canReceivePackets = true;

    /* Creo l'istanza del timer per per ripristinare l'arrivo dei pacchetti dopo la ricezione di uno valido; serve per evitare
     * un flooding di pacchetti, con conseguente creazione di molte schermate inutili. Questo timer è istanziato qua e non
     * nel costruttore in modo tale che venga creato nel nuovo thread e non nel main thread, altrimenti il timer non funzionerebbe.
     * Di per se, il timer è definito come singleshot in modo che una volta eseguito non si ripeta a meno che non glielo
     * si dica esplicitamente */
    timerInterval = new QTimer(this);
    timerInterval->setInterval(SerialReaderThread::INTERVAL_BETWEEN_PACKETS);
    timerInterval->setSingleShot(true);

    //Connetto il signal che indica il termine del timer con lo slot che si occupa di ripristinare la ricezione dei pacchetti
    QObject::connect(timerInterval, SIGNAL(timeout()), this, SLOT(allowIncomingPackets()));


    //Setto il nome della porta a cui è connesso l'RFID reader
    serialPort.setPort(QSerialPortInfo(SerialReaderThread::PORT_NAME));

    //Apro la porta in modalità lettura
    if(serialPort.open(QIODevice::ReadOnly))
    {
        //Inserisco i setaggi da usare per la porta
        serialPort.setBaudRate(SerialReaderThread::BAUD_RATE);
        serialPort.setDataBits((QSerialPort::DataBits) SerialReaderThread::DATA_BITS);
        serialPort.setParity((QSerialPort::Parity) SerialReaderThread::PARITY);
        serialPort.setStopBits((QSerialPort::StopBits) SerialReaderThread::STOP_BITS);

        /* Buffer in cui saranno inseriti i dati di volta in volta. In pratica per come funziona l'RFID reader, quando viene
         * letto un tag il pacchetto che si manda può essere splittato in più parti (e da quanto abbiamo visto è sempre così);
         * ad esempio, se la grandezza del pacchetto è 16 byte (ed è così) alla lettura del tag il pacchetto può essere diviso in
         * 2 pachetti inviati uno dopo l'altro, uno della grandezza di 6 byte e l'altro 10 byte. Uniti, questi due pacchetti
         * formano il pacchetto originario. Quindi quello che bisogna fare è recuperare dal buffer della porta seriale tutti
         * i byte fino a quando non si leggono un totale di 16 byte; a quel punto so che il pacchetto è completo e posso processarlo.
         * L'array "buffer" contiene di volta in volta le parti del pacchetto, e ha grandezza pari alla grandezza effettiva del
         * pacchetto nel caso in cui il pacchetto per qualche motivo non viene splittato */
        char buffer[SerialReaderThread::PACKET_SIZE];

        //Questo array contiene il pacchetto vero e proprio; ogni volta che viene letto qualcosa nel buffer si aggiunge quel
        //qualcosa a questo array, fino ad arrivare ad occupare 16 byte
        char packet[SerialReaderThread::PACKET_SIZE];

        //Questa variabile è il contatore dell'array packet. Tiene conto del punto a cui si è arrivati nel riempimento
        qint64 byteIndex = 0;


        /* Questo while si occupa di leggere periodicamente dalla porta, all'infinito. Il metodo waitForReadyRead() blocca tutto
         * fino a quando non ci sono altri dati da leggere, e nel caso ritorna true. Ritorna false se c'è stato un errore o se è
         * scattato il timeout, che in questo caso è settato su -1 per non avere proprio alcun timeout */
        while(serialPort.waitForReadyRead(-1))
        {
            /* Leggo al massimo sizeof(buffer) byte e metto il contenuto letto in buffer. Per quanto detto nei commenti più sopra,
             * i pacchetti inviati dall'RFID sono divisi in pacchetti più piccoli; di conseguenza, vengono letti
             * al più sizeof(buffer) byte (16 di default), ma generalmente sono di meno. Il numero effettivo di byte letti viene
             * restituito dal metodo */
            qint64 numBytesRead  = serialPort.read(buffer, sizeof(buffer));


            /* Una volta svuotato il contenuto della porta seriale e messo tutto nell'array buffer, devo processare gli eventi
             * Qt che ci potrebbero essere. In pratica, per far si che il timer di intervallo tra due pacchetti funzioni (cioè
             * per far si che al suo termine lo slot associato venga effettivamente eseguito), bisogna chiamare questo metodo
             * statico che forza il thread in cui viene eseguito a processare gli eventi arretrati (cioè eventuali slot); c'è
             * bisogno di farlo esplicitamente in quanto essendo presente un while infinito e bloccante, eventuali slot non
             * vengono MAI eseguiti (verrebbero eseguiti solo al termine del while, che però è infinito). Quindi, bisogna
             * forzare il thread a processarli ogni qualvolta riceve qualcosa nella porta, in modo tale che se in precedenza
             * il timer fosse scattato, il suo slot verrebbe eseguito adesso (e quindi il pacchetto appena arrivato verrebbe
             * processato).
             * E' inoltre importante fare questo DOPO aver svuotato il buffer della porta seriale, in quanto questo si riempie
             * ogni volta che viene letto un tag, anche se il timer non vien scattato; ad esempio lo scenario è questo: avvicino
             * un tag al reader, viene letto correttamente e scatta il timer di intervallo; se prima che il timer scada avvicino un
             * ulteriore tag, il pacchetto viene inviato dal reader alla porta seriale. Dato che il timer non è ancora scattato,
             * di fatto il pacchetto non viene processato. Supponiamo che venga scartato subito senza prima svuotare il buffer;
             * allora se dovessi passare un ulteriore tag, questa volta dopo la fine del timer, verrebbe mandato un ulteriore
             * pacchetto nella porta seriale. Adesso però nella porta seriale ce ne sono due, quello di prima (che deve
             * essere scartato) e quello nuovo. Però non so che devo scartar il primo, che quindi viene processato senza motivo.
             * In sostanza, prosciugando il buffer ogni volta che si riceve un pacchetto, anche se non deve essere processato,
             * permette di mantenere sempre il buffer "pulito" */
            QCoreApplication::processEvents();

            //Dopo che ho processato gli eventi, posso controllare il booleano che indica se è possibile ricevere i pacchetti;
            //se non è possibile, salto un giro del while
            if(!canReceivePackets)
                continue;


            // Dato che i paccheti inviati dal reader sono spezzettati, di volta in volta riempio l'array packet con i byte letti
            // sul momento, tenendo conto del punto a cui si era arrivati in precedenza nel riempimento (definito da byteIndex)
            for(int i = 0; i < numBytesRead; i++)
                packet[byteIndex + i] = buffer[i];

            //Incremento l'indice dei byte ricevuti in base al numero di byte letti sul momento
            byteIndex += numBytesRead;


            /* Se il numero di byte letti è maggiore di 0, vuol dire che è andato tutto bene e quindi faccio scattare il segnale
             * che avvisa il main thread dell'arrivo di un nuovo messaggio, e glielo passo.
            /* Se l'indice dei byte inseriti nell'array packet raggiunge 15, vuol dire che il pacchetto è stato assemblato nella sua
             * interezza e quindi si può processare (si controlla se arriva a 15 perchè l'indice parte da 0 e deve leggere 16 byte).
             * Se quindi scatta questa if, vorrà dire che il pacchetto è ora completo ed è contenuto nell'array packet.
             * Le info su come codificare il messaggio ricevuto le ho prese dal datasheet ufficiale dell'RFID
             * reader (http://id-innovations.com/httpdocs/ID-3LA,ID-12LA,ID-20LA.pdf)
             * e da questa pagina: http://www.settorezero.com/wordpress/impariamo-ad-utilizzare-i-tags-rfid/ */
            if(byteIndex >= SerialReaderThread::PACKET_SIZE - 1)
            {
                //Dato che se si entra in questa if il pacchetto è stato ricevuto nella sua interezza, riporto a zero
                //l'indice del counter dell'array packet in modo che sia pronto a ricevere altri pacchetti in futuro
                byteIndex = 0;

                //Array che conterrà il codice effettivo del tag, estrapolato dal pacchetto
                char code[SerialReaderThread::CODE_SIZE];

                //Recupero dal packet il codice. Salto il primo carattere contenuto nel buffer perchè è il carattere di
                //start of text, che non serve
                for(int i = 0; i < SerialReaderThread::CODE_SIZE; i++)
                    code[i] = packet[i+1];


                //Preso il codice, controllo se combacia col checksum contenuto sempre nel buffer; nel caso, emitto il signal per
                //avvisare il main thread del nuovo codice ricevuto
                if(checkChecksum(packet, code))
                {
                    QString codeString;

                    //Trasformo in QString il messaggio
                    for(int i = 0; i < SerialReaderThread::CODE_SIZE; i++)
                        codeString.append(code[i]);


                    //Visto che è tutto ok, posso emettere il signal che avvisa WindowManager che deve ricercare
                    //la scarpa con quel tag
                    emit codeArrived(codeString);

                    /* Disabilito la ricezione di ulteriori pacchetti e attivo il timer che la ripristina dopo un tot di tempo;
                     * in questo modo si evita un flood di pacchetti che vorrebbe dire un casino di richere nel db e di caricamenti
                     * di nuove schermate una dopo l'altra */
                    canReceivePackets = false;
                    timerInterval->start();
                }
                else
                    qDebug() << "SerialReaderThread:: Errore: il checksum del codice ricevuto non combacia con quello calcolato";
            }
        }

        //Se si esce dal loop vuol dire che c'è stato un problema, quindi stampo un messaggio e chiudo la porta
        qDebug() << "Serial thread exited the main loop... something is wrong... very wrong...";

        serialPort.close();
    }
    else
        qDebug() << "SerialReaderThread:: Errore: non è stato possibile aprire la porta dell'RFID reader";
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

    //Adesso che ho i valori decimali, posso calcolare il checksum, che dovrò confrontare con il checksum effettivamente ricevuto
    //dall'RFID reader. Inizializzo questa variabile a 0; conterrà il valore finale del checksum
    int checksumCalculated = 0;

    /* Per calcolare il checksum bisogna eseguire lo XOR logico su tutti i valori decimali; il risultato è il checksum.
     * Se il codice fosse ad esempio "01 06 93 60 16", dopo la conversione in decimale avrei "1, 6, 147, 96, 22". Con questo, per
     * calcolare il checksum dovrei fare "1 XOR 6 XOR 147 XOR 96 XOR 22" il cui risultato è 226. In C++ lo XOR si fa con il carattere ^.
     * Con una for quindi scorro i valori decimali ed eseguo lo XOR su ogni carattere con il risultato precedentemente ottenuto */
    for(int i = 0; i < codeSizeInDecimal; i++)
        checksumCalculated = checksumCalculated ^ codeDecimal[i];


    /* Adesso devo recuperare il checksum contenuto nel buffer ricevuto dall'RFID reader. Il checksum sarà formato da 2 caratteri,
     * che sono anch'essi da prendere come un numero esadecimale, che dovrò quindi convertire nel corrispettivo decimal.
     * Preparo quindi l'array che conterrà la stringa esadecimale, aggiungendo 1 alla grandezza perchè dovrò mettere 0 come
     * ultimissimo carattere; se non lo faccio, in seguito la conversione da esadecimale a decimale non funzionerebbe, e non ho
     * capito bene perchè nel caso della conversione dei valori esadecimali del codice questo non avevo avuto bisogno di
     * farlo eppure funzionava... */
    char checksumString[SerialReaderThread::CHECKSUM_SIZE + 1];

    //Il checksum all'interno del buffer è subito dopo il codice, quindi calcolo l'offset
    int checksumStartingPosition = SerialReaderThread::CODE_SIZE + 1;

    //Inserisco nella stringa del checksum tutti i valori partendo dall'offset
    for(int i = 0; i < SerialReaderThread::CHECKSUM_SIZE; i++)
        checksumString[i] = buffer[checksumStartingPosition + i];

    //Come ultimissimo carattere della stringa inserisco 0, altrimenti la conversione da esadecimale a decimale non funzionerebbe
    checksumString[SerialReaderThread::CHECKSUM_SIZE] = 0;

    //Converto quindi il checksum da esadecimale al suo corrispettivo decimale
    int checksumGiven = (int) strtol(checksumString, NULL, 16);

    //Adesso che ho sia il checksum calcolato che quello passato dall'RFID reader, controllo se sono uguali e restituisco il risultato
    return checksumCalculated == checksumGiven;
}

/**
 * @brief SerialReaderThread::allowIncomingPackets è uno slot chiamato quando il timer di intervallo tra due pacchetti scatta;
 *        si occupa semplicemente di riportare su true il booleano che indica se è possibile ricevere pacchetti
 */
void SerialReaderThread::allowIncomingPackets()
{
    canReceivePackets = true;
}


