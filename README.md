# Welcome to the Arches Relational Data Model Tutorial!

This tutorial aims to familiarize you with the basics of the relational data model for loading data into Arches.

Please see the [project page](http://archesproject.org/) for more information on the Arches project.


# Using this tutorial

## 1.) Setup project and load models and reference data

1.) Create a new arches project using the `arches-project create` command. For the purposes of this tutorial we will use the project name new_project

2.) Clone this package repository into `new_project/new_project`

3.) In order to exercise the data load capabilities of the relational data model you'll need to load this packages models and reference data. Use the 
    
    python manage.py packages -o load_package -s new_project/relational_data_model_tutorial -db -y
    
command to load the components to your new_project.

You can ignore the following errors:


    arches.manage.commands.packages WARNING Invalid syntax in package_config.json. Please inspect and then re-run command
	arches.management.commands.package WARNING Expecting value: line 1 column 1 (char 0
        

4.) At this point you can run the following command to spin up the django dev server: 

    python manage.py run_server


## 2.) Create the staging schema and stage the example data

Run these commands from `new_project/new_project/relational_data_model_tutorial/business_data/relational_data_model_sql`. **You may have to modify them with your database, host and username.**
### Create staging schema

This command creates a staging schema for our examaple data.

        
    psql -d new_project -h localhost -U postgres -f create_dvdstaging_schema.sql
        

### Stage example data

This command populates our staging schema with our example data.


    psql -d new_project -h localhost -U postgres \
    -c "\copy dvdstaging.actor FROM '../relational_data_model_csvs/actors.csv' WITH (FORMAT CSV, header)" \
    -c "\copy dvdstaging.film FROM '../relational_data_model_csvs/films.csv' WITH (FORMAT CSV, header)"  \
    -c "\copy dvdstaging.film_actor FROM '../relational_data_model_csvs/film_actor.csv' WITH (FORMAT CSV, header)"


## 3.) Create relational data model schema

At this point it makes the most sense to switch to a sql client such as pgadmin to run the following commands.

Run the following sql command to create a relational data model schema from all of the active graphs in the new_project database (except system settings).


    select __arches_create_resource_model_views(graphid) \
    from graphs \
    where isresource = true \
    and isactive = true \
    and name != 'Arches System Settings';"


## 4.) Create Actor and Film Resource Instances in the relational data model

Before adding any attributes to our resources we must create the resource instances themselves. We create resource instances in the relational data model by populating the `instances` view in the schema of the model we would like to create instances for.
In this case we will be creating instances for both actors and films using the resourceintsanceid from our staging schema as the Arches resource instance id. In this tutorial those already happen to be UUIDs.

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

## 5.) Add a name for each Actor instance

Now that we have resource instances we can begin adding attributes to those instances. 

In Arches attributes are stored in 'nodes', which are organized into 'nodegroups'.
The relational data model creates a schema for each model, a view for each nodegroup in that model, and columns for each node that collects data in that nodegroup. Take the following example for a name nodegroup with a node for first and last name.
    

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

After running this sql you will have populated the string datatype nodes for first and last name in the actor.names view. 
    
At this point, if you wish, you can return to your command line and reindex your database to view the changes you have made in Arches.

    (env) python manage.py es reindex_database

## 6.) Add multiple attributes for each Film instance

Now that you recognize the pattern for adding instances and attributes to the relational data model let's try something more complex. 
    
In the following example we will add multiple attributes to the films.information nodegroup. We will be mixing datatypes so you can see the type of data the relational data model expects and how to craft that data.

First, because we are creating data for a concept datatype node (which in Arches requires you to use a labelid) we need to lookup the correct labelid for the given source data's label. 

The 'with' statement below creates a temporary lableid lookup, using two customized functions `__arches_get_labels_for_concept_node` and `__arches_get_node_id_for_view_column`. This lookup is then used below to select the correct labelid for an incoming rating from our staging schema.

The date too must be in the correct format for import into arches in this case we must transform the data from our staging schema to a valid year represented with in the YYYY format.

Finally, we must also transform our source geometry from our staging format to geojson. To do this we utilize postgres json selectors and postgis functions.


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

After running this sql you should have populated many attributes for each film instance in the relational data model.

To see these changes in Arches you can return to your command line and reindex your database to view the changes you have made in Arches.

    (env) python manage.py es reindex_database

## 7.) Adding related resource data

The final datatype we will cover in this tutorial will be related resources. Related resources are imported via the relational data model as json. The following sql uses standard postgres json manipulation to create the resource_x_resource object.

Here we have an insert statement to the film.actor view which represents the Actor nodegroup within the Film data model. resourceinstanceid in the insert statement corresponds to the film instance the related actor node belongs to and the resourceId 
    property within the resource_x_resource object corresponds to the actor that we would like to relate to that film instance.

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


To see these changes in Arches you can return to your command line and reindex your database to view the changes you have made in Arches.

    (env) python manage.py es reindex_database

Congratulations! You've now completed the relational data model tutorial. For more information on
the commands available in the relation data model schema check the [Arches Documentation](https://arches.readthedocs.io/en/latest/).
