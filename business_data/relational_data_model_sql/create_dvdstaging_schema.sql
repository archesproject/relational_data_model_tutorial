CREATE SCHEMA dvdstaging;

COMMENT ON SCHEMA dvdstaging IS NULL;

ALTER SCHEMA dvdstaging OWNER TO postgres;

GRANT USAGE ON SCHEMA dvdstaging TO postgres WITH GRANT OPTION;
GRANT CREATE ON SCHEMA dvdstaging TO postgres WITH GRANT OPTION;


--
-- Type: TABLE ; Name: actor; Owner: postgres
--

CREATE TABLE dvdstaging.actor (
    actor_id integer NOT NULL,
    first_name character varying(45) NOT NULL,
    last_name character varying(45) NOT NULL,
    last_update timestamp without time zone NOT NULL,
    actorid uuid
);


ALTER TABLE dvdstaging.actor ALTER last_update SET DEFAULT now();

ALTER TABLE dvdstaging.actor ADD CONSTRAINT actor_pkey
  PRIMARY KEY (actor_id);

CREATE INDEX idx_actor_last_name ON dvdstaging.actor USING btree (last_name);

ALTER TABLE dvdstaging.actor OWNER TO postgres;


--
-- Type: TABLE ; Name: film; Owner: postgres
--

CREATE TABLE dvdstaging.film (
    film_id integer NOT NULL,
    title character varying(255) NOT NULL,
    description text,
    release_year text,
    language_id smallint NOT NULL,
    rental_duration smallint NOT NULL,
    rental_rate numeric(4,2) NOT NULL,
    length smallint,
    replacement_cost numeric(5,2) NOT NULL,
    rating text,
    last_update timestamp without time zone NOT NULL,
    special_features text[],
    fulltext tsvector NOT NULL,
    filmid uuid,
    geometry json
);


ALTER TABLE dvdstaging.film ALTER rental_duration SET DEFAULT 3;
ALTER TABLE dvdstaging.film ALTER rental_rate SET DEFAULT 4.99;
ALTER TABLE dvdstaging.film ALTER replacement_cost SET DEFAULT 19.99;
ALTER TABLE dvdstaging.film ALTER last_update SET DEFAULT now();

ALTER TABLE dvdstaging.film ADD CONSTRAINT film_pkey
  PRIMARY KEY (film_id);

CREATE INDEX film_fulltext_idx ON dvdstaging.film USING gist (fulltext);
CREATE INDEX idx_fk_language_id ON dvdstaging.film USING btree (language_id);
CREATE INDEX idx_title ON dvdstaging.film USING btree (title);

CREATE TRIGGER film_fulltext_trigger BEFORE INSERT OR UPDATE ON dvdstaging.film FOR EACH ROW EXECUTE FUNCTION tsvector_update_trigger('fulltext', 'pg_catalog.english', 'title', 'description');

ALTER TABLE dvdstaging.film OWNER TO postgres;


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

