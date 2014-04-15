#include "shoedatabase.h"
#include <QDebug>
#include <QQmlContext>
#include <QtSql/QSqlDatabase>
#include <QtSql/QSqlQuery>
#include <QtSql/QSqlError>

ShoeDatabase::ShoeDatabase()
{
    db = QSqlDatabase::addDatabase("QMYSQL");
    db.setHostName("localhost");
    db.setPort(3306);
    db.setDatabaseName("my_bellescarpecod");
    db.setUserName("root");
    db.setPassword("");
}

bool ShoeDatabase::open()
{
    db.open();

    if(!db.isOpen()){
        qDebug() << db.lastError();
        return false;
    }

    return true;
}

void ShoeDatabase::getAllShoes()
{
    QSqlQuery query;
    query.exec("SELECT * FROM scarpa");
    qDebug() << query.lastError();

    if(query.lastError().number() == -1){
        while (query.next()) {
             int name = query.value(0).toInt();
             QString salary = query.value(1).toString();
             qDebug() << name << salary;
         }
    }
    else qDebug() << query.lastError();
}

void ShoeDatabase::close()
{
    db.close();
}
