#include <shoedatabase.h>
#include <shoe.h>
#include <QString>
#include <QDebug>
#include <QQmlContext>
#include <QtSql/QSqlDatabase>
#include <QtSql/QSqlQuery>
#include <QtSql/QSqlError>
#include <vector>


//Namespace contenente classi come "vector" e "map". Usare il namespace fa si che non si debba scrivere ad esempio std::vector quando lo si usa
using namespace std;


//Costanti per accedere al database
const QString ShoeDatabase::HOST_NAME = "localhost";
const int ShoeDatabase::DB_PORT = 3306;
const QString ShoeDatabase::DB_NAME = "my_bellescarpecod";
const QString ShoeDatabase::DB_USERNAME = "root";
const QString ShoeDatabase::DB_PASSWORD = "";

//Nomi delle tabelle
const QString ShoeDatabase::SHOE_TABLE_NAME = "scarpa";
const QString ShoeDatabase::SIZE_TABLE_NAME = "taglia";


//Nomi delle colonne della tabella delle scarpe
const QString ShoeDatabase::SHOE_ID_COLUMN = "id_scarpa";
const QString ShoeDatabase::SHOE_BRAND_COLUMN = "marca";
const QString ShoeDatabase::SHOE_MODEL_COLUMN = "modello";
const QString ShoeDatabase::SHOE_COLOR_COLUMN = "colore";
const QString ShoeDatabase::SHOE_SEX_COLUMN = "sesso";
const QString ShoeDatabase::SHOE_CATEGORY_COLUMN = "categoria";
const QString ShoeDatabase::SHOE_PRICE_COLUMN = "prezzo";
const QString ShoeDatabase::SHOE_MEDIA_COLUMN = "media";


//Posizioni delle colonne della tabella delle scarpe
const int ShoeDatabase::SHOE_ID_COLUMN_POSITION = 0;
const int ShoeDatabase::SHOE_BRAND_COLUMN_POSITION = 1;
const int ShoeDatabase::SHOE_MODEL_COLUMN_POSITION = 2;
const int ShoeDatabase::SHOE_COLOR_COLUMN_POSITION = 3;
const int ShoeDatabase::SHOE_SEX_COLUMN_POSITION = 4;
const int ShoeDatabase::SHOE_CATEGORY_COLUMN_POSITION = 5;
const int ShoeDatabase::SHOE_PRICE_COLUMN_POSITION = 6;
const int ShoeDatabase::SHOE_MEDIA_COLUMN_POSITION = 7;


//Nomi delle colonne della tabella delle taglie
const QString ShoeDatabase::SIZE_ID_COLUMN = "id_scarpa";
const QString ShoeDatabase::SIZE_SIZE_COLUMN = "taglia";
const QString ShoeDatabase::SIZE_QUANTITY_COLUMN = "quantita";


//Posizioni delle colonne della tabella delle taglie
const int ShoeDatabase::SIZE_ID_COLUMN_POSITION = 0;
const int ShoeDatabase::SIZE_SIZE_COLUMN_POSITION = 1;
const int ShoeDatabase::SIZE_QUANTITY_COLUMN_POSITION = 2;


/**
 * @brief ShoeDatabase::ShoeDatabase costruttore; istanzia il database
 */
ShoeDatabase::ShoeDatabase()
{
    db = QSqlDatabase::addDatabase("QMYSQL");
    db.setHostName(ShoeDatabase::HOST_NAME);
    db.setPort(ShoeDatabase::DB_PORT);
    db.setDatabaseName(ShoeDatabase::DB_NAME);
    db.setUserName(ShoeDatabase::DB_USERNAME);
    db.setPassword(ShoeDatabase::DB_PASSWORD);
}

/**
 * @brief ShoeDatabase::open apre il db
 *
 * @return true se è stato aperto, false altrimenti
 */
bool ShoeDatabase::open()
{
    db.open();

    if(!db.isOpen())
    {
        qDebug() << db.lastError();

        return false;
    }

    return true;
}


/**
 * @brief ShoeDatabase::getShoeFromId preleva i dati della scarpa con l'id specificato
 *
 * @param shoeId l'id della scarpa da cercare
 *
 * @return un oggetto Shoe contenente i dati (è un puntatore perchè estende QObject e gli oggetti che estendono QObject non possono
 *         essere copiati, bisogna passare per forza un riferimento). Viene ritornato NULL in caso di errori o se non è stato trovato niente
 */
