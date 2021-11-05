CREATE INDEX airfields_the_geom_gist
  ON airfields
  USING gist
  (the_geom);
