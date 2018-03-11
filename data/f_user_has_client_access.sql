drop function if exists pd_dfsbenchmarking.user_has_client_access(int,int[]);
create or replace function pd_dfsbenchmarking.user_has_client_access(v_client_id int,v_user_id_chain int[]) returns boolean
as $$
declare v_has_access boolean default false;
begin
	select (ARRAY[created_by_user_id] <@ v_user_id_chain) into v_has_access
	from pd_dfsbenchmarking.clients where clients.client_id = v_client_id;

	return coalesce(v_has_access,false);
end;
$$ LANGUAGE plpgsql;