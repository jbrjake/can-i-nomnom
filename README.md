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
	
### Behind the Scenes ###

While this won't be visible in the public api, internally the core data stack is accessed through a certain protocol to do specific things:

* Add samples to core data
* Reads samples from core data
* Deletes samples from core data

It interfaces with the rest of TrendCore through DataSamples. No NSManagedObject leaves its DataStoreController ghetto. It uniques on dates.

	var dataStore = DataStoreController()
	dataStore.addSamples([DataSample]()) {
		// Samples added
		
		dataStore.fetchSamples(fromDate :NSDate, toDate :NSDate, completion: {
			samples in
			// we've got data back
			dataStore.deleteSamples(samples) {
				// Samples gone			
			}
		})
	})
		
	}
	
----

Once the controller has used the importer to feed samples into the data store, it will then run the filter over the data store. The filter does a few things to clean the data:
* Inserts interpolated weights for any missing days, using the .Dummy type
* Applies a 10-day moving average to the weights to populate the trend.

The filter has to run every time the data store add or remove operations are performed.

The external API will be dead simple:
* filterDataStore(dataStore, callback)

Internally, we'll have a structure like this:
* FilterController
	* Pipeline
	* Filters
		* Filter: (DataStore, callback) -> ()
	
### Interpolator logic ###

1. Find the first datapoint.
2. Increment to the next datapoint. If the date is > 1 calendar day apart, mark the previous index and the previous value.
3. Mark the current index and value.
4. Across the range of days inbetween, add a new sample and set the weight to plus the difference between the two weights divided by the day range, e.g.: N-1 + (V2-V1)/ (I2-I1)

### Trend logic ###

1. Find the 1st datapoint.
2. Set its trend to its value.
3. Find the 2nd datapoint.
4. Set n's trend to n-1's trend + ((n's value - n-1's trend) / 10, rounded to 1 decimal)
5. Repeat for remaining datapoints.

