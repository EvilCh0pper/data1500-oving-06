# Besvarelse: Avansert SQL

## Oppgave 1: Window Functions

### Del 1: Forklar SQL-spørringene

1.  **Spørring:**
    ```sql
    SELECT
        Fornavn,
        Etternavn,
        Årslønn,
        RANK() OVER (ORDER BY Årslønn DESC) AS Lønnsrangering
    FROM Ansatt;
    ```
    **Forklaring:**
    *   *Vis kolonnene fornavn, etternavn, årslønn, og en egen kolonne som rangerer etter årslønn nedadgående - og omdøp denne til Lønnsrangering. Hent fra ansatt*.

2.  **Spørring:**
    ```sql
    SELECT
        V.Betegnelse,
        K.Navn AS Kategori,
        V.Pris,
        AVG(V.Pris) OVER (PARTITION BY K.Navn) AS GjennomsnittsprisForKategori
    FROM Vare V
    JOIN Kategori K ON V.KatNr = K.KatNr;
    ```
    **Forklaring:**
    *   *Vis kolonnene v.betegnelse, k.navn omdøpt som kategori, v.pris.*

### Del 2: Lag SQL-spørringer
 

1.  **Rangering av varer per kategori:**
    ```sql
    SELECT
        betegnelse,
        katnr,
        RANK() OVER (ORDER BY katnr DESC) AS kategorirangering
    FROM vare;
    ```

2.  **Løpende sum av ordrebeløp:**
    ```sql
    -- Skriv din SQL-spørring her

    SELECT 
        ordrenr,
        antall,
        SUM(antall * prisprenhet) OVER (PARTITION BY ordrenr ORDER BY vnr) AS løpende_pris
    FROM ordrelinje;
    ```

3.  **Prosentandel av kategoriprisen:**
    ```sql
    SELECT 
        betegnelse,
        pris,
        katnr,
        ROUND(pris / (SUM(pris) OVER (PARTITION BY katnr)) * 100, 2) AS prosentandel,
        SUM(pris) OVER (PARTITION BY katnr) AS kategorisum
    FROM vare;
    ```

---

## Oppgave 2: Common Table Expressions (CTEs)

### Del 1: Forklar SQL-spørringen

1.  **Spørring:**
    ```sql
    WITH KunderPerPoststed AS (
        SELECT PostNr, COUNT(*) AS AntallKunder
        FROM Kunde
        GROUP BY PostNr
    )
    SELECT P.Poststed, KPP.AntallKunder
    FROM Poststed P
    JOIN KunderPerPoststed KPP ON P.PostNr = KPP.PostNr
    WHERE KPP.AntallKunder > 5
    ORDER BY KPP.AntallKunder DESC;
    ```
    **Forklaring:**
    *   *CTE-en viser antall kunder per postnr fra kundetabellen. Utenfor CTE-en vises p.poststed og kpp.antallKunder, der poststed P slås sammen med CTE-en tabellen kundeperpoststed gjennom postnr-nøkkelen. Videre spesifiseres at KPP.AntallKunder må være høyere enn 5, og sorteres nedover etter denne kolonnen*

### Del 2: Lag SQL-spørringer

1.  **Ansatte med over gjennomsnittslønn:**
    ```sql
    -- Skriv din SQL-spørring her
    WITH gjennomsnittslønn AS (
        SELECT 
            AVG(Årslønn) AS gjennomsnitt
        FROM ansatt
    )
    SELECT a.* 
    FROM ansatt a, gjennomsnittslønn
    WHERE a.Årslønn > gjennomsnittslønn.gjennomsnitt;
    ```

2.  **Kategorier med flest varer:**
    ```sql
    -- Skriv din SQL-spørring her
    WITH varestatistikk AS (
        SELECT DISTINCT
            k.katnr,
            SUM(v.antall) OVER (PARTITION BY k.katnr) AS mengde
        FROM vare v
        JOIN kategori k ON v.katnr = k.katnr
    )
    SELECT k.navn, vs.mengde
    FROM kategori k
    JOIN varestatistikk vs ON k.katnr = vs.katnr
    ORDER BY vs.mengde DESC LIMIT 3;

    ```

3.  **Rekursiv CTE - Hierarki av ansatte:**
    ```sql
    -- Skriv din SQL-spørring her (inkluder gjerne ALTER TABLE og testdata)
    BEGIN;
    ALTER TABLE Ansatt ADD COLUMN LederAnsNr INT;
    WITH RECURSIVE hierarki AS (
    -- Basistilfelle: startpunkt
        SELECT AnsNr, Fornavn, LederAnsNr, 0 AS Nivå
        FROM Ansatt
        WHERE LederAnsNr IS NULL

        UNION ALL

        -- Rekursivt steg: finn alle underordnede
        SELECT A.AnsNr, A.Fornavn, A.LederAnsNr, H.Nivå + 1
        FROM Ansatt A
        JOIN hierarki H ON A.LederAnsNr = H.AnsNr
    )
    SELECT * FROM hierarki;
    END;
    ```

---

## Oppgave 3: Avanserte Subqueries

### Del 1: Forklar SQL-spørringene

1.  **Spørring (Correlated Subquery):**
    ```sql
    SELECT V.Betegnelse, V.Pris
    FROM Vare V
    WHERE V.Pris > (
        SELECT AVG(Pris)
        FROM Vare
        WHERE KatNr = V.KatNr
    );
    ```
    **Forklaring:**
    *   *... Skriv din forklaring her ...*

2.  **Spørring (Subquery i `FROM`):**
    ```sql
    SELECT Kategori, Gjennomsnittspris
    FROM (
        SELECT K.Navn AS Kategori, AVG(V.Pris) AS Gjennomsnittspris
        FROM Vare V
        JOIN Kategori K ON V.KatNr = K.KatNr
        GROUP BY K.Navn
    ) AS KategoriPriser
    WHERE Gjennomsnittspris > 100;
    ```
    **Forklaring:**
    *   *... Skriv din forklaring her ...*

### Del 2: Lag SQL-spørringer

1.  **Kunder som har bestilt en spesifikk vare:**
    ```sql
    -- Skriv din SQL-spørring her
    SELECT fornavn, etternavn
    FROM kunde k
    WHERE '10820' IN (
        SELECT ol.vnr
        FROM ordrelinje ol
        JOIN ordre o ON ol.ordrenr = o.ordrenr
        WHERE o.knr = k.knr
    );
    ```

2.  **`EXISTS` - Kategorier med dyre varer:**
    ```sql
    -- Skriv din SQL-spørring her
        SELECT *
        FROM kategori k
        WHERE EXISTS (
            SELECT pris
            FROM vare v
            WHERE pris > 1000 AND v.katnr = k.katnr 
        )
    ```

3.  **Varer dyrere enn gjennomsnittet:**
    ```sql
    -- Skriv din SQL-spørring her
    SELECT betegnelse, pris
    FROM vare 
    WHERE pris > (
        SELECT AVG(pris) AS gjennomsnitt
        FROM vare
    )
    ORDER BY pris DESC;
    ```

## Ekstraoppgave (valgfri)

**Kombiner CTE og Window Function:** Bruk en CTE til å beregne totalt salgsbeløp per vare (sum av `Pris * Antall` fra `Ordrelinje`), og bruk deretter en window function til å rangere varene etter totalt salgsbeløp innenfor hver kategori. Vis topp 3 varer per kategori.

```sql
-- Hint: Bruk RANK() OVER (PARTITION BY ... ORDER BY ...) og filtrer på rang <= 3
```