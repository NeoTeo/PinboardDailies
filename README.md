PinboardDailies
===============

An OS X command line app to fetch your bookmarks (defaults to those tagged "daily") and format them for Alfred's Script Filter.
PinboardDailies fetches the bookmarks tagged with daily from api.pinboard.in and returns the results 
in the xml format that Alfred can parse into a results list. 

Although the utility defaults to your dailies it will take any tag as an argument.

## Usage

./PinboardDailies <--token="Your Pinboard token"> [--tag="Tag name"] [--mode=fetch|display|uncached] 

which will output any found bookmarks in an xml format that Alfred's script filter understands.

## To use with Alfred
In Alfred's Workflows you add a Script Filter with the above (using your own credentials of course) 
and flow the output into an Open URL Action.


Eg. the following script will do two things:
* Fetch bookmarks with the "daily" tag and cache them without displaying any output.
* Output the xml for any previously cached bookmarks with the "daily" tag. 

This is done in two independent stages to ensure that there is no delay in displaying any existing bookmarks.

```
nohup /usr/local/bin/PinboardDailies --token=username:tokenstring --tag=daily --mode=fetch &> /dev/null &

/usr/local/bin/PinboardDailies --token=username:tokenstring --tag=daily --mode=display
```

This script will disregard any existing cache and will fetch and display the results as soon as possible. This does mean there can be a noticable delay as the query is resolved.

```
/usr/local/bin/PinboardDailies --token=username:tokenstring--tag={query} --mode=uncached
```
The scripts can either be called from an Alfred workflow or pasted in like so:
![](alfredScript.jpg?raw=true "Screenshot of Alfred Script.")

You should end up with something like this:

![](ShowPD.gif?raw=true "Screenshot of Alfred showing Pinboard Dailies.")
![](ShowPB.gif?raw=true "Screenshot of Alfred showing Pinboard tag search.")
