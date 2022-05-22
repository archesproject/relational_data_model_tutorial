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

