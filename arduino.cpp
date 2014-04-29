#include "arduino.h"
#include <QSerialPort>
#include <QSerialPortInfo>
#include <QDebug>


//Costanti che definiscono la porta e i setaggi da usare
const QString Arduino::PORT_NAME = "COM6";
const int Arduino::BAUD_RATE = (int) QSerialPort::Baud9600;
const int Arduino::DATA_BITS = (int) QSerialPort::Data8;
const int Arduino::PARITY = (int) QSerialPort::NoParity;
const int Arduino::STOP_BITS = (int) QSerialPort::OneStop;

//Costanti che indicano quali sono i prefissi da usare per accendere luci singolarmente, in movimento, e in movimento stile stop motion
const QString Arduino::SINGLE_LIGHTS_PREFIX = "#";
const QString Arduino::MOVING_MESSAGE_PREFIX = "\\";
const QString Arduino::MOVING_MESSAGE_STOP_MOTION_PREFIX = "|";

//Costante che contiene il messaggio da inviare alla porta seriale per spegnere tutte le luci
const QString Arduino::TURN_OFF_LIGHTS_CODE = Arduino::SINGLE_LIGHTS_PREFIX + "o";



/**
 * @brief Arduino::Arduino costruttore della classe; setta la porta seriale da usare e scrive nel prompt dei comandi le impostazioni da usare
 *        usare per la porta; senza queste informazioni non funzionerebbe corettamente
 */
Arduino::Arduino()
{
    serialPort.setPort(QSerialPortInfo(Arduino::PORT_NAME));

    system("mode com6: BAUD=9600 PARITY=n DATA=8 STOP=1 to=off dtr=off rts=off");
}


/**
 * @brief turnOnLights manda il messaggio specificato ad arduino; da usare per acccendere le luci. Mandare ad esempio un messaggio come "ABC" farà
 *        accendere le luci relative ad ABC.
 *        Uso del metodo: prima di chiamare il metodo bisogna formare una stringa contenente tutte le luci da accendere e poi mandare il messaggio.
 *
 *        Ad esempio:
 *              QString lights = shoe1.getLightCoordinate() + shoe2.getLightCoordinate() + shoe3.getLightCoordinate();
 *              arduinoObject.turnOnLights(lights);
 *
 * @param data il messaggio da inviare
 *
 * @return true se il messaggio è stato mandato corretamente, false altrimenti
 */
bool Arduino::turnOnLights(QString data)
{
    bool result = false;

    //Provo ad aprire la porta in modalità scrittura
    if(serialPort.open(QIODevice::WriteOnly))
    {
        //Inserisco i setaggi da usare per la porta
        this->setPortSettings();

        //Aggiungo all'inizio del messagggio da inviare il prefisso da usare per far si che si accendano le luci singolarmente
        data.prepend(Arduino::SINGLE_LIGHTS_PREFIX);

        int numBytesWritten = 0;
        char *command;       

        //Prima di inviare il messaggio, dato che la porta seriale si aspetta una stringa formata da char*, trasformo
        //il messaggio da QString a char*
        QByteArray byteArray;
        byteArray = data.toLatin1();
        command = byteArray.data();

        //Scrivo nella porta il comando, passando la sua lunghezza per indicare il numero di byte che deve scrivere
        numBytesWritten  = serialPort.write(command, strlen(command));

        //Se il numero di byte scrito è maggiore di 0, savo nel booleano che  andato tutto bene
        if(numBytesWritten > 0)
            result = true;

        //A prescindere dall'esito dell'invio, chiudo la porta seriale
        serialPort.close();
    }

    return result;
}

/**
 * @brief Arduino::turnOffAllLights spegne tutte le luci
 *
 * @return true se sono state spente correttamente, false altrimenti
 */
bool Arduino::turnOffAllLights()
{
    bool result = false;

    //Provo ad aprire la porta in modalità scrittura
    if(serialPort.open(QIODevice::WriteOnly))
    {
        //Inserisco i setaggi da usare per la porta
        this->setPortSettings();


        int numBytesWritten = 0;
        char *command;


        //Trasformo il codice per spegnere le luci in un array di char
        QByteArray byteArray;
        byteArray = Arduino::TURN_OFF_LIGHTS_CODE.toLatin1();
        command = byteArray.data();

        //Invio il comando
        numBytesWritten  = serialPort.write(command, strlen(command));

        //Se il numero di byte scritto è > 0 vuol dire che è andato tutto bene, quindi procedo con l'invio del messaggio vero e proprio
        if(numBytesWritten > 0)
            result = true;

        //A prescindere dall'esito dell'invio, chiudo la porta seriale
        serialPort.close();
    }

    return result;
}

/**
 * @brief Arduino::setPortSettings è un metodo di convenienza per settare i setaggi della porta una volta aperta
 */
void Arduino::setPortSettings()
{
    serialPort.setBaudRate(Arduino::BAUD_RATE);
    serialPort.setDataBits((QSerialPort::DataBits) Arduino::DATA_BITS);
    serialPort.setParity((QSerialPort::Parity) Arduino::PARITY);
    serialPort.setStopBits((QSerialPort::StopBits) Arduino::STOP_BITS);
}
