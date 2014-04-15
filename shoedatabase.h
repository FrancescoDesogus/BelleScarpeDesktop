#ifndef SHOEDATABASE_H
#define SHOEDATABASE_H

#include <QtSql/QSqlDatabase>

class ShoeDatabase
{
public:
    ShoeDatabase();
    bool open();
    void close();
    void getAllShoes();

private:
    QSqlDatabase db;

};

#endif // SHOEDATABASE_H
