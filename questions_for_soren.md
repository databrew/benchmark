1. My `view_assessment_questions_list` starts with `question_id` number 2. I'm assuming that's a bug?

2. I don't fully understand the use of -1 in, for example, the `db_edit_client_assessment` function. Can you explain?

3. In the test file, `db_edit_client_assessment` returns -1. When I then run `load_client_assessment(-1)`, I get an error:
```
Error: Requested assessment -1 not found!
```

4. Also in relation to this -1 issue, what is the correct way for me to retrieve data for a given assessment, so as to populate the ui? It doesn't appear to me that this is stored in the `SESSION` object - should I just query the db directly?