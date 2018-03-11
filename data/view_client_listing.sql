drop view if exists pd_dfsbenchmarking.view_client_listing;
create or replace view pd_dfsbenchmarking.view_client_listing
as
select 
clients.created_by_user_id,
clients.client_id,
clients.ifc_client_id,
clients."name",
clients.short_name,
clients.firm_type,
clients.address,
clients.city,
clients.country,
users."name" as created_by,
count(distinct assessments.assessment_id) as assessments,
coalesce(max(assessments.assessment_date)::varchar,'Never') as last_assessment
from pd_dfsbenchmarking.clients
inner join pd_dfsbenchmarking.users on users.user_id = clients.created_by_user_id
left join pd_dfsbenchmarking.assessments on assessments.client_id = clients.client_id
group by
clients.created_by_user_id,
clients.client_id,
clients.ifc_client_id,
clients."name",
clients.short_name,
clients.firm_type,
clients.address,
clients.city,
clients.country,
users."name"
order by clients.created_time desc;