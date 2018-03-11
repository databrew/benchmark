drop function if exists pd_dfsbenchmarking.user_id_session_chain(varchar);
create or replace function pd_dfsbenchmarking.user_id_session_chain(v_session_id varchar) RETURNS int[]
as $$
declare user_id_chain int[] default null;
BEGIN
--This function doesn't do much now
--To Do: create user groups that allow nesting so managers or supervisors can see clients/assessments created under them
--and admins can see all created
	select array_agg(distinct user_id) into user_id_chain from pd_dfsbenchmarking.users where session_id = v_session_id::uuid;
	return user_id_chain;
END;
$$ LANGUAGE plpgsql;