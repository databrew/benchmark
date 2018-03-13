create or replace function pd_dfsbenchmarking.assessment_load(v_client_id int, v_assessment_id int, v_session_id varchar)
returns TABLE(category_id int, question_id int, tab_name varchar, competency varchar, combined_name varchar,
							category_name varchar, question_title varchar, formative_text text, emerging_text text, developed_text text,
							client_id int, assessment_id int, last_modified_time timestamp, last_modified_user_id int, last_modified_user_name varchar,
							score numeric, rationale text)
as $$
declare v_has_access boolean default false;
BEGIN

	-- Open questions:
	-- Is it better to fully load assessment, questions and responses, where available?  Or keep as-is and load these separately -- first the
	-- assessment and then the data and pair them internally?
	-- and if we load them separately, should the assessment template be reloaded each load_assessment() call?  Will take more bandwidth, but also
	-- keeps the groups together by consolidating assessment-related functionality
	-- Also unlikely users are going to be going up and back between multiple different assessments frequently cusing lots of loads and unloads
	-- and even if they do the bandwidth due to the questions is adding maybe partial second in incremental download time.  
	-- Internally takes about <0.25s to execute.

	select coalesce(
					 pd_dfsbenchmarking.user_has_client_access(
						 assessments.client_id,pd_dfsbenchmarking.user_id_session_chain(v_session_id)),false) into v_has_access
	from pd_dfsbenchmarking.assessments where assessments.assessment_id = v_assessment_id and assessments.client_id = v_client_id;
	
	return query
	select 
	vaql.category_id::int,
	vaql.question_id::int,
	vaql.tab_name::varchar,
	vaql.competency::varchar,
	vaql.combined_name::varchar,
	vaql.category_name::varchar,
	vaql.question_title::varchar,
	vaql.formative_text::text,
	vaql.emerging_text::text,
	vaql.developed_text::text,
	coalesce(vacd.client_id,v_client_id)::int,
	coalesce(vacd.assessment_id,v_assessment_id)::int,
	vacd.last_modified_time::timestamp,
	vacd.last_modified_user_id::int,
	vacd.last_modified_user_name::varchar,
	vacd.score::numeric,
	vacd.rationale::text
	from pd_dfsbenchmarking.view_assessment_questions_list vaql
	left join pd_dfsbenchmarking.view_assessments_current_data vacd on vacd.question_id = vaql.question_id
	where coalesce(vacd.assessment_id,v_assessment_id)=v_assessment_id and v_has_access = true;

END;
$$ language plpgsql;