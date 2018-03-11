create or replace function pd_dfsbenchmarking.client_edit(
v_session_id varchar,
v_client_id int,
v_ifc_client_id int,
v_name varchar(75),
v_short_name varchar(15),
v_firm_type varchar(50),
v_address varchar(100),
v_city varchar(35),
v_country varchar(35))
returns int
as $$
declare v_new_client_id int default null;
begin

	v_new_client_id := v_client_id;
	
	IF coalesce(v_client_id,-1) = -1 THEN
		insert into pd_dfsbenchmarking.clients(ifc_client_id,"name",short_name,firm_type,address,city,country,created_by_user_id)
		select 
			v_ifc_client_id,v_name,v_short_name,v_firm_type,v_address,v_city,v_country,users.user_id
		from pd_dfsbenchmarking.users
		where users.session_id = v_session_id::uuid 
		on conflict do nothing 
		returning clients.client_id into v_new_client_id;
	ELSE
		update pd_dfsbenchmarking.clients set(ifc_client_id,"name",short_name,firm_type,address,city,country) = 
			(v_ifc_client_id,v_name,v_short_name,v_firm_type,v_address,v_city,v_country)
		where clients.client_id = v_client_id  -- where conflicting client_id matches and user has access to edit
			and pd_dfsbenchmarking.user_has_client_access(clients.client_id,pd_dfsbenchmarking.user_id_session_chain(v_session_id))
			and not exists(select * from pd_dfsbenchmarking.clients c2 where ((c2."name" = v_name or c2.short_name = v_short_name) and c2.client_id <> v_client_id))
		returning clients.client_id into v_new_client_id;
  END IF;
	
	return coalesce(v_new_client_id,v_client_id);

end; 
$$ LANGUAGE plpgsql;
