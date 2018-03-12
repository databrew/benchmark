What follows is an update and questions.

*UPDATE*


*QUESTIONS*

1. I'm unable to get the `assessment_id` field to update in the SESSION object. This is likely because I don't really understand how `db_edit_client_assessment` works, what the expected argument meanings are, etc. After I run either of the following (a and b), `SESSION$client_info$current_assessment_id` is always NA. 

_a_
```
updated_assessment_id <- db_edit_client_assessment(24,data.frame(client_id=get_current_client_id(),assessment_name="New Assessment",assessment_date=today(),stringsAsFactors=F))
```

_b_
```
updated_assessment_id <- db_edit_client_assessment(-1,data.frame(client_id=get_current_client_id(),assessment_name="New Assessment",assessment_date=today(),stringsAsFactors=F))
```

Because of this issue, the menu in which one chooses an assessment (based on the client), and the data being stored for that particular assessment isn't working properly.

2. I'm struggling with creating a new assessment. I take 1 text input in the UI (let's call this `new_name`). I then run it through:

```
updated_assessment_id <- 
      db_edit_client_assessment(-1,
                                data.frame(client_id=<current client id>,
                                           assessment_name=new_name,
                                           assessment_date=<today's date>,
                                           stringsAsFactors=F))
``` 
This yields the below message:
```
Error: Requested assessment -1 not found!
```

What am I doing wrong here? My understanding is that the first argument of the `db_edit_client_assessment` should be -1 if I'm trying to create a new assessment. But running the above both renders an error message and apparently has no effect on the database (ie, no new assessment is created).

3. In the `testing.R` script, you wrote this comment: "#User decides to edit the client, change the ifc_client_id by 1". What is the reason for this?

4. Am I correct that `db_edit_client` does not update the `SESSION` object? That is, if someone creates a new client, the `SESSION` object (which I'm using to generate the drop-down of clients to choose from) won't be updated, meaning that I should hard-code an update into the SESSION object on the UI side? Or is this something you can handle. I made an attempt at modifying `db_edit_client`, but failed to update `SESSION` with the new client...

5. My understanding is that `db_edit_client` serves both to modify an existing client or create a brand new one. We don't have an equivalent function for modifying/creating users, right (ie, `db_edit_user`), right? Will you create something like this? 