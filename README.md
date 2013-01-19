can-i-nomnom
============

A tool for weight trend analysis

Concept
-------

See http://www.fourmilab.ch/hackdiet/e4/signalnoise.html

When you're dieting, fluctuating daily weigh-ins can hide progress--or worse, give you false hope. Some people recommend only weighing in once a week. But there's a better way: measure daily, just don't make any judgements based off the number you see on the scale. Instead, watch a smoothed trend line that filters out all the noise

### The trend line

To start, I'm using the calculation recommended in the Hacker's Diet, as outlined here: http://www.fourmilab.ch/hackdiet/e4/pencilpaper.html

> When you first start keeping your log, the very first day, enter your weight in the “Trend” column as well as the “Weight” column. Thereafter, calculate the number for the “Trend” column as follows: 

> Subtract yesterday's trend from today's weight. Write the result with a minus sign if it's negative.

> Shift the decimal place in the resulting number one place to the left. Round the number to one decimal place by dropping the second decimal and increasing the first decimal by one if the second decimal place is 5 or greater.

> Add this number to yesterday's trend number and enter in today's trend column.
