create or replace function pd_dfsbenchmarking.client_assessment_edit(
v_session_id varchar,
v_assessment_id int,
v_client_id int,
v_assessment_name varchar(75),
v_assessment_date date)
returns int
as $$
declare v_new_assessment_id int default null;
begin

	v_new_assessment_id := v_assessment_id;
	
	IF coalesce(v_assessment_id,-1) = -1 THEN
		insert into pd_dfsbenchmarking.assessments(client_id,assessment_name,assessment_date,created_by_user_id)
		select v_client_id,v_assessment_name,v_assessment_date,users.user_id
		from pd_dfsbenchmarking.users
		where users.session_id = v_session_id::uuid and 
					pd_dfsbenchmarking.user_has_client_access(v_client_id,pd_dfsbenchmarking.user_id_session_chain(v_session_id))
		on conflict do nothing;

	ELSE
	
		update pd_dfsbenchmarking.assessments set(assessment_name,assessment_date) = (v_assessment_name,v_assessment_date)
		where assessments.assessment_id = v_assessment_id and
			assessments.client_id = v_client_id and
			pd_dfsbenchmarking.user_has_client_access(assessments.client_id,pd_dfsbenchmarking.user_id_session_chain(v_session_id))
			and not exists(select * from pd_dfsbenchmarking.assessments ca2 
										 where ((ca2.assessment_name = v_assessment_name or ca2.assessment_date = v_assessment_date) 
											 and ca2.assessment_id <> v_assessment_id
											 and ca2.client_id = v_client_id));

  END IF;
	
	select assessment_id into v_new_assessment_id 
	from pd_dfsbenchmarking.assessments
	where client_id = v_client_id and assessment_name = v_assessment_name and assessment_date = v_assessment_date;
	
	return coalesce(v_new_assessment_id,v_assessment_id);

end; 
$$ LANGUAGE plpgsql;
