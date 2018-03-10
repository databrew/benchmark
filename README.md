# Mobile Banking Diagnostic Model Scoring Tool

A web application for benchmarking mobile banking competencies

## Setting up database

In `dev`, create the applicable schemas:

```
psql dev
CREATE SCHEMA pd_dfsbenchmarking
```

## Get the db on AWS

- Connect to the AWS databrew db:

```
psql --host=databrewdb.cfejspjhdciw.us-east-2.rds.amazonaws.com --port=8080 --username=worldbank --dbname=dev 
```

- Create the relevant schemas

```
CREATE SCHEMA pd_dfsbenchmarking
```

- Restore the locally created dump from within psql
``` 
\i 'data/2018-03-10 - pd_dfsbenchmarking.sql'
```

- Grant relevant privileges
```
GRANT ALL PRIVILEGES ON SCHEMA pd_dfsbenchmarking TO worldbank;
GRANT ALL PRIVILEGES ON SCHEMA public TO worldbank;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO worldbank;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA pd_dfsbenchmarking TO worldbank;
```