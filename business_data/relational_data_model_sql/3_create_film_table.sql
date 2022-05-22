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

