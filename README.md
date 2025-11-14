# R per proletari - Episodio 05

**R per proletari** è una serie di post su LinkedIn dedicata a chi vuole
liberarsi dal giogo del lavoro manuale e automatizzare la produzione di report
ripetitivi con la potenza collettiva di **R**, **Quarto** e **Shiny**.

In questo **episodio 05**, il proletariato può finalmente trasformare
uno specifico formato di file Excel luridamente borghese in un dataset ordinato
e pronti per l'analisi: nessuna cella fermerà la rivoluzione!

---

## Obiettivo

I dati con cui lavoro sono spesso generati da laboratori o fonti multiple, con:

- colonne duplicate o mancanti,
- date in formati diversi,
- valori sotto limite di quantificazione (“<LoQ”),
- limiti locali e nazionali mescolati.

Questa serie di funzioni permette di:

- Leggere e normalizzare tutte le informazioni dal foglio Excel.
- Gestire valori mancanti, sotto LoQ e sopra limite.
- Applicare controlli di base sui metadati (date, laboratori, punti di campionamento).
- Combinare automaticamente più fogli in un unico dataset.

---

## Struttura del progetto

```bash
R/
  |- get_clean_values.R  # Funzioni principali e sotto-funzioni modulari
  |- checks.R            # Controlli e validazioni opzionali
data/                    # File Excel di esempio
renv/                    # Informazioni per maggiore riproducibilità
utilizzo.R               # Esempio di utilizzo
README.md                # Questo file
```
---

## Funzioni principali

`get_clean_values(path, sheet)`

- Legge un singolo foglio Excel e restituisce un data.table normalizzato.
- Gestisce:
  - Sample ID
  - Punto di campionamento
  - Data di campionamento (numeri Excel o stringhe)
  - Nome laboratorio
  - Parametri e valori
  - Limiti nazionali/locali
  - Flag below_loq e above_limit
- Modularizzata in sotto-funzioni per leggibilità e manutenzione.

`process_excel_file(file)`

- Applica get_clean_values() a tutti i fogli di un file Excel.
- Restituisce un unico data.table combinato.
- Ideale per file multipli con dati simili ma separati per area o laboratorio.

---

## Requisiti

- **R >= 4.2**  
- Tutti i pacchetti R sono gestiti tramite **renv**.

---

## Setup

1. Clonare il repository:

   ```bash
   git clone https://github.com/andreabz/r-proletari-05.git
   cd r-proletari-05
   ```
   
2. Ripristinare le dipendenze

   ```r
   renv::restore()
   ```
   
3. Eseguire lo script `utilizzo.R`
   
## Criteri di valutazione dei dati secondo il Decreto Legislativo 155/2010

Il report confronta i dati osservati con i valori limite di legge, ad esempio:

- PM10 → media giornaliera ≤ 50 µg/m³ (max 35 superamenti/anno).
- NO₂ → max oraria ≤ 200 µg/m³ (max 18 superamenti/anno).
- O₃ → max media mobile 8h ≤ 120 µg/m³ (max 25 superamenti/anno).
- CO → max media mobile 8h ≤ 10 mg/m³.
- SO₂ → max giornaliera ≤ 125 µg/m³ (max 3 superamenti/anno).
- SO₂ → max oraria ≤ 350 µg/m³ (max 24 superamenti/anno).

## Output

Una applicazione web `shiny` disponibile all'indirizzo [https://abazz.shinyapps.io/r-proletari-04/](https://abazz.shinyapps.io/r-proletari-04/)

## Contatti e contributi

Il codice è libero come dev'essere la conoscenza: ogni compagno o compagna può **leggerlo, copiarlo, migliorarlo o farne una propria versione**.  
Le *pull request* sono benvenute, purché portino avanti la causa della **trasparenza e dell’efficienza proletaria**.

📬 **Scrivici:** [LinkedIn](https://it.linkedin.com/in/andreabazzano)  
💻 **Partecipa:** [GitHub](https://github.com/andreabz/)

Ogni bug è una **contraddizione interna del sistema**: segnalarlo è un atto rivoluzionario.  
Se l'app ti è utile, **condividila**.  
Se ti piace, **forkala**.  
Se non funziona, **riparala**.  
L’importante è **non restare fermi**.

> *“La statistica al servizio del popolo, non del profitto.”*
