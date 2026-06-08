# Øvingsoppgave 2.2: Avansert SQL

**Mål:** Lære å bruke avanserte SQL-teknikker — Window Functions, Common Table Expressions (CTEs), og avanserte subqueries — for å utføre komplekse analyser på en relasjonsdatabase.

**Database:** `hobbyhuset` (samme som i øving 2.1)

---

## Kom i gang

### Forutsetninger

Denne øvingen bygger på `hobbyhuset`-databasen fra øving 2.1. Sørg for at databasen kjører og er populert med data fra `init-scripts/hobbyhuset.sql` og utvidelsene fra `test-scripts/hobbyhuset_utvidet_o5-6.sql`.

### Start databasen

```bash
docker-compose up -d
```

### Kjør utvidelsene (hvis du ikke allerede har gjort det)

```bash
docker-compose exec postgres psql -U admin -d hobbyhuset -f test-scripts/hobbyhuset_utvidet_o5-6.sql
```

### Koble til databasen

```bash
docker-compose exec postgres psql -U admin -d hobbyhuset
```


---

## Besvarelse

- Forklaringer og SQL skrives i `besvarelse-avansert-sql.md`


---

## Oppgave 1: Window Functions

*Window functions* (vindufunksjoner) utfører beregninger på et sett med rader som er relatert til den nåværende raden, uten å kollapse radene til én (slik `GROUP BY` gjør). De brukes til rangeringer, løpende totaler, og sammenligninger innenfor grupper.

**Generell syntaks:**
```sql
funksjon() OVER (
    [PARTITION BY kolonne]  -- Del opp i grupper
    [ORDER BY kolonne]      -- Sorter innenfor gruppen
)
```

**Vanlige vindufunksjoner:**

| Funksjon | Beskrivelse |
|----------|-------------|
| `RANK()` | Gir rang med hopp ved like verdier (1, 2, 2, 4) |
| `DENSE_RANK()` | Gir rang uten hopp ved like verdier (1, 2, 2, 3) |
| `ROW_NUMBER()` | Gir unikt løpenummer per rad |
| `SUM() OVER (...)` | Løpende sum |
| `AVG() OVER (...)` | Løpende eller partisjonert gjennomsnitt |

### Del 1: Forklar SQL-spørringene (skriv i `besvarelse-avansert-sql-sql.md`)

1.  **Spørring:**
    ```sql
    SELECT
        Fornavn,
        Etternavn,
        Årslønn,
        RANK() OVER (ORDER BY Årslønn DESC) AS Lønnsrangering
    FROM Ansatt;
    ```

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

### Del 2: Lag SQL-spørringer (skriv i `besvarelse-avansert-sql.sql`)

1.  **Rangering av varer per kategori:** Rangér alle varer etter pris (dyrest først) *innenfor* hver kategori. Resultatet skal vise varenavn, kategori, pris og rang.
```sql
SELECT 
    betegnelse,
    pris,
    katnr,
    RANK() OVER (PARTITION BY katnr ORDER BY pris DESC) AS rang
FROM vare;
```

2.  **Løpende sum:** Vis alle ordrer med ordredato og totalbeløp (`SUM(Pris * Antall)` fra `Ordrelinje`), og legg til en kolonne som viser den *løpende summen* av ordrebeløp sortert etter dato.
```sql
SELECT
    o.ordrenr,
    o.ordredato,
    SUM(ol.prisprEnhet * ol.antall) AS ordrebelop,
    SUM(SUM(ol.prisprEnhet * ol.antall)) 
        OVER (ORDER BY o.ordredato) AS lopende_sum
FROM ordre o
JOIN ordrelinje ol USING (ordrenr)
GROUP BY o.ordrenr, o.ordredato
ORDER BY o.ordredato;
```

3.  **Prosentandel av kategoriprisen:** For hver vare, beregn hvor stor prosentandel varens pris utgjør av den totale prisen for alle varer i samme kategori. Avrund til to desimaler.

---

## Oppgave 2: Common Table Expressions (CTEs)

En CTE (Common Table Expression) er en midlertidig, navngitt resultattabell som defineres med `WITH`-nøkkelordet. CTEs gjør komplekse spørringer mer lesbare ved å dele dem opp i logiske steg.

**Generell syntaks:**
```sql
WITH navn_paa_cte AS (
    SELECT ...   -- Definer den midlertidige tabellen
)
SELECT *         -- Bruk den midlertidige tabellen
FROM navn_paa_cte
WHERE ...;
```

Du kan også definere **rekursive CTEs** for å traversere hierarkiske strukturer (f.eks. organisasjonskart):
```sql
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
```

### Del 1: Forklar SQL-spørringen (skriv i `besvarelse-avansert-sql-sql.md`)

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

### Del 2: Lag SQL-spørringer (skriv i `besvarelse-avansert-sql.sql`)

1.  **Ansatte med over gjennomsnittslønn:** Bruk en CTE til å først beregne gjennomsnittslønnen for alle ansatte, og deretter liste opp alle ansatte som tjener mer enn dette gjennomsnittet. Vis navn, stilling og lønn.

```sql
WITH snittloenn AS (
    SELECT AVG("Årslønn") AS snitt
    FROM ansatt
)

SELECT 
    CONCAT(fornavn, ' ', etternavn) AS navn,
    stilling,
    "Årslønn"
FROM ansatt, snittloenn
WHERE "Årslønn" > snittloenn.snitt;

```

2.  **Kategorier med flest varer:** Bruk en CTE til å telle antall varer i hver kategori, og deretter finne *kun* kategorien(e) med flest varer. Vis kategorinavn og antall.

```sql
WITH varer_per_kategori AS (
    SELECT katnr, COUNT(*) AS antall
    FROM vare
    GROUP BY katnr
)

SELECT k.navn, vpk.antall
FROM kategori AS k
JOIN varer_per_kategori AS vpk USING(katnr)
WHERE vpk.antall > 10 ORDER BY vpk.antall DESC;
-- WHERE vpk.antall = (SELECT MAX(antall) FROM varer_per_kategori) egentlig riktig


```


3.  **Rekursiv CTE — Hierarki av ansatte:** Legg til en `LederAnsNr`-kolonne i `Ansatt`-tabellen og sett inn noen testverdier (f.eks. at ansatt 1 er leder for ansatt 2 og 3, og ansatt 2 er leder for ansatt 4). Skriv deretter en rekursiv CTE som finner alle ansatte som rapporterer til ansatt 1, direkte eller indirekte, og vis hvilket nivå i hierarkiet de befinner seg på.

```sql
WITH RECURSIVE hierarki AS (
    SELECT CONCAT(fornavn, ' ', etternavn) AS navn, ansnr, stilling, LederAnsNr, 0 AS nivaa
    FROM Ansatt
    WHERE LederAnsNr IS NULL

    UNION ALL

    SELECT CONCAT(sub.fornavn, ' ', sub.etternavn) AS navn, sub.ansnr, sub.stilling, sub.LederAnsNr, dom.nivaa + 1
    FROM Ansatt AS sub
    JOIN hierarki AS dom ON sub.LederAnsNr = dom.ansnr
)

SELECT * FROM hierarki

```

---

## Oppgave 3: Avanserte Subqueries

En subquery (underspørring) er en `SELECT`-setning inni en annen SQL-setning. Subqueries kan brukes i `WHERE`, `FROM`, og `SELECT`-klausuler.

**Typer subqueries:**

| Type | Beskrivelse | Eksempel |
|------|-------------|---------|
| **Skalær** | Returnerer én enkelt verdi | `WHERE Pris > (SELECT AVG(Pris) FROM Vare)` |
| **Korrelert** | Refererer til den ytre spørringen | `WHERE Pris > (SELECT AVG(Pris) FROM Vare WHERE KatNr = V.KatNr)` |
| **I `FROM`** | Brukes som en midlertidig tabell | `FROM (SELECT ...) AS t` |
| **Med `EXISTS`** | Sjekker om subquery returnerer rader | `WHERE EXISTS (SELECT 1 FROM ...)` |

### Del 1: Forklar SQL-spørringene (skriv i `besvarelse-avansert-sql-sql.md`)

1.  **Spørring (Korrelert subquery):**
    ```sql
    SELECT V.Betegnelse, V.Pris
    FROM Vare V
    WHERE V.Pris > (
        SELECT AVG(Pris)
        FROM Vare
        WHERE KatNr = V.KatNr
    );
    ```

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

### Del 2: Lag SQL-spørringer (skriv i `besvarelse-avansert-sql.sql`)

1.  **Kunder som har bestilt en spesifikk vare:** Finn fornavn og etternavn på alle kunder som har bestilt varen med `VNr` = `'10820'`. Bruk en subquery med `IN`.
```sql
SELECT fornavn, etternavn
FROM kunde
WHERE knr IN (
    SELECT k.knr
    FROM kunde k 
    JOIN ordre o ON k.knr = o.knr
    JOIN ordrelinje ol ON o.ordrenr = ol.ordrenr
    WHERE ol.vnr = '10820'
);
    

```
2.  **`EXISTS` — Kategorier med dyre varer:** Bruk `EXISTS` for å finne alle kategorier som har minst én vare med en pris over 1000 kr. Vis kategorinavn.

```sql
    SELECT k.katnr, k.navn
    FROM kategori k
    JOIN vare v USING (katnr)
    WHERE EXISTS(
        SELECT iv.katnr, pris
        FROM vare iv
        WHERE iv.pris > 1000 AND iv.katnr = k.katnr
    )
    GROUP BY k.katnr
    ;
```

```sql
--løsningsforslag:
SELECT k.katnr, k.navn
FROM kategori k
WHERE EXISTS (
    SELECT 1
    FROM vare v
    WHERE v.katnr = k.katnr
    AND v.pris > 1000
);
```

3.  **Varer dyrere enn gjennomsnittet:** Finn alle varer som er dyrere enn gjennomsnittsprisen for *alle* varer i databasen. Vis varenavn og pris, sortert fra dyrest til billigst.
```sql
SELECT v.betegnelse, v.pris
FROM vare v
WHERE v.pris > (
    SELECT AVG(pris)
    FROM vare
)
ORDER BY pris DESC;

```

## MER EKSTRA 
1. **Exercise 1 — Basic ranking**
Ranger alle ansatte etter årslønn innenfor hver stilling (stilling). Vis fornavn, stilling, årslønn og rang.
```sql

SELECT 
    fornavn,
    stilling,
    "Årslønn",
    RANK() OVER (PARTITION BY stilling ORDER BY "Årslønn" DESC)
FROM ansatt;

```

2. **Exercise 2 — Running total**
Vis alle ordrer med ordredato og totalbeløp per ordre, og legg til en løpende sum av ordrebeløp sortert etter dato.
```sql
SELECT
    o.ordredato,
    SUM(SUM(ol.prisprenhet*ol.antall)) OVER (ORDER BY o.ordredato)
FROM ordre o
JOIN ordrelinje ol USING (ordrenr)
GROUP BY o.ordredato;
```

3. **Exercise 3 — Lag/Lead**
For hver prisendring i prishistorikk, vis varenummer, dato, gammel pris, og den forrige prisen for samme vare. Bruk LAG().
4. **Exercise 4 — Combined CTE + window function**
Bruk en CTE til å beregne totalt antall ordrer per kunde, og bruk deretter en window function til å rangere kundene etter antall ordrer innenfor hvert poststed. Vis topp 2 kunder per poststed.
```sql
WITH shit AS (
    SELECT k.knr, COUNT(*) AS antall_ordre
    FROM ordre 
    JOIN kunde k USING (knr)
    GROUP BY k.knr
)
SELECT 
    k.knr, 
    s.antall_ordre,
    k.postnr,
    RANK() OVER (PARTITION BY k.postnr ORDER BY s.antall_ordre DESC)
FROM kunde k JOIN shit s USING (knr)
ORDER BY k.postnr;

```


---

## Ekstraoppgave (valgfri)

**Kombiner CTE og Window Function:** Bruk en CTE til å beregne totalt salgsbeløp per vare (sum av `Pris * Antall` fra `Ordrelinje`), og bruk deretter en window function til å rangere varene etter totalt salgsbeløp innenfor hver kategori. Vis topp 3 varer per kategori.

```sql
-- Hint: Bruk RANK() OVER (PARTITION BY ... ORDER BY ...) og filtrer på rang <= 3
WITH totalt_belop AS (
    SELECT 
        vnr,
        SUM(prisprenhet * antall) AS total
    FROM ordrelinje
    GROUP BY vnr;
)

SELECT 
    v.betegnelse,
    tb.total,
    RANK() OVER (PARTITION BY tb.total ORDER BY tb.total) AS rang
FROM vare v JOIN totalt_belop tb USING (vnr)
HAVING rang <= 3;
```

correct:

```sql
WITH totalt_belop AS (
    SELECT 
        vnr,
        SUM(prisprEnhet * antall) AS total
    FROM ordrelinje
    GROUP BY vnr
),
rangert AS (
    SELECT 
        v.betegnelse,
        v.katnr,
        tb.total,
        RANK() OVER (PARTITION BY v.katnr ORDER BY tb.total DESC) AS rang
    FROM vare v
    JOIN totalt_belop tb USING (vnr)
)
SELECT *
FROM rangert
WHERE rang <= 3;
```

explanation:
```sql
WITH totalt_belop AS (
    ...  -- CTE 1: beregner total per vare
),
rangert AS (
    ...  -- CTE 2: bruker CTE 1 og legger til rang
)
SELECT * FROM rangert  -- henter fra CTE 2
WHERE rang <= 3;
```
