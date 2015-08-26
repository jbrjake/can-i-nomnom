Can I Nom Nom?
==============

Cinn cuts through the noise and lets you see how your diet is doing. It strips away all the day-to-day fluctuations in your weight and just shows your progress over time. Cinn lets you know at a glance if it's time to get serious or a good day to indulge.

Features
--------

### Version 0.5 (iPhone-only) ###

#### Model ####

* Read daily averages from HealthKit
* Import weight to CoreData
* Fill in gaps with a simple interpolation
* Calculate 10-day moving averages

#### UI ####

* See a progress trendline on the phone app
* See a yes/no progress indicator on the phone app

### Version 1 (includes Watch) ###

#### UI ####

* See a progress trendline on the watch app
* See a yes/no progress indicator on a watch glance

### Long-Term ###

* Enter your weight from your watch.
* Share trend lines on Twitter
* Predict future weight based on trend
* Switch between week, month, year, and all-time views for trendline

Concept
-------

See http://www.fourmilab.ch/hackdiet/e4/signalnoise.html

When you're dieting, fluctuating daily weigh-ins can hide progress--or worse, give you false hope. Some people recommend only weighing in once a week. But there's a better way: measure daily, just don't make any judgements based off the number you see on the scale. Instead, watch a smoothed trend line that filters out all the noise

### The trend line

To start, I'm using the calculation recommended in the Hacker's Diet, as outlined here: http://www.fourmilab.ch/hackdiet/e4/pencilpaper.html

> * When you first start keeping your log, the very first day, enter your weight in the “Trend” column as well as the “Weight” column. Thereafter, calculate the number for the “Trend” column as follows: 

> * Subtract yesterday's trend from today's weight. Write the result with a minus sign if it's negative.

> * Shift the decimal place in the resulting number one place to the left. Round the number to one decimal place by dropping the second decimal and increasing the first decimal by one if the second decimal place is 5 or greater.

> * Add this number to yesterday's trend number and enter in today's trend column.

Architecture
------------

I want this project to be as modular and testable as possible. That means using separate frameworks for everything.

### TrendCore ###

#### Data Import Controller ####

* Reads data using an importer.
	* Importers provide 1 weight value for each date.
	* Reads across ranges of dates
	
* Feeds data to the data store controller

#### Data Store Controller ####

* Manages a Core Data stack to persist imported weights
* Provides CRUD for reading, writing, and transforming weights
	* Transformations include trend calculations

##### WeightModel #####

The data model used by the data store controller for representing weights:

* Weight
* Date
* Trend transformation
	* Interpolation of missing dates will occur here
	* Trends will not be stored, trading cpu efficiency for less state to manage

### TrendViewModel ###

* Transform model data from TrendCore formatting to whatever the UI needs, and reconfigures the model in response to UI changes for display style.

### TrendViewController ###

* Displays a line chart, drawing data from the view model.
* Sends UI events to the view model

Milestones
----------

### 0.1 ###

Goal: Framework to read data from a dummy importer, store it in Core Data

1. TrendCore framework and classes stubbed out, with methods
2. Unit tests for methods
3. Build a dummy importer
4. Get the data import controller to read from the importer
5. Set up Core Data, except the trend transformation
6. Get the data store controller to write from the import controller to CD
7. Test the public api for the controller by returning weights for date ranges

### 0.2 ###

Goals: Reading from HealthKit and trending

### 0.3 ###

Goal: figure out yes/no stuff. who owns that, trend core? does it return a bool or a value? What is that value?

### 0.4 ###

Goal: Framework to display yes/no progress indicator data

### 0.5 ###

Goal: Framework to display weight data trendline

### 1.0 ###

Goal: Complete watch support

Deep Dive: TrendCore 
--------------------

### Hierarchy ###

* TrendCore Framework
	* TrendCoreController
		* DataStoreController
			* CoreData Stack
				* WeightModel
			* DataImportController				
				* DataImporterFactory
					* DummyImporter
					* HealthKitImporter
					* CSVImporter
					* FitBitImporter
					* MyFitnessPalImporter

### Usage ###

The caller is going to have the same concerns as a TrendViewModel:

* It's going to want a collection of weights for a range of dates.
* It's also going to want a collection of trends for a range of dates.
* It's also going to need to have a way to tell the code to import from a particular source.
* And it needs to have a way to list the available ways to import data into the core

So that stuff will form the public api protocol vended by the TrendCore framework.

	var trendCore = TrendCoreController()

	trendCore.import(TrendCoreImporterType.HealthKit, completion: {
		trendCore.fetchWeights(NSDate.distantPast(),
						toDate:NSDate.distantFuture(),
					completion: 
		{
		fetchedWeights in
			doStuffWith(fetchedWeights)
		}
	}
	



