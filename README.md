Can I Nom Nom?
==============

Cinn cuts through the noise and lets you see how your diet is doing. It strips away all the day-to-day fluctuations in your weight and just shows your progress over time. Cinn lets you know at a glance if it's time to get serious or a good day to indulge.

Roadmap 
-------

### 0.1 Complete ###

* Framework to read data from a dummy importer, store it in Core Data
	* TrendCore framework with API to fetch weights for date ranges and add dates from an import source
	* Dummy importer for testing
	* Core Data persistence for imported data
* Filtering on the data
	* Fill in gaps with interpolated values
	* Calculate trend weights for the data
* Code coverage

### 0.2 ###

* Display the weight trendline on a UIView
	* View model that takes in data samples for a range of dates and outputs arrays of x and y samples from dates and trend values respectively.
	* View whose controller requests samples from all dates and plots them

### 0.3 ###

* Assessor to determine whether the trend is good or bad
	* Owned by trend core
	* New public api to get its decision
* UI to display whether the trend is good or bad
	* View model that takes in an assessment for a range of dates
	* View whose controller requests samples from all dates and plots them

### 0.4 ###

* Reading from HealthKit

### 0.5 ###

* Publish phone app:
	* See a progress trendline for the past month
	* See a yes/no progress indicator

### 0.6 ###

* Publish watch app
	* See a progress trendline on a glance
	* See a yes/no progress indicator on a complication
	
### 0.7 ###

* Enter your weight from your watch

### 0.8 ###

* Touch gestures on the phone to scale the date range
	* "Snap" to week, month, year, and all-time views

### 0.9 ###

* Share trend lines on Twitter

### 1.0 ###

* Polish

### Long-Term ###

* Predict future weight based on trend

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
	* Importers provide <= 1 weight value for each date.
	* Reads across ranges of dates	
* Feeds data to the data store controller

#### Data Store Controller ####

* Manages a Core Data stack to persist imported weights
* Provides CRUD for reading, writing, and transforming weights
	* Transformations include trend calculations

##### DataSample #####

The data model used by the data store controller for representing weights:

* Weight
* Date
* Trend

### TrendViewModel ###

* Transform model data from TrendCore formatting to whatever the UI needs, and reconfigures the model in response to UI changes for display style.

### TrendViewController ###

* Displays a line chart, drawing data from the view model.
* Sends UI events to the view model

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

* Add samples from a source to core data
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

