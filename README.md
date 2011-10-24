cronviz -- visualize your cron jobs
=================================


## DESCRIPTION

Something's causing performance issues on the application server between 1 and 4 AM, and the cron jobs seem the likeliest culprit.

Problem is, crontabs were written for computers to interpret -- not humans.

Cronviz will turn...

````
* * * * * /usr/bin/foo
*/10 * * * * /usr/bin/bar
*/15 * * * * /usr/bin/baz
*/30 * * * * /usr/bin/qux
8 */8 * * * /usr/bin/quux
* * * * * /usr/bin/corge
*/30 23,0,1 * * * /usr/bin/grault
*/5 * * * * /usr/bin/garply
0 * * * * /usr/bin/waldo
0 0 4,22 * * /usr/bin/fred
0 1 * * * /usr/bin/plugh
0 13 * * * /usr/bin/xyzzy
0 2 * * * /usr/bin/thud
30 6 * * 1,2,3,4,5 /usr/bin/wibble
30 7 * * * /usr/bin/wobble
30 8 * * * /usr/bin/wubble
33 */2 * * * /usr/bin/flob
35 1 * * * /usr/bin/whatever
45 * * * * /usr/bin/whoever
45 1 * * * /usr/bin/whomever
* * * * * /usr/bin/whenever
````

into...

![]https://github.com/federatedmedia/cronviz/raw/master/assets/screenshot.png 


## RUNNING

Look to run.rb for an example that renders a HAML template that passes cronviz' JSON output to the SIMILE timeline widget to produce a graph as seen in the screenshot above.

You'll need to pass the filepath to a crontab file, or accept the default of "crontab" in the current directory.

You'll also need to pass two dates to act as book-ends for the period of time we're interested in graphing. cronviz will graph all matching datetimes from the crontab contents...

````
earliest_time = "2011-12-08 00:00" # Zeroth minute on Dec 8.
latest_time   = "2011-12-08 23:59" # Final minute on Dec 8.
````

Using strings lets us compare dates faster than casting to DateTime or int objects.

## ROLLUPS

Events that occur every minute and every five minutes will swamp the display, so these are rolled up into single events which get displayed as a continuous line, one per rolled-up job.

With a bit of cron-style math, you can define custom rollups targeting whatever interval you like. 

Let's say you've got an event that occurs every 21 minutes and you'd like to roll it up. Cron defines "*/21" as occurrences on the following minutes of each hour: :0, :21, :42. This results in three executions per hour, for as many hours are between your earliest_time and latest_time. However, if your earliest_time starts at :01 instead of :00, that hour's first execution on :00 won't happen. Thus, given the following...

````
earliest_time = "2011-12-08 00:01"
latest_time   = "2011-12-09 00:00"
````

then a job defined as "*/21 * * * *" will occur 71 times. You'd define a new hash in EVENT_DATA with your desired rollup interval as an integer, as follows...

````
71 => {
    "color"         => "#f00",  
    "class"         => "noisy_event",
    "title_prefix"  => "Every 21 minutes: ",
    "durationEvent" => true},
````

durationEvent must equal true. title_prefix can be defined as any string. Color and class are optional.


## NEXT STEPS

- Timezone is currently hardcoded and, all things remaining static, is effectively transparent as long as the server's timezone is yours. It would be nice to allow an offset parameter so that someone in Pacific could view an Eastern server's crontab translated to their local time.

- Excessively lengthy cron commands ("/usr/bin/bash /full/path/to/script.sh >> /some/output/path.log 2>> /some/error/path.log") can uglify the resulting graph display. It might be possible to find a simple way to allow specifying which bits of the cron command are used as the resulting title... comments in the crontab file?