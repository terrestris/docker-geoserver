UPDATE airfields SET the_geom = ST_GeomFromText('POINT(' || lon || ' ' || lat || ')', 4326);
