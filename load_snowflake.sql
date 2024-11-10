CREATE DATABASE spotify_db;


CREATE OR REPLACE storage integration s3_init
    TYPE = EXTERNAL_STAGE
    STORAGE_PROVIDER = S3
    ENABLED = TRUE
    STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::481665115384:role/spotify-spark-snowflake-role'
    STORAGE_ALLOWED_LOCATIONS = ('s3://spotify-etl-data-pipeline-mitesh')
    COMMENT = 'Creating Connection to S3';

    
DESC integration s3_init;


CREATE OR REPLACE FILE FORMAT csv_fileformat 
    TYPE = CSV
    FIELD_DELIMITER = ','
    RECORD_DELIMITER = '\n'
    SKIP_HEADER = 1
    NULL_IF = ('NULL', 'null')
    EMPTY_FIELD_AS_NULL = TRUE
    FIELD_OPTIONALLY_ENCLOSED_BY = '0x22';



CREATE OR REPLACE stage spotify_stage 
    URL = 's3://spotify-etl-data-pipeline-mitesh/transformed_data/'
    STORAGE_INTEGRATION = s3_init
    FILE_FORMAT = csv_fileformat;

    
LIST @spotify_stage;
LIST @spotify_stage/album;
LIST @spotify_stage/artist;
LIST @spotify_stage/songs;


CREATE OR REPLACE TABLE tbl_albums(
    album_id STRING,
    name STRING,
    release_date DATE,
    total_tracks INT,
    url STRING
);

CREATE OR REPLACE TABLE tbl_artists(
    artist_id STRING,
    name STRING,
    url STRING
);

CREATE OR REPLACE TABLE tbl_songs(
    song_id STRING,
    song_name STRING,
    duration_ms INT,
    url STRING,
    popularity INT, 
    song_added DATE,
    album_id STRING,
    artist_id STRING
);

// songs
COPY INTO tbl_songs
FROM @spotify_stage/songs/songs_transformed_2024-11-10/run-1731233627672-part-r-00007;


SELECT * FROM tbl_songs;

// album
COPY INTO tbl_albums
FROM @spotify_stage/album/album_transformed_2024-11-10/run-1731233614107-part-r-00000;


SELECT * FROM tbl_albums;


// artists 
COPY INTO tbl_artists
FROM @spotify_stage/artist/artist_transformed_2024-11-10/run-1731233625688-part-r-00001;


SELECT * FROM tbl_artists;



-- creating snowpipe

CREATE OR REPLACE SCHEMA pipe;


CREATE OR REPLACE PIPE spotify_db.pipe.tbl_songs_pipe
auto_ingest = TRUE
AS 
COPY INTO spotify_db.public.tbl_songs
FROM @spotify_db.public.spotify_stage/songs;

CREATE OR REPLACE PIPE spotify_db.pipe.tbl_artists_pipe
auto_ingest = TRUE
AS 
COPY INTO spotify_db.public.tbl_artists
FROM @spotify_db.public.spotify_stage/artist;

CREATE OR REPLACE PIPE spotify_db.pipe.tbl_albums_pipe
auto_ingest = TRUE
AS 
COPY INTO spotify_db.public.tbl_albums
FROM @spotify_db.public.spotify_stage/album;


DESC PIPE pipe.tbl_songs_pipe;
DESC PIPE pipe.tbl_artists_pipe;
DESC PIPE pipe.tbl_albums_pipe;


SELECT count(*) FROM tbl_songs;
SELECT count(*) FROM tbl_artists;
SELECT count(*) FROM tbl_albums;




    
