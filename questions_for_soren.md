1. My `view_assessment_questions_list` starts with `question_id` number 2. I'm assuming that's a bug?

2. I don't fully understand the use of -1 in, for example, the `db_edit_client_assessment` function. Can you explain?

3. In the test file, `db_edit_client_assessment` returns -1. When I then run `load_client_assessment(-1)`, I get an error:
```
Error: Requested assessment -1 not found!
```