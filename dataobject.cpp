#include <QDebug>
 #include "dataobject.h"

 DataObject::DataObject(QObject *parent)
     : QObject(parent)
 {
 }

 DataObject::DataObject(const QString &source, QObject *parent)
     : QObject(parent), m_source(source)
 {
 }

 QString DataObject::source() const
 {
     return m_source;
 }

 void DataObject::setSource(const QString &source)
 {
     if (source != m_source) {
         m_source = source;
         emit sourceChanged();
     }
 }
