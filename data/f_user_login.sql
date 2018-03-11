drop function if exists pd_dfsbenchmarking.user_login;
create or replace function pd_dfsbenchmarking.user_login(
v_username varchar(15), 
v_password varchar(35)) 
returns table(user_id int, "name" varchar, session_id varchar)
as $$
declare v_user_id int4 default null;
declare v_name varchar default null;
declare v_session_id uuid default null;
BEGIN

	select users.user_id,users."name" into v_user_id,v_name
	from pd_dfsbenchmarking.users
	where lower(username) = lower(trim(v_username)) and
				"password" = CRYPT(v_password,"password");
	
	update pd_dfsbenchmarking.users
	set last_login = now(), session_id = gen_random_uuid()
	where v_user_id is not null and users.user_id = v_user_id
	returning users.session_id into v_session_id;
	
	return query select (coalesce(v_user_id,-1)) as user_id, v_name as "name", v_session_id::varchar as session_id;

END; 
$$ LANGUAGE plpgsql;