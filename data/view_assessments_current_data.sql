drop view  pd_dfsbenchmarking.view_assessments_current_data;
create or replace view pd_dfsbenchmarking.view_assessments_current_data as
select distinct on (asm.client_id,asm.assessment_id,ad.question_id)
asm.client_id,
asm.assessment_id,
ad.question_id,
ad.entry_time as last_modified_time,
ad.entry_user_id as last_modified_user_id,
us."name" as last_modified_user_name,
ad.score,
ad.rationale
from pd_dfsbenchmarking.assessments asm
inner join pd_dfsbenchmarking.assessment_data ad on ad.assessment_id = asm.assessment_id
left join pd_dfsbenchmarking.users us on us.user_id = ad.entry_user_id
order by asm.client_id,
asm.assessment_id,
ad.question_id,
ad.entry_time desc