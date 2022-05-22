COPY dvdstaging.actor FROM '../relational_data_model_csvs/relational_data_model_csvs/actors.csv' DELIMITER ',' CSV HEADER;

COPY dvdstaging.film FROM '../relational_data_model_csvs/films.csv' DELIMITER ',' CSV HEADER;

COPY dvdstaging.film_actor FROM '../relational_data_model_csvs/film_actor.csv' DELIMITER ',' CSV HEADER;
