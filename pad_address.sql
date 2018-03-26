-- creates the PAD BIN / ADDRESS flat file

-- for records with only one address put the street name in ()
UPDATE dcp_pad_bobaadr
SET stname = '('||trim(stname)||')'
WHERE bin IN (
	SELECT bin
	FROM dcp_pad_bobaadr
	GROUP BY bin
	HAVING COUNT(*) = 1 
);

-- create the PAD BIN / ADDRESS flat file, with addresses seperated by ::
-- does not yet remove () from corner lots, etc.
DROP TABLE dcp_pad;
CREATE TABLE dcp_pad AS (
WITH newhousenum AS (
	SELECT a.*, trim(lhnd) AS newhnd
	FROM dcp_pad_bobaadr a
	WHERE lhnd = hhnd
	AND lhnd ~ '[0-9a-z]'
UNION
	SELECT a.*, trim(lhnd)||' - '||trim(hhnd) AS newhnd
	FROM dcp_pad_bobaadr a
	WHERE lhnd <> hhnd
	AND lhnd ~ '[0-9a-z]'
	AND hhnd ~ '[0-9a-z]'
UNION
	SELECT a.*, NULL AS newhnd
	FROM dcp_pad_bobaadr a
	WHERE lhnd = hhnd
	AND trim(lhnd) = ''
),
agghousenum AS (
	SELECT 	bin, 
		array_to_string(array_agg(DISTINCT trim(newhnd)), ',')||' '||trim(stname) AS newhnd
	FROM newhousenum
	GROUP BY stname, bin
	ORDER BY stname
)
SELECT bin,
array_to_string(array_agg(DISTINCT trim(newhnd)), '::') AS alladd
FROM agghousenum
GROUP BY bin 
);

UPDATE dcp_pad
SET alladd = REPLACE(alladd,'(','')
WHERE bin::text IN
(SELECT bin::text FROM building_composite
WHERE lottype='3' OR lottype = '4' OR (lottype='1' AND lotarea::double precision >= 10000) OR (numbldgs > 3 AND numfloors >= 8 AND lotarea::double precision >= 10000)
)
AND alladd LIKE '%(%)%';

UPDATE dcp_pad
SET alladd = REPLACE(alladd,')','')
WHERE bin::text IN
(SELECT bin::text FROM building_composite
WHERE lottype='3' OR lottype = '4' OR (lottype='1' AND lotarea::double precision >= 10000) OR (numbldgs > 3 AND numfloors >= 8 AND lotarea::double precision >= 10000)
)
AND alladd LIKE '%)%';




COPY(
SELECT * FROM dcp_pad WHERE bin <> '1000000'
  )TO '/prod/db-pad/output/dcp_pad_flat.csv' DELIMITER ',' CSV HEADER;