Shoe* ShoeDatabase::getShoeFromId(int shoeId)
{
    QSqlQuery query;

    //Eseguo la query
    query.exec("SELECT * FROM " + ShoeDatabase::SHOE_TABLE_NAME + " WHERE " + ShoeDatabase::SHOE_ID_COLUMN + " = " + QString::number(shoeId));


    //Se non ci sono stati errori e se è stata trovata esattamente una scarpa procedo
    if(query.lastError().number() == -1 && query.size() == 1)
    {
        //Prelevo il primo (e unico) risultato
        query.next();

        //Recupero tutti gli elementi; sono ordinati in base a come sono stati specificati nella SELECT. In questo caso sono nell'ordine
        //con cui sono state messe le colonne della tabella, quindi ci accedo con le costanti specificate in questa classe
        QString brand = query.value(ShoeDatabase::SHOE_BRAND_COLUMN_POSITION).toString();
        QString model = query.value(ShoeDatabase::SHOE_MODEL_COLUMN_POSITION).toString();
        QString color = query.value(ShoeDatabase::SHOE_COLOR_COLUMN_POSITION).toString();
        QString sex = query.value(ShoeDatabase::SHOE_SEX_COLUMN_POSITION).toString();
        QString category = query.value(ShoeDatabase::SHOE_CATEGORY_COLUMN_POSITION).toString();
        float price = query.value(ShoeDatabase::SHOE_PRICE_COLUMN_POSITION).toFloat();
        QString mediaPath = query.value(ShoeDatabase::SHOE_MEDIA_COLUMN_POSITION).toString();


        //Adesso devo recuperare tutte le taglie disponibili per la scarpa. Per farlo devo eseguire un'altra query
        QSqlQuery queryForSizes;

        //Eseguo la query sulla tabella delle taglie
        queryForSizes.exec("SELECT * FROM " + ShoeDatabase::SIZE_TABLE_NAME + " WHERE " + ShoeDatabase::SIZE_ID_COLUMN + " = " + QString::number(shoeId) + " ORDER BY " + ShoeDatabase::SIZE_SIZE_COLUMN);

        QVariantMap sizesAndQuantities;

        //Se non ci sono stati errori procedo
        if(queryForSizes.lastError().number() == -1)
        {
            //Scorro tutti i risultati, fino a quando non ce ne sono più
            while(queryForSizes.next())
            {
                float size = queryForSizes.value(ShoeDatabase::SIZE_SIZE_COLUMN_POSITION).toFloat();
                int quantity = queryForSizes.value(ShoeDatabase::SIZE_QUANTITY_COLUMN_POSITION).toInt();

                QString sizeString = QString::number(size);

                //Inserisco nell'array associativo la taglia ed il booleano che segnala se è disponibile o meno
                sizesAndQuantities[sizeString] = quantity > 0;
            }
        }

//        sizesAndQuantities["48"] = true;
        //Ora che ho tutti i dati, creo l'oggetto Shoe...
        Shoe* shoe = new Shoe(shoeId, brand, model, color, sex, price, category, sizesAndQuantities, mediaPath);

        //...e lo ritorno
        return shoe;
    }
    else
    {
        qDebug() << query.lastError();

        return NULL;
    }
}



/**
 * @brief ShoeDatabase::getSimiliarShoes
 *        preleva le scarpe che hanno proprietà simili alla scarpa con id specificato, in base ai parametri passati
 *
 * @param shoeId id della scarpa che si deve scartare
 * @param sex sesso della scarpa
 * @param category categoria della scarpa
 *
 * @return la lista delle scarpe simili; NOTA: le scarpe avranno l'array contenente le taglie e le quantità vuoto
 */
vector<Shoe*> ShoeDatabase::getSimiliarShoes(int shoeId, QString sex, QString category)
{
    QSqlQuery query;


    query.exec("SELECT * FROM " + ShoeDatabase::SHOE_TABLE_NAME +
               " WHERE " + ShoeDatabase::SHOE_ID_COLUMN + " != " + QString::number(shoeId) +
               " AND " + ShoeDatabase::SHOE_SEX_COLUMN + " = '" + sex + "' "
               " AND " + ShoeDatabase::SHOE_CATEGORY_COLUMN + " = '" + category + "'");

    vector<Shoe*> shoeList;

    if(query.lastError().number() == -1 && query.size() > 0)
    {
        while(query.next())
        {
            int id = query.value(ShoeDatabase::SHOE_ID_COLUMN_POSITION).toInt();
            QString brand = query.value(ShoeDatabase::SHOE_BRAND_COLUMN_POSITION).toString();
            QString model = query.value(ShoeDatabase::SHOE_MODEL_COLUMN_POSITION).toString();
            QString color = query.value(ShoeDatabase::SHOE_COLOR_COLUMN_POSITION).toString();
            QString sex = query.value(ShoeDatabase::SHOE_SEX_COLUMN_POSITION).toString();
            QString category = query.value(ShoeDatabase::SHOE_CATEGORY_COLUMN_POSITION).toString();
            float price = query.value(ShoeDatabase::SHOE_PRICE_COLUMN_POSITION).toFloat();
            QString mediaPath = query.value(ShoeDatabase::SHOE_MEDIA_COLUMN_POSITION).toString();

            //Array vuoto da inserire nel costruttore (?)
            QVariantMap sizesAndQuantities;

            shoeList.push_back(new Shoe(id, brand, model, color, sex, price, category, sizesAndQuantities, mediaPath));
        }

        return shoeList;
    }
    else
    {
        qDebug() << query.lastError();

        //Restituisco l'array vuoto
        return shoeList;
    }
}



/**
 * @brief ShoeDatabase::close chiude il db
 */
void ShoeDatabase::close()
{
    db.close();
}
