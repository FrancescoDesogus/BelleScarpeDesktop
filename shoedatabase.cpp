#include <shoedatabase.h>
#include <shoe.h>
#include <QString>
#include <QDebug>
#include <QQmlContext>
#include <QtSql/QSqlDatabase>
#include <QtSql/QSqlQuery>
#include <QtSql/QSqlError>
#include <vector>
#include <QDir>
#include <QThread>


//Namespace contenente classi come "vector". Usare il namespace fa si che non si debba scrivere ad esempio std::vector quando lo si usa
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
const QString ShoeDatabase::SHOE_RFID_CODE_COLUMN = "rfid_code";


//Posizioni delle colonne della tabella delle scarpe
const int ShoeDatabase::SHOE_ID_COLUMN_POSITION = 0;
const int ShoeDatabase::SHOE_BRAND_COLUMN_POSITION = 1;
const int ShoeDatabase::SHOE_MODEL_COLUMN_POSITION = 2;
const int ShoeDatabase::SHOE_COLOR_COLUMN_POSITION = 3;
const int ShoeDatabase::SHOE_SEX_COLUMN_POSITION = 4;
const int ShoeDatabase::SHOE_CATEGORY_COLUMN_POSITION = 5;
const int ShoeDatabase::SHOE_PRICE_COLUMN_POSITION = 6;
const int ShoeDatabase::SHOE_MEDIA_COLUMN_POSITION = 7;
const int ShoeDatabase::SHOE_RFID_CODE_COLUMN_POSITION = 8;



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
    //Setup del database
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
    //Se il db era già aperto, non faccio nulla
    if(!db.isOpen())
    {
        db.open();

        if(db.isOpenError())
        {
            qDebug() << "ShoeDatabase::open: " << db.lastError();

            return false;
        }
    }

    return true;
}

/**
 * @brief ShoeDatabase::close chiude il db
 */
void ShoeDatabase::close()
{
    //Chiudo il db solo se era effettivamente aperto
    if(db.isOpen())
        db.close();
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
    //Preparo la query vera e propria da eseguire in base all'id passato
    QString queryString = "SELECT * FROM " + ShoeDatabase::SHOE_TABLE_NAME + " " +
                          "WHERE " + ShoeDatabase::SHOE_ID_COLUMN + " = " + QString::number(shoeId);

    //Chiamo il metodo che si occuperà di eseguire la query vera e propria e di restituire la scarpa trovata
    return getShoe(queryString);
}


/**
 * @brief ShoeDatabase::getShoeFromId preleva i dati della scarpa con l'id specificato
 *
 * @param RFIDcode il codice RFID associato alla scarpa da cercare
 *
 * @return un oggetto Shoe contenente i dati (è un puntatore perchè estende QObject e gli oggetti che estendono QObject non possono
 *         essere copiati, bisogna passare per forza un riferimento). Viene ritornato NULL in caso di errori o se non è stato trovato niente
 */
Shoe* ShoeDatabase::getShoeFromId(QString RFIDcode)
{
    //Preparo la query vera e propria da eseguire in base al codice RFID passato
    QString queryString = "SELECT * FROM " + ShoeDatabase::SHOE_TABLE_NAME + " "+
                          "WHERE " + ShoeDatabase::SHOE_RFID_CODE_COLUMN + " = " + "'" + RFIDcode + "'";

    //Chiamo il metodo che si occuperà di eseguire la query vera e propria e di restituire la scarpa trovata
    return getShoe(queryString);
}


/**
 * @brief ShoeDatabase::getShoe preleva i dati della scarpa dopo aver eseguito la query passatagli come stringa
 *
 * @param queryString la query sotto forma di stringa da usare per il recupero
 *
 * @return un oggetto Shoe contenente i dati (è un puntatore perchè estende QObject e gli oggetti che estendono QObject non possono
 *         essere copiati, bisogna passare per forza un riferimento). Viene ritornato NULL in caso di errori o se non
 *         è stato trovato niente o in caso di errori
 */
Shoe* ShoeDatabase::getShoe(QString queryString)
{
    //Apro il db; se non si apre correttamente, blocco l'esecuzione
    if(!open())
        return NULL;


    QSqlQuery query;

    //Eseguo la query
    query.exec(queryString);


    //Se non ci sono stati errori e se è stata trovata esattamente una scarpa procedo
    if(query.lastError().number() == -1 && query.size() == 1)
    {
        //Prelevo il primo (e unico) risultato
        query.next();

        //Recupero tutti gli elementi; sono ordinati in base a come sono stati specificati nella SELECT. In questo caso sono nell'ordine
        //con cui sono state messe le colonne della tabella, quindi ci accedo con le costanti specificate in questa classe
        int shoeId = query.value(ShoeDatabase::SHOE_ID_COLUMN_POSITION).toInt();
        QString brand = query.value(ShoeDatabase::SHOE_BRAND_COLUMN_POSITION).toString();
        QString model = query.value(ShoeDatabase::SHOE_MODEL_COLUMN_POSITION).toString();
        QString color = query.value(ShoeDatabase::SHOE_COLOR_COLUMN_POSITION).toString();
        QString sex = query.value(ShoeDatabase::SHOE_SEX_COLUMN_POSITION).toString();
        QString category = query.value(ShoeDatabase::SHOE_CATEGORY_COLUMN_POSITION).toString();
        float price = query.value(ShoeDatabase::SHOE_PRICE_COLUMN_POSITION).toFloat();
        QString mediaPath = query.value(ShoeDatabase::SHOE_MEDIA_COLUMN_POSITION).toString();
        QString RFIDcode = query.value(ShoeDatabase::SHOE_RFID_CODE_COLUMN_POSITION).toString();



        //Adesso devo recuperare tutte le taglie disponibili per la scarpa. Per farlo devo eseguire un'altra query
        QSqlQuery queryForSizes;

        //Eseguo la query sulla tabella delle taglie
        queryForSizes.exec("SELECT * FROM " + ShoeDatabase::SIZE_TABLE_NAME + " "
                           "WHERE " + ShoeDatabase::SIZE_ID_COLUMN + " = " + QString::number(shoeId) + " "
                           "ORDER BY " + ShoeDatabase::SIZE_SIZE_COLUMN);

        QVariantMap sizesAndQuantities;

        //Se non ci sono stati errori, procedo
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


        //Ora che ho tutti i dati, creo l'oggetto Shoe...
        Shoe* shoe = new Shoe(shoeId, brand, model, color, sex, price, category, sizesAndQuantities, mediaPath, RFIDcode);


//        qDebug() << "getShoe, second thread: " << QThread::currentThreadId();

        ///////////
        QThread::currentThread()->sleep(1);


        //Chiudo il db
        close();

        //...e lo ritorno
        return shoe;
    }
    else
    {
        if(query.size() == 0)
            qDebug() << "ShoeDatabase::getShoe: nessuna scarpa è stata trovata";
        else
            qDebug() << "ShoeDatabase::getShoe: c'è stato un errore nella query: " << query.lastError();

        close();

        return NULL;
    }
}


/**
 * @brief ShoeDatabase::getSimiliarShoes preleva le scarpe che hanno proprietà simili alla scarpa con id specificato,
 *        in base alla categoria della scarpa e al sesso per cui è stata fatta
 *
 *
 * @param shoeParam riferimento alla scarpa da cui prelevare i dati per ricercare scarpe simili
 *
 * @return la lista delle scarpe simili (vuota in caso di errori o se non ce ne sono); NOTA: le scarpe avranno l'array
 *         contenente le taglie e le quantità vuoto, e anche l'array delle scarpe simili sarà vuoto
 */
vector<Shoe*> ShoeDatabase::getSimiliarShoes(Shoe *shoeParam)
{
    vector<Shoe*> shoeList;

    if(!open())
        return shoeList;

    QSqlQuery query;


    query.exec("SELECT * FROM " + ShoeDatabase::SHOE_TABLE_NAME +
               " WHERE " + ShoeDatabase::SHOE_ID_COLUMN + " != " + QString::number(shoeParam->getId()) +
               " AND " + ShoeDatabase::SHOE_SEX_COLUMN + " = '" + shoeParam->getSex() + "' "
               " AND " + ShoeDatabase::SHOE_CATEGORY_COLUMN + " = '" + shoeParam->getCategory() + "'");


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
            QString RFIDcode = query.value(ShoeDatabase::SHOE_RFID_CODE_COLUMN_POSITION).toString();


            //Array vuoto da inserire nel costruttore; è vuoto perchè per visualizzare le scarpe simili non importa sapere le taglie
            QVariantMap sizesAndQuantities;

            //Creo la nuova scarpa
            Shoe *shoe = new Shoe(id, brand, model, color, sex, price, category, sizesAndQuantities, mediaPath, RFIDcode);


            //Dato che le scarpe consigliate hanno una thumbnail, devo settare il path all'immagine per ogni scarpa. Prendo
            //quindi il path assoluto della cartella che conterrà la thumbnail
            QDir path = QDir::currentPath() + "/debug/shoes_media/" + shoe->getMediaPath() + "/thumbnail/";


            //Filtro per recuperare solo immagini, non si sa mai
            QStringList nameFilter;
            nameFilter << "*.png" << "*.jpg" << "*.gif";

            //Recupero il path del primo file trovato che soddisfi i filtri; userò quello come thumbnail
            QString thumbnailPath = "file:///" + path.entryInfoList(nameFilter, QDir::Files, QDir::Name).first().absoluteFilePath();

            //Setto quindi il path trovato come thumbnail della scarpa
            shoe->setThumbnailPath(thumbnailPath);

            //Infine, inserisco la scarpa nell'array
            shoeList.push_back(shoe);
        }

//        Shoe* shoe1 = this->getShoeFromId(1);
//        Shoe* shoe2 = this->getShoeFromId(3);
//        Shoe* shoe3 = this->getShoeFromId(4);
//        Shoe* shoe4 = this->getShoeFromId(8);

//        QDir path = QDir::currentPath() + "/debug/shoes_media/" + shoe1->getMediaPath() + "/thumbnail/";


//        QStringList nameFilter;
//        nameFilter << "*.png" << "*.jpg" << "*.gif";

//        QString thumbnailPath = "file:///" + path.entryInfoList(nameFilter, QDir::Files, QDir::Name).first().absoluteFilePath();

//        shoe1->setThumbnailPath(thumbnailPath);


//        path = QDir::currentPath() + "/debug/shoes_media/" + shoe2->getMediaPath() + "/thumbnail/";
//        thumbnailPath = "file:///" + path.entryInfoList(nameFilter, QDir::Files, QDir::Name).first().absoluteFilePath();
//        shoe2->setThumbnailPath(thumbnailPath);

//        path = QDir::currentPath() + "/debug/shoes_media/" + shoe3->getMediaPath() + "/thumbnail/";
//        thumbnailPath = "file:///" + path.entryInfoList(nameFilter, QDir::Files, QDir::Name).first().absoluteFilePath();
//        shoe3->setThumbnailPath(thumbnailPath);

//        path = QDir::currentPath() + "/debug/shoes_media/" + shoe4->getMediaPath() + "/thumbnail/";
//        thumbnailPath = "file:///" + path.entryInfoList(nameFilter, QDir::Files, QDir::Name).first().absoluteFilePath();
//        shoe4->setThumbnailPath(thumbnailPath);


//        shoeList.push_back(shoe1);
//        shoeList.push_back(shoe2);
//        shoeList.push_back(shoe3);
//        shoeList.push_back(shoe4);
    }
    else
    {
        if(query.size() == 0)
            qDebug() << "ShoeDatabase::getSimiliarShoes: nessuna scarpa simile è stata trovata";
        else
            qDebug() << "ShoeDatabase::getSimiliarShoes: c'è stato un errore nella query: " << query.lastError();
    }

    close();

    //Restituisco l'array, vuoto o no
    return shoeList;
}



/**
 * @brief ShoeDatabase::getAllBrands recupera tutte le marche disponibili nel database
 *
 * @return la lista delle marche; vuota in caso di errori o se non ne sono state trovate
 */
QStringList ShoeDatabase::getAllBrands()
{
    QStringList brands;

    if(!open())
        return brands;

    QSqlQuery query;

    query.exec("SELECT DISTINCT " + ShoeDatabase::SHOE_BRAND_COLUMN + " FROM " + ShoeDatabase::SHOE_TABLE_NAME + " " +
               "ORDER BY " + ShoeDatabase::SHOE_BRAND_COLUMN);


    if(query.lastError().number() == -1 && query.size() > 0)
    {
        while(query.next())
        {
            brands.append(query.value(0).toString());
        }
    }
    else
    {
        if(query.size() == 0)
            qDebug() << "ShoeDatabase::getAllBrands: nessuna marca trovata";
        else
            qDebug() << "ShoeDatabase::getAllBrands: c'è stato un errore nella query: " << query.lastError();
    }

    close();

    return brands;
}

/**
 * @brief ShoeDatabase::getAllCategories recupera tutte le categorie disponibili nel database
 *
 * @return la lista delle categorie; vuota in caso di errori o se non ne sono state trovate
 */
QStringList ShoeDatabase::getAllCategories()
{
    QStringList categories;

    if(!open())
        return categories;


    QSqlQuery query;

    query.exec("SELECT DISTINCT " + ShoeDatabase::SHOE_CATEGORY_COLUMN + " FROM " + ShoeDatabase::SHOE_TABLE_NAME + " " +
               "ORDER BY " + ShoeDatabase::SHOE_CATEGORY_COLUMN);


    if(query.lastError().number() == -1 && query.size() > 0)
    {
        while(query.next())
        {
            categories.append(query.value(0).toString());
        }
    }
    else
    {
        if(query.size() == 0)
            qDebug() << "ShoeDatabase::getAllCategories: nessuna categoria trovata";
        else
            qDebug() << "ShoeDatabase::getAllCategories: c'è stato un errore nella query: " << query.lastError();
    }

    close();

    return categories;
}

/**
 * @brief ShoeDatabase::getAllColors recupera tutti i colori disponibili nel database
 *
 * @return la lista dei colori; vuota in caso di errori o se non ne sono state trovate
 */
QStringList ShoeDatabase::getAllColors()
{
    QStringList colors;

    if(!open())
        return colors;


    QSqlQuery query;

    query.exec("SELECT DISTINCT " + ShoeDatabase::SHOE_COLOR_COLUMN + " FROM " + ShoeDatabase::SHOE_TABLE_NAME + " " +
               "ORDER BY " + ShoeDatabase::SHOE_COLOR_COLUMN);

    if(query.lastError().number() == -1 && query.size() > 0)
    {
        while(query.next())
        {
            colors.append(query.value(0).toString());
        }
    }
    else
    {
        if(query.size() == 0)
            qDebug() << "ShoeDatabase::getAllColors: nessun colore trovato";
        else
            qDebug() << "ShoeDatabase::getAllColors: c'è stato un errore nella query: " << query.lastError();
    }

    close();

    return colors;
}



/**
 * @brief ShoeDatabase::getAllSizes recupera tutte le taglie presenti nel database
 *
 * @return la lista delle taglie; vuota in caso di errori o se non ne sono state trovate
 */
QStringList ShoeDatabase::getAllSizes()
{
    QStringList sizes;

    if(!open())
        return sizes;


    QSqlQuery query;

    query.exec("SELECT DISTINCT " + ShoeDatabase::SIZE_SIZE_COLUMN + " FROM " + ShoeDatabase::SIZE_TABLE_NAME + " " +
               "ORDER BY " + ShoeDatabase::SIZE_SIZE_COLUMN);


    if(query.lastError().number() == -1 && query.size() > 0)
    {
        while(query.next())
        {
            sizes.append(query.value(0).toString());
        }
    }
    else
    {
        if(query.size() == 0)
            qDebug() << "ShoeDatabase::getAllSizes: nessuna taglia trovata";
        else
            qDebug() << "ShoeDatabase::getAllSizes: c'è stato un errore nella query: " << query.lastError();
    }

    close();

    return sizes;
}



/**
 * @brief ShoeDatabase::getPriceRange recupera il prezzo minimo e quello massimo presente nel database
 *
 * @return una lista contenente nel primo elemento il prezzo minimo e nel secondo quello massimo; vuota in caso di errori o se
 *         non ne sono state trovate
 */
QStringList ShoeDatabase::getPriceRange()
{
    QStringList priceRange;

    if(!open())
        return priceRange;


    QSqlQuery query;

    query.exec("SELECT MIN(" + ShoeDatabase::SHOE_PRICE_COLUMN + "), MAX(" + ShoeDatabase::SHOE_PRICE_COLUMN + ")" + " " +
               "FROM " + ShoeDatabase::SHOE_TABLE_NAME);


    if(query.lastError().number() == -1 && query.size() > 0)
    {
        while(query.next())
        {
            priceRange.append(query.value(0).toString());
            priceRange.append(query.value(1).toString());
        }
    }
    else
    {
        if(query.size() == 0)
            qDebug() << "ShoeDatabase::getPriceRange: nessuna prezzo trovato";
        else
            qDebug() << "ShoeDatabase::getPriceRange: c'è stato un errore nella query: " << query.lastError();
    }

    close();

    return priceRange;
}

/**
 * @brief ShoeDatabase::getFilteredShoes filtra le scarpe in base ai filtri passati e restituisce i risultati trovati. Le liste
 *        dei filtri passate possono essere anche vuote
 *
 * @param brandList lista delle marche da filtrare
 * @param categoryList lista delle categorie da filtrare
 * @param colorList lista dei colori da filtrare
 * @param sizeList lista delle taglie da filtrare
 * @param sexList lista del sesso da filtrare
 * @param minPrice prezzo minimo da applicare nella ricerca
 * @param maxPrice prezzo massimo da applicare nella ricerca
 *
 * @return la lista delle scarpe che soddisfano i filtri; può essere vuota se non ne sono state trovate o se c'è stato un errore
 */
vector<Shoe*> ShoeDatabase::getFilteredShoes(const QStringList& brandList, const QStringList& categoryList, const QStringList& colorList, const QStringList& sizeList, const QStringList& sexList, int minPrice, int maxPrice)
{
    vector<Shoe*> shoeList;

    if(!open())
        return shoeList;


    /* Dato che la query di ricerca è formata da parti che possono esserci o non esserci, e ogni parte ha lunghezza variabile,
     * attraverso un apposito metodo recupero le parti della query da usare per ogni categoria di filtro. La parte di query
     * restituita sarà del tipo "AND marca IN ('Adidas', 'Nike')", oppure sarà una stringa vuota se quella data categoria
     * di filtri non deve essere usata nella query (questo accade quando la lista dei filtri per quella categoria è vuota) */
    QString brandQueryPart = prepareFilterQueryPart(ShoeDatabase::SHOE_BRAND_COLUMN, brandList);
    QString categoryQueryPart = prepareFilterQueryPart(ShoeDatabase::SHOE_CATEGORY_COLUMN, categoryList);
    QString colorQueryPart = prepareFilterQueryPart(ShoeDatabase::SHOE_COLOR_COLUMN, colorList);
    QString sizeQueryPart = prepareFilterQueryPart(ShoeDatabase::SIZE_SIZE_COLUMN, sizeList);
    QString sexQueryPart = prepareFilterQueryPart(ShoeDatabase::SHOE_SEX_COLUMN, sexList);

    QSqlQuery query;


    /* Esempio di query risultante:
     *
     * SELECT * FROM scarpa JOIN taglia ON scarpa.id_scarpa = taglia.id_scarpa
     * WHERE prezzo BETWEEN 45 AND 90
     * AND marca IN ('Vans', 'Reebok')
     * AND categoria IN ('Running')
     * AND colore IN ('Nero', 'Rosso')
     * AND taglia IN ('38') AND sesso IN ('Uomo')
     * GROUP BY scarpa.id_scarpa
     *
     * Dato che il range di prezzi è sempre usato nella query, tutte le parti che possono essere opzionali e composte dal
     * metodo prepareFilterQueryPart() hanno davanti "AND ", in modo da concatenarsi a vicenda senza problemi
     */
    query.exec("SELECT * FROM " + ShoeDatabase::SHOE_TABLE_NAME +
               " JOIN " + ShoeDatabase::SIZE_TABLE_NAME +
               " ON " + ShoeDatabase::SHOE_TABLE_NAME + "." + ShoeDatabase::SHOE_ID_COLUMN + " = " + ShoeDatabase::SIZE_TABLE_NAME + "." + ShoeDatabase::SIZE_ID_COLUMN +
               " WHERE " + ShoeDatabase::SHOE_PRICE_COLUMN + " BETWEEN " + QString::number(minPrice) + " AND " + QString::number(maxPrice) +
               + "" + brandQueryPart + categoryQueryPart + colorQueryPart + sizeQueryPart + sexQueryPart
               + " GROUP BY " + ShoeDatabase::SHOE_TABLE_NAME + "." + ShoeDatabase::SHOE_ID_COLUMN);


    //Recupero i risultati, se ci sono; il recupero dei risultati è analogo a quello per le scarpe simili
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
            QString RFIDcode = query.value(ShoeDatabase::SHOE_RFID_CODE_COLUMN_POSITION).toString();


            //Array vuoto da inserire nel costruttore; è vuoto perchè per visualizzare le scarpe simili non importa sapere le taglie
            QVariantMap sizesAndQuantities;

            Shoe *shoe = new Shoe(id, brand, model, color, sex, price, category, sizesAndQuantities, mediaPath, RFIDcode);


            //Dato che le scarpe consigliate hanno una thumbnail, devo settare il path all'immagine per ogni scarpa. Prendo
            //quindi il path assoluto della cartella che conterrà la thumbnail
            QDir path = QDir::currentPath() + "/debug/shoes_media/" + shoe->getMediaPath() + "/thumbnail/";

            QStringList nameFilter;
            nameFilter << "*.png" << "*.jpg" << "*.gif";
            QString thumbnailPath = "file:///" + path.entryInfoList(nameFilter, QDir::Files, QDir::Name).first().absoluteFilePath();
            shoe->setThumbnailPath(thumbnailPath);

            //Infine, inserisco la scarpa nell'array
            shoeList.push_back(shoe);
        }
    }
    else
    {
        if(query.size() == 0)
            qDebug() << "ShoeDatabase::getFilteredShoes: nessuna scarpa è stata trovata con i filtri inseriti";
        else
            qDebug() << "ShoeDatabase::getFilteredShoes: c'è stato un errore nella query: " << query.lastError();
    }

    close();

////////////
    QThread::currentThread()->sleep(3);

    return shoeList;
}

/**
 * @brief ShoeDatabase::prepareFilterQueryPart è un metodo di convenienza per formare parti della query per filtrare le scarpe.
 *        Dato che i filtri possono essere molti (per marca, categoria, colore, ecc.) e per ognuno ci posssono essere molteplici
 *        filtri (ad esempio per marca Adidas, Nike, ecc.), la query deve essere formata dinamicamente.
 *        A questo metodo sono passati il nome della colonna del db coinvolta e l'elenco dei filtri da applicare. Il risultato
 *        è una stringa che contiene l'SQL da usare per applicare quei filtri all'interno della clausola WHERE, utilizzando
 *        la clausola IN. Ad esempio, se sto filtrando per marca il risulato può essere una stringa del genere:
 *        "marca IN ('Adidas', 'Nike')"
 *        dove "marca" è il nome della colonna per le marche.
 *        Se la lista dei filtri è vuota, viene restituita invece una stringa vuota. In questo modo tutte le stringhe
 *        ritornate da questo metodo sono usate per la query, ma solo quelle in cui la lista dei filtri non era vuota
 *        effettivamente saranno usate nella query.
 *        Dato che queste stringhe saranno poi usate una dopo l'altra, e sono usate tutte dopo una clausola WHERE fissa,
 *        tutte le stringhe ritornate da questo metodo avranno "AND" all'inizio.
 *        Quindi un output definitivo potrebbe essere:
 *        "AND marca IN ('Adidas', 'Nike')"
 *
 * @param columnName nome della colonna in cui si deve applicare la lista dei filtri
 * @param filterList lista contenente i filtri da applicare
 *
 * @return stringa contenente la parte della query relativa ai filtri considerati; stringa vuota se la lista dei filtri è vuota
 */
QString ShoeDatabase::prepareFilterQueryPart(const QString& columnName, const QStringList& filterList)
{
    //Se la lista dei filtri è vuota, ritorno una stringa vuota
    if(filterList.size() == 0)
        return "";

    //Compongo l'inizio della stringa inserendo anche il primo elemento, in modo da non dover controllare se bisogna mettere la
    //virgola o no nel for
    QString queryPart = " AND " + columnName + " IN ('" + filterList.at(0) + "'";

    //Scorro tutti i filtri e li aggiungo alla stringa
    for(int i = 1; i < filterList.size(); i++)
        queryPart.append(", '" + filterList.at(i) + "'");

    queryPart.append(")");

    return queryPart;
}



