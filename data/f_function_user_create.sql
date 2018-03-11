create or replace function pd_dfsbenchmarking.user_create(
v_username varchar(15), 
v_password varchar(35), 
v_name varchar(50), 
v_email varchar(50),
v_upi int4) 
returns int
as $$
declare v_user_id int4;
BEGIN

	insert into pd_dfsbenchmarking.users("username","password","name","email",upi,can_login,last_login)
	values(lower(trim(v_username)),
				 CRYPT(v_password, GEN_SALT('md5')),
				 v_name,
				 v_email,
				 v_upi,
				 true,
				 NULL)
	returning user_id into v_user_id;
	
	return(v_user_id);

END; 
$$ LANGUAGE plpgsql;