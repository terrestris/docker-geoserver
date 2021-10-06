CREATE INDEX airports_the_geom_gist
  ON airports
  USING gist
  (the_geom);
