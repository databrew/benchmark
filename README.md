# Mobile Banking Diagnostic Model Scoring Tool

A web application for benchmarking mobile banking competencies

# To-do

## Overall status

The Benchmark dashboard is close to being finished, with only minor pending changes. It's completely functional, though some rough edges may require further modification. Known "issues" are (i) that all slider changes activate the code to update the database, even though some slider changes are made by the app (ie, when a user changes an assessment and a previous value is loaded) rather than actively by the user, and (ii) because of the long processing time of the many database hits, the app can ocasionally go into a strange state in which a slider moves back and forth infinitely and only a tab change fixes the issues.

There is nothing particularly advanced about the code for this app, but it does have the pecuilarity of being almost all dynamically generated on the `server` side before being passed to the UI. The reason for this is because there were so many identically formatted inputs that it made more sense to write one function to generate some UI text (for each UI element) rather than to write thousands of lines of code, copy-pasting the identical format code for each element. This approach relies heavily on the use of `eval(parse())` in the UI, which wraps a call to a function which returns UI code. Examples of this are in `R/create_qualy` and `R/create_slider`.

## Tasks

- Minimize prominence of legends; add legend outside of specific charts.
- Ensure that sliders don't enter into back-and-forth infinit mode. 
- Ensure that only "active" changes to sliders are registered as saves in the database (ie, not changes to a slider which only occurred because someone logged in, etc.).


# Developers' guide

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

Once database is in shape, dump this project's schema with data:

```
pg_dump -d dev -n pd_dfsbenchmarking -f data/2018-03-14_clean.sql
```

- Restore the locally created dump from within psql
``` 
\i 'data/2018-03-14_clean.sql'
```

- Grant relevant privileges
```
GRANT ALL PRIVILEGES ON SCHEMA pd_dfsbenchmarking TO worldbank;
GRANT ALL PRIVILEGES ON SCHEMA public TO worldbank;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO worldbank;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA pd_dfsbenchmarking TO worldbank;
```