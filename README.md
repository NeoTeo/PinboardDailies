PinboardDailies
===============

An OS X command line app to fetch your bookmarks tagged "Daily" and format them for Alfred's Script Filter.
PinboardDailies fetches the bookmarks tagged with daily from api.pinboard.in and returns the results 
in the xml format that Alfred can parse into a results list. 

Although the utility defaults to your dailies it does take a tag argument that allows you to fetch whatever tag you want.

The usage is:

./PinboardDailies tag: "tagName" token: "Your Pinboard token"

In Alfred's Workflows you simply add a Script Filter with the above (using your own credentials of course) 
and flow the output into an Open URL Action.