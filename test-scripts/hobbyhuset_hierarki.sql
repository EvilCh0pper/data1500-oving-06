-- Step 1: Add the column
ALTER TABLE Ansatt ADD COLUMN LederAnsNr SMALLINT REFERENCES Ansatt(AnsNr);

-- Step 2: Set up a hierarchy rooted at AnsNr = 7 (Henriette, Daglig leder)
--
--         7  (Daglig leder - Henriette Brobakken)
--        / \
--       2   3
--      / \   \
--     6   13   1
--    /
--   16

UPDATE Ansatt SET LederAnsNr = 7  WHERE AnsNr = 2;   -- Gunnlaug rapporterer til Henriette
UPDATE Ansatt SET LederAnsNr = 7  WHERE AnsNr = 3;   -- Morgan rapporterer til Henriette
UPDATE Ansatt SET LederAnsNr = 2  WHERE AnsNr = 6;   -- Vilde rapporterer til Gunnlaug
UPDATE Ansatt SET LederAnsNr = 2  WHERE AnsNr = 13;  -- Oda rapporterer til Gunnlaug
UPDATE Ansatt SET LederAnsNr = 3  WHERE AnsNr = 1;   -- Georg rapporterer til Morgan
UPDATE Ansatt SET LederAnsNr = 6  WHERE AnsNr = 16;  -- Andrine rapporterer til Vilde
UPDATE Ansatt SET LederAnsNr = 1  WHERE AnsNr = 8;   -- Synøve rapporterer til Georg
UPDATE Ansatt SET LederAnsNr = 1  WHERE AnsNr = 11;  -- Oliver rapporterer til Georg

-- Step 3: Recursive CTE — all employees under AnsNr 7, with hierarchy level
WITH RECURSIVE Hierarki AS (

    -- Base case: the root (Daglig leder, no manager)
    SELECT
        AnsNr,
        Fornavn,
        Etternavn,
        Stilling,
        LederAnsNr,
        0 AS Nivå
    FROM Ansatt
    WHERE AnsNr = 7

    UNION ALL

    -- Recursive step: find direct reports of whoever is already in the result
    SELECT
        A.AnsNr,
        A.Fornavn,
        A.Etternavn,
        A.Stilling,
        A.LederAnsNr,
        H.Nivå + 1
    FROM Ansatt A
    JOIN Hierarki H ON A.LederAnsNr = H.AnsNr

)
SELECT
    Nivå,
    REPEAT('    ', Nivå) || Fornavn || ' ' || Etternavn AS Ansatt,
    Stilling,
    AnsNr,
    LederAnsNr AS RapportererTil
FROM Hierarki
ORDER BY Nivå, AnsNr;