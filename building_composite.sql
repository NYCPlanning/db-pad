-- creates the Buildings Composite Dataset


WITH footprint_centroid AS(
	SELECT name,
			bin,
			bbl,
			cnstrct_yr,
			lstmoddate,
			lststatype,
			doitt_id,
			heightroof,
			feat_code,
			groundelev,
			num_floors,
			built_code,
			ST_Centroid(geom) as geom
	FROM doitt_buildingfootprints
),
footprint_mappluto AS (
	SELECT 
	a.bbl,
	a.bbl::text as bbl_text,
	a.bin,
	a.doitt_id,
	b.cd,
	b.bldgclass,
	b.landuse,
	b.ownername,
	b.ownertype,
	b.numbldgs,
	b.numfloors,
	b.lotarea,
	b.unitsres,
	b.unitstotal,
	b.bsmtcode,
	b.proxcode,
	b.lottype,
	b.yearbuilt,
	b.yearalter1,
	b.yearalter2,
	b.borocode,
	a.heightroof,
	a.feat_code,
	a.groundelev,
	a.lststatype,
	b.bbl AS sv_bbl
	FROM footprint_centroid a, dcp_mappluto b
	WHERE ST_Within(a.geom, b.geom)
),
footprint_mappluto_pad AS (
SELECT a.*, b.alladd as padaddress 
FROM footprint_mappluto a
LEFT JOIN dcp_pad b 
ON a.bin::text=b.bin
)

SELECT * FROM footprint_mappluto_pad LIMIT 1

;

DROP TABLE IF EXISTS building_composite;
CREATE building_composite AS (

SELECT 

)