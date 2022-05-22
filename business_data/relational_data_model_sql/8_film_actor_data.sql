-- raise notice 'now creating actor.instances....';
INSERT INTO actor.instances(
    resourceinstanceid
    -- transactionid
) select
    distinct actorid
    -- transaction_id
from dvdstaging.actor;

-- raise notice 'now creating film.instances....';
INSERT INTO film.instances(
    resourceinstanceid
    -- transactionid
) select
    distinct filmid
    -- transaction_id
from dvdstaging.film;

-- raise notice 'now creating actor.names....';
INSERT INTO actor.name (
    resourceinstanceid,
    first_name,
    last_name
) select 
    actorid::uuid,
    first_name,
    last_name
from dvdstaging.actor;


----------------------film--------------------------------------

-- raise notice 'now creating film info...';
WITH movie_ratings (valueid, value) as (
    select valueid, value
    from __arches_get_labels_for_concept_node(
        __arches_get_node_id_for_view_column(
            'film',
            'information',
            'rating'
        )
    )
)

INSERT INTO film.information (
    resourceinstanceid,
    length,
    year,
    description,
    title,
    rating,
    geometry    
) select 
    filmid::uuid,
    length,
    to_date(release_year, 'YYYY'),
    description,
    title,
    (
        select valueid
        from movie_ratings
        where value = rating
        limit 1
    ),
    ST_GeomFromGeoJSON(geometry->'features'->0->'geometry')
from dvdstaging.film;

-- raise notice 'now creating film <-> actor data...';
INSERT INTO film.actor (
    resourceinstanceid,
    actor 
) select 
    filmid::uuid,
    jsonb_build_array(
    jsonb_build_object(
        'resourceId', actorid,
        'ontologyProperty', 'https://linked.art/ns/terms/digitally_shows',
        'resourceXresourceId', '',
        'inverseOntologyProperty', 'https://linked.art/ns/terms/digitally_shown_by'
    )
)
from dvdstaging.film_actor;