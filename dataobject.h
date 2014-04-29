#ifndef DATAOBJECT_H
#define DATAOBJECT_H

#include <QObject>

class DataObject : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QString source READ source WRITE setSource NOTIFY sourceChanged)

public:
    DataObject(QObject *parent=0);
    DataObject(const QString &source, QObject *parent=0);

    QString source() const;
    void setSource(const QString &source);

signals:
    void sourceChanged();

private:
    QString m_source;
};

#endif // DATAOBJECT_H
