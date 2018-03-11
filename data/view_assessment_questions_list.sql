create or replace view pd_dfsbenchmarking.view_assessment_questions_list as
select 
aqc.category_id,
ac.question_id,
regexp_replace(lower(aqc.category_name),E'\\s+','_','g') as tab_name,
regexp_replace(lower(ac.question_title),E'\\s+','_','g') as competency,
regexp_replace(lower(aqc.category_name),E'\\s+','_','g') || '_' || regexp_replace(lower(ac.question_title),E'\\s+','_','g') as combined_name,

aqc.category_name,
ac.question_title,
ac.formative_text,
ac.emerging_text,
ac.developed_text
from pd_dfsbenchmarking.assessment_question_categories aqc
inner join pd_dfsbenchmarking.assessment_questions ac on ac.category_id = aqc.category_id
order by aqc.sort_order,ac.sort_order