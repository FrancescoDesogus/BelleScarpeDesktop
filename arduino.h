#ifndef ARDUINO_H
#define ARDUINO_H

#include <QSerialPort>

/**
 * @brief The Arduino class si occupa di gestire l'arduino e permette di mandargli messaggi
 */
class Arduino
{
public:
    Arduino();

    bool turnOnLights(QString data);
    bool turnOffAllLights();

private:
    static const QString PORT_NAME;
    static const int BAUD_RATE;
    static const int DATA_BITS;
    static const int PARITY;
    static const int STOP_BITS;
    static const QString SINGLE_LIGHTS_PREFIX;
    static const QString MOVING_MESSAGE_PREFIX;
    static const QString MOVING_MESSAGE_STOP_MOTION_PREFIX;
    static const QString TURN_OFF_LIGHTS_CODE;

    QSerialPort serialPort;

    void setPortSettings();
};

#endif // ARDUINO_H
