GRANT ALL ON SCHEMA pd_dfsbenchmarking TO "ARLTeam", "Applications";
ALTER DEFAULT PRIVILEGES IN SCHEMA pd_dfsbenchmarking GRANT ALL ON TABLES TO "ARLTeam", "Applications";
ALTER DEFAULT PRIVILEGES IN SCHEMA pd_dfsbenchmarking GRANT ALL ON SEQUENCES TO "ARLTeam", "Applications";
ALTER DEFAULT PRIVILEGES IN SCHEMA pd_dfsbenchmarking GRANT ALL ON FUNCTIONS TO "ARLTeam", "Applications";
GRANT ALL ON ALL TABLES IN SCHEMA pd_dfsbenchmarking TO "Applications","ARLTeam";
GRANT USAGE, UPDATE, SELECT ON ALL SEQUENCES IN SCHEMA pd_dfsbenchmarking TO "Applications","ARLTeam";
GRANT ALL ON ALL FUNCTIONS IN SCHEMA pd_dfsbenchmarking TO "Applications","ARLTeam";
CREATE EXTENSION pgcrypto;