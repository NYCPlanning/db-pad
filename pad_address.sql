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
