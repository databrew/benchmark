What follows is an overall update, some details, and questions.

*UPDATE*
- _Overall_: Lots of progress, but also lots of issues.
- Much of the friction / slow-downs at this point is my lack of full understanding of some of the database functionality, as well as some of the oddities of combining the heavy use of the `SESSION` object with shiny's reactive framework.
- I've pushed the most recent stuff.
- As I see it, next steps are (i) Soren helps me with below questions, (ii) I figure out how to get `SESSION` to play nicely with shiny, or re-do much of the db functions in a more reactive manner (ie, no modification of global objects, etc.), (iii) simultaneously, we make changes to UI (input from both Soren and Oleksiy).
- Timing: As of this message, I haven't slept for about 40 hours - so I'm out of the pocket until Tuesday morning.

*DETAILS*
- Log-in is working with pg crypto
- A "Settings" tab is where all the data management lives.
- UI has functionality so that user can either (a) select an existant client/assessment, (b) create a new assessment, or (c) create a new client
- Of the above, (a) is working half-way - picking the client works, but I'm unable to make the assessment drop-down reactive (see below questions), (b) is only working on the UI side, not interacting reactively with database (see below questions), and (c) is working half-way - one can create a client, and this updates the database, but does not update the UI.
- One of the reasons that so much of this is "half-way done" is the oddities of trying to get the `SESSION` object to play nicely with the "reactive" nature of shiny. What works in a static sript (ie, `testing.R`) does not work as predictably in a reactive environment, because each change has to be triggered, and the scoping is all within reactive environments (see questions below).
- Scores from slider inputs are saved. Upon session load, sliders are updated.
- The above isn't perfect. Due to issues with getting "current assessment" from the db, their is no differentiation between different assessments.
- Another imperfection of restoring saved inputs is the UI elements, which aren't updated automatically (in my court).



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

