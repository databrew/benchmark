create or replace function pd_dfsbenchmarking.assessments_data_save(v_session_id varchar) returns int
as $$
DECLARE i_count int default 0;
BEGIN

  create temp table _inserts(u_assessment_id int,u_question_id int,u_entry_time timestamp);
	create index if not exists _inserts_index ON _inserts USING btree (u_assessment_id,u_question_id,u_entry_time);
	
	with data_uploads as
	(
		select assessment_id,question_id,last_modified_time as entry_time,last_modified_user_id as entry_user_id,score,rationale
		from public._pd_dfsbenchmarking_save_client_assessment_data
		where pd_dfsbenchmarking.user_has_client_access(client_id,pd_dfsbenchmarking.user_id_session_chain( v_session_id ))
	),
	data_inserts as
	(
		insert into pd_dfsbenchmarking.assessment_data(assessment_id,question_id,entry_time,entry_user_id,score,rationale)
		select assessment_id,question_id,entry_time,entry_user_id,score,rationale
		from data_uploads
		on conflict(assessment_id,question_id,entry_time) do update set score=data_uploads.score,rationale=data_uploads.rationale
		returning assessment_id,question_id,entry_time
	)
	insert into _inserts(u_assessment_id,u_question_id,u_entry_time)
	select assessment_id,question_id,entry_time
	from data_inserts;
	
	delete from public._pd_dfsbenchmarking_save_client_assessment_data
	where exists(select * from _inserts where u_assessment_id = assessment_id and u_question_id = question_id and u_entry_time = last_modified_time);
	
	select count(*) into i_count from _inserts;
	
	drop table _inserts;
	
	return i_count;

END; 
$$ LANGUAGE plpgsql;