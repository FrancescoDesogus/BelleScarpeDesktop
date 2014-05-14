#ifndef SHOEDATABASE_H
#define SHOEDATABASE_H

#include <QtSql/QSqlDatabase>
#include <QString>
#include <shoe.h>
#include <vector>

class ShoeDatabase
{
public:
    ShoeDatabase();

    bool open();
    void close();
    void getAllShoes();
    Shoe* getShoeFromId(int shoeId);
    Shoe* getShoeFromId(QString RFIDcode);
    std::vector<Shoe*> getSimiliarShoes(int shoeId, QString sex, QString category);

private:
    QSqlDatabase db;

    static const QString HOST_NAME;
    static const QString DB_NAME;
    static const int DB_PORT;
    static const QString DB_USERNAME;
    static const QString DB_PASSWORD;

    static const QString SHOE_TABLE_NAME;
    static const QString SIZE_TABLE_NAME;



    static const QString SHOE_ID_COLUMN;
    static const QString SHOE_BRAND_COLUMN;
    static const QString SHOE_MODEL_COLUMN;
    static const QString SHOE_COLOR_COLUMN;
    static const QString SHOE_SEX_COLUMN;
    static const QString SHOE_CATEGORY_COLUMN;
    static const QString SHOE_PRICE_COLUMN;
    static const QString SHOE_MEDIA_COLUMN;
    static const QString SHOE_RFID_CODE_COLUMN;

    static const int SHOE_ID_COLUMN_POSITION;
    static const int SHOE_BRAND_COLUMN_POSITION;
    static const int SHOE_MODEL_COLUMN_POSITION;
    static const int SHOE_COLOR_COLUMN_POSITION;
    static const int SHOE_SEX_COLUMN_POSITION;
    static const int SHOE_CATEGORY_COLUMN_POSITION;
    static const int SHOE_PRICE_COLUMN_POSITION;
    static const int SHOE_MEDIA_COLUMN_POSITION;
    static const int SHOE_RFID_CODE_COLUMN_POSITION;




    static const QString SIZE_ID_COLUMN;
    static const QString SIZE_SIZE_COLUMN;
    static const QString SIZE_QUANTITY_COLUMN;

    static const int SIZE_ID_COLUMN_POSITION;
    static const int SIZE_SIZE_COLUMN_POSITION;
    static const int SIZE_QUANTITY_COLUMN_POSITION;


    Shoe* getShoe(QString query);
};

#endif // SHOEDATABASE_H
