--
-- Type: TABLE ; Name: film_actor; Owner: postgres
--

CREATE TABLE dvdstaging.film_actor (
    actor_id smallint NOT NULL,
    film_id smallint NOT NULL,
    last_update timestamp without time zone NOT NULL,
    actorid uuid,
    filmid uuid
);


ALTER TABLE dvdstaging.film_actor ALTER last_update SET DEFAULT now();

ALTER TABLE dvdstaging.film_actor ADD CONSTRAINT film_actor_pkey
  PRIMARY KEY (actor_id, film_id);

CREATE INDEX idx_fk_film_id ON dvdstaging.film_actor USING btree (film_id);

ALTER TABLE dvdstaging.film_actor OWNER TO postgres;

