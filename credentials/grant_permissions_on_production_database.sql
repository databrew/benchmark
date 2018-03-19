GRANT ALL ON SCHEMA pd_dfsbenchmarking TO "ARLTeam", "Applications";
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA pd_dfsbenchmarking TO "Applications","ARLTeam";
GRANT SELECT ON pd_dfsbenchmarking.view_assessment_questions_list TO "Applications","ARLTeam";
GRANT SELECT ON pd_dfsbenchmarking.view_assessments_current_data TO "Applications","ARLTeam";
GRANT SELECT ON pd_dfsbenchmarking.view_client_listing TO "Applications","ARLTeam";
GRANT SELECT ON pd_dfsbenchmarking.view_client_assessment_listing TO "Applications","ARLTeam";

