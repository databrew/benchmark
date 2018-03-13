# DFS benchmarking UI flow
source('global.R')
# 
# - User Loads page:
#   - Not much functionality exists.
# - Menus: "Home" and "About"
# - Home: has a simple login form prompt.   Perhaps some text information on what this app is, what it does.


# - User logs in:
#   - A new menu item appears: "Clients" and user auto-moves to the "Clients" tab screen
# - Clients: shows a table list of clients that are set in login and saved under LISTINGS$client_listing
# - Clients: shows an option or link "create new client"
# - "create new client" opens a pop-up form to fill-in relative client info.  Submit sends to db_edit_client with client_id=-1; refreshes table
# - Clients: a user can "select a client" - table is responsive to mouse clicks -- clicking on a row will "load" that client with a call to load_client() 


# - User selects a client:
#   - A new menu item appears, same as short_name of client and user auto-moves to the client's page
# - There are two collapsable panels
# 1. Contains the client's information.  User can edit it/save with a call to db_edit_client that will send client_id equal to selected client's client_id
# 2. Contains a list of all the client's assessments, obtained through LISTINGS$client_assessment_listing, which was populated with load_client()
#     - The 2nd panel also has a link "create new assessment" clicking will open a pop-up form that user can fill in relavent assessment info: name and date
#     - The table in the 2nd panel is responsive to mouse clicks.  Clicking on an assessment will call load_client_assessment()
#     - Can edit the assessments...maybe an edit button on right-hand side with an added column and pop-up editor


# - User selects an assessment
#     - A menu item with the name of the assessment appears under the client's name (indented?)
# - All the menu items of competencies appear under, as we're familiar with...  Goes through the assessment...


# - User closes an assessment
#     - Option to close assessment will save it and return to client menu and remove the menu items associated with the assessment


# - User closes a client
#     - Saves assessment if open; closes assessment; closes client


# - User selects a different client ... if a client is selected we might want to hide the client listing menu and make it reappear when client is closed

