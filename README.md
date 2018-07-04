Authors: Francesco Desogus, Gabriele Marini (Gabryxx7)

Screenshots from the software:

![1 - Sample from the software](http://i65.tinypic.com/s15jkw.png)

![2 - Sample from the software](http://i68.tinypic.com/1ykfuw.png)

![2 - Sample from the software](http://i63.tinypic.com/2077sk8.png)

************************************************************************************
Qua su git c'è il progetto dell'applicazione, da importare così com'è su QtCreator; dentro c'è tutto il codice sorgente oltre che le immagini
e cose varie usate dall'app. Il contenuto è tutto sparso, per vederlo con più ordine bisogna importare il progetto su QtCreator.
************************************************************************************

In generale, l'applicazione è stata fatta con le Qt versione 5.2.1, e ha bisogno delle seguenti cose per funzionare:

- WAMP: attualmente l'app usa un database in locale (il database usato si può scaricare qua: https://drive.google.com/file/d/0B_aMDsgPQiUsQzYtbVkxVVA0Ym8/edit?usp=sharing), 
  quindi serve WAMP per crearlo, altrimenti rimane tutto bloccato nella prima schermata e mostra un errore.
  
- Driver SQL: per far funzionare il database bisogna scaricare i driver contenuti in questo archivio: https://drive.google.com/file/d/0B_aMDsgPQiUsTTM5OUV5MmxHR2M/edit?usp=sharing
  e copiare i file .dll nella cartella di deploy dell'applicazione (dove c'è l'eseguibile).

- Le immagini delle scarpe: attualmente non ci sono check per vedere se le immagini delle scarpe sono presenti, quindi se 
  non ci sono l'app crasha se non le trova (crasha quando non trova le thumbnail delle scarpe, quelle da mostrare nelle
  scarpe simili). Le immagini delle scarpe relative al database contenuto nella cartella si possono scaricare qua: 
  https://drive.google.com/file/d/0B_aMDsgPQiUsbTR3RHl1dUtueDg/edit?usp=sharing
  Nell'archivio da scaricare c'è una cartella da copiare ed incollare così com'è all'interno della cartella di deploy dell'applicazione
  (dove c'è l'eseguibile).
  
Con queste cose messe, l'applicazione dovrebbe funzionare.

***********************************

Ulteriori info:

- I nomi delle porte seriali per l'RFID reader e per l'Arduino sono presi come costanti nelle rispettive classi che li 
  gestiscono (ci vorrebbe un'interfaccia semplice che permetta di selezionarle all'avvio dell'applicazione, che poi permetta di
  avviare l'applicazione in se una volta selezionate le porte). Se si attacca l'RFID reader o l'Arduino, bisogna quindi controllare che i nomi delle costanti combacino con
  le effettive porte a cui sono attaccati.

- All'avvio dell'applicazione viene caricata una scarpa; questo è fatto per provare l'applicazione senza avere l'RFID reader.
  Senza l'RFID reader l'applicazione non crasha (mostra un warning nella console dicendo che non è stato rilevato), però
  non sarebbe neanche possibile visualizzare le scarpe.
  Per togliere il caricamento della nuova schermata all'inizio dell'applicazione bisogna commentare l'istruzione
  "emit requestShoeData("710024E7F3");" nella classe WindowManager
  
- Ogni volta che si filtrano le scarpe l'applicazione prova a mandare messaggi all'Arduino per illuminare le scarpe.
  Se l'Arduino non è attaccato, l'operazione non ha effetto e non viene mostrato nessun warning/errore nell'applicazione.

- Quando si filtrano le scarpe c'è un caricamento di 1 secondo, messo solo per mostrare il caricamento asincrono dei dati.
  Per toglierlo bisogna commentare una riga nella classe ShoeDatabase contenente una chiamata alla funzione sleep del thread.
