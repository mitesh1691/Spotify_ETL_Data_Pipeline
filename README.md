
# Spotify ETL Data Pipeline

This project is an end-to-end data pipeline designed to extract, transform, and load (ETL) data from Spotify playlists using the Spotify API, AWS services (S3, Lambda, Glue), and Snowflake. The pipeline automates data collection, transformation, and storage, creating a database optimized for analytical queries.

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Components](#components)
  - [Spotify API](#spotify-api)
  - [AWS S3](#aws-s3)
  - [AWS Lambda](#aws-lambda)
  - [AWS Glue](#aws-glue)
  - [Snowflake](#snowflake)
- [Setup and Configuration](#setup-and-configuration)
- [Detailed Walkthrough](#detailed-walkthrough)
  - [1. Extraction from Spotify API](#1-extraction-from-spotify-api)
  - [2. Transformation in AWS Glue](#2-transformation-in-aws-glue)
  - [3. Loading into Snowflake](#3-loading-into-snowflake)
- [Scheduling and Automation](#scheduling-and-automation)
- [Future Enhancements](#future-enhancements)

---

## Overview

This ETL pipeline project extracts song, artist, and album data from Spotify playlists, processes it, and stores it for analysis. The pipeline is designed to automate the entire ETL process, from data extraction to storage, ensuring that new data is regularly and reliably available for analysis.

## Architecture

![Spotify ETL Pipeline Architecture](/images/Spotify_ETL_pipeline_architectu.jpg)

### Workflow Summary

1. **Extract** data from Spotify playlists.
2. **Store raw data** in an S3 bucket.
3. **Transform** raw data using AWS Glue into structured formats.
4. **Load** the transformed data into Snowflake tables.
5. Use **Snowpipe** to auto-ingest transformed data into Snowflake for real-time availability.

## Components

### Spotify API

The Spotify API allows for programmatically accessing Spotify’s song, album, and artist data. In this pipeline:
- **Data Extraction**: Extracts track details from a specific Spotify playlist.
- **Data Structure**: Retrieves JSON data of tracks, albums, and artist details.

### AWS S3

Amazon S3 acts as the central data storage layer in the pipeline:
- **Raw Data Storage**: Stores the unprocessed JSON data from Spotify.
- **Processed Data Storage**: Stores the cleaned and transformed data for Snowflake loading.
  
### AWS Lambda

AWS Lambda functions handle the extraction process:
- **Spotify API Data Retrieval**: Lambda is configured to access the Spotify API and store JSON data directly to S3.
- **S3 Trigger**: Every new data file upload to S3 triggers the transformation stage using Glue.

### AWS Glue

AWS Glue processes and transforms data stored in S3:
- **Glue Job**: Spark job that performs data transformation, such as flattening nested data, formatting dates, and cleaning values.
- **Glue DynamicFrames**: These are converted to Spark DataFrames for flexible transformations.
- **Final Output**: Transformed data is saved as CSV files back to S3 in a structured format.

### Snowflake

Snowflake stores and organizes the processed data for efficient querying and analytics:
- **External Stage Integration**: Connects Snowflake to the S3 bucket containing transformed data.
- **File Format Specification**: Configures how Snowflake should interpret and load CSV files.
- **Snowpipe**: Automated data loading from S3 to Snowflake as new data arrives.

## Setup and Configuration

### Prerequisites

- **Spotify Developer Account**: Required to access Spotify API and create API credentials.
- **AWS Account**: Required to set up S3, Lambda, Glue, and IAM roles.
- **Snowflake Account**: Required to create the database, tables, and Snowpipe.
  
### AWS IAM Roles

Define IAM roles with permissions to allow Glue, Lambda, and Snowflake integration:
- **Lambda IAM Role**: Access to S3 for reading/writing raw data.
- **Glue IAM Role**: Access to S3 for reading/writing processed data.
- **Snowflake IAM Role**: Access to S3 for external stage integration.

### Environment Variables

- Set up environment variables in AWS Lambda for Spotify credentials:
  - `client_id`: Spotify API client ID.
  - `client_secret`: Spotify API client secret.

## Detailed Walkthrough

### 1. Extraction from Spotify API

Lambda function pulls data from Spotify:
```python
# Extracts data from Spotify API
data = sp.playlist_tracks(playlist_URI)
```
The Lambda function runs with each trigger, fetching the latest playlist tracks and saving raw data as a JSON file in S3.

**Lambda Function for Extracting Data Triggers using Cloudwatch Event:**
![Lambda function](/images/extract_lambda_function.png)

### 2. Transformation in AWS Glue

AWS Glue transforms data with the following steps:
- **Data Loading**: Reads raw JSON files from S3 as DynamicFrames.
- **Data Processing**: The transformation functions `process_albums`, `process_artists`, and `process_songs` create separate DataFrames for albums, artists, and songs.
- **Writing Transformed Data**: Saves transformed CSV files to S3 in structured directories.

Example of album data processing in Glue:
```python
def process_albums(df):
    return df.select(
        col("items.track.album.id").alias("album_id"),
        col("items.track.album.name").alias("album_name"),
        col("items.track.album.release_date").alias("release_date"),
        col("items.track.album.total_tracks").alias("total_tracks"),
        col("items.track.album.external_urls.spotify").alias("url")
    ).drop_duplicates(["album_id"])
```

**Running Glue Transformation Jobs:**
![Running glue transformation jobs](/images/glue_job_run.png)

### 3. Loading into Snowflake

Snowflake loads data from S3, leveraging stages, file formats, and tables:
- **File Format**: Specifies CSV configuration in Snowflake.
- **External Stage**: Links to the S3 bucket containing transformed CSVs.
- **COPY INTO Command**: Loads data into tables using Snowpipe for real-time ingestion.

Example of creating Snowflake table:
```sql
CREATE TABLE tbl_albums(
    album_id STRING,
    name STRING,
    release_date DATE,
    total_tracks INT,
    url STRING
);
```

### Snowpipe Automation

Snowpipe ensures that each new data file arriving in S3 is loaded automatically into Snowflake tables for immediate availability.

**Data Loaded into Snowflake using Snowpipe:**
![Loaded data into snowflake using snowpipe](/images/loaded_data_snowflake.png)

---

## Scheduling and Automation

- **Lambda Function**: Runs on a trigger to extract new data at scheduled intervals.
- **AWS Glue Job Scheduling**: Configured to run at specific intervals to transform newly extracted data.
- **Snowpipe**: Provides automated loading into Snowflake as soon as processed files appear in S3.

## Future Enhancements

- **Error Handling and Logging**: Improve monitoring for each component for better pipeline reliability.
- **Expanded Data Sources**: Extend the pipeline to process other Spotify data, like user listening history.
- **Advanced Transformations**: Implement additional data transformations based on specific analysis needs.
