<img src="http://blog.safecast.org/wp-content/uploads/2014/01/header.png?w=460&amp;h=120&amp;crop=1" alt="Safecast">

 

# Pocketcast Prototype
Dev for Pocketcast client on iOS, initially using a bGeigie BLE proxy


# Update 2015-06-03

All documentation below this section is somewhat outdated, and current development is changing too rapidly to synchronize it just now.

In short, while what is present below is somewhat correct, the core model of the app has changed to support low-power use cases and have a very flexible and reuseable standardized data model.

### Data Model Changes

A database-backed ANSI C-based data model and processing graph has been created to replace DeviceBufffer.c, HistoryBuffer.c, and LocationBuffer.c.  This is designed to be extremely flexible and work with not only this version of Pocketcast but potentially any sensor or sensors.

Because the code is ANSI C, it is highly portable, and should even work on embedded platforms.

Because it is database-backed with a standard, strongly-typed relational database, this provides an excellent combination of performance, efficiency, and being able to query data while remaining flexible enough to dynamically handle future use cases.

This is quite non-trivial to develop, but the end goal is a reuseable component that is trivial to integrate and reduces future development time and maintenance.

#### Data Model - Objects

The data model fundamentally defines devices, sensors, and channels.  A channel is the equivalent of a Bluetooth BLE characterisitic.

These channels are then mapped to display and database storage fields.

#### Data Model - Processing Graph

The other part of this is the processing graph, which is any number of processing nodes performing various operations on the data to convert raw sensor values to derived-SI units.  The reason for the flexible operation chain instead of formal concepts such as gamma sensitivity are because for many sensors, a constant factor is not sufficient to transfeom raw sensor data into something useful.  In terms of the Pocketcast with the SensorTag, this is true for most all of the built-in sensors.

#### Data Model - End Use

The app will contain a fully-functional object model and processing graph that will automatically recognize Pocketcast devices via a to-be-determined Bluetooth UUID.  This will be defined at a database level.

Eventually, the ability to import a model and graph will be added.  This will likely involve adding a JSON parser, with the JSON coming from a known and recognized BLE service, or potentially a webservice or other mechanism.  The JSON document would be parsed and added to the internal DB as the default preloaded model and graph are.

It would also be my expectation that a GUI-type editor could be developed to greatly simplify the process of creating object models and graphs for new devices.

#### Data Model - Interfaces

Objective C interface classes will be provided on top of the C model to make integration and use easier.

### BLE Delegate

All Bluetooth functionality has been moved from the ViewController to a new BLE delegate interface.  Support for callbacks and multiple services and characteristics have been added.

### CoreLocation Delegate

As with BLE, CoreLocation functionality now has been seperated into its own delegate class.  Support for iOS's significant location changes mode has been added.  Supoort for external power detection has been added.


# Old Documentation Follows - Superceded by Above


# Status Overview
<img width="728" height="546" src="https://github.com/Safecast/pGeigie-prototype/raw/master/pocketcast_2048x1536.png" />

### Version 0.1

Goal: Get bGeigie BLE input going with the location (NMEA + altitude) and timestamp coming from the iOS device.

Status: 100%.

Caveats: The following bGeigie columns were simulated:
- "number of satellites" (not obtainable on iOS.  "8" if CoreLocation returns a valid location, "0" otherwise.)
- "gpsIsValid" (CoreLocation's determination via negated HDOP for invalid location is used here.)
- "HDOP" (CoreLocation returns horizontal precision in meters.  Per the Wikipedia page, a factor of 6.0 is being used to convert meters to HDOP.  This is an approximation.  The actual HDOP is likely indeterminate on iOS from my understanding.)

Note: there has been some internal discussion about simulating these columns other than HDOP.  An alternative implementation has been proposed, which would use a modernized log format converted to a bGeigie log by a gateway server.  At this point I assume an initial implementation using the bGeigie format directly on iOS is more likely, but will update as needed.

Additionally, simulated Bluetooth input has been added.


### Version 0.2

Goal: Support "burst" transmissions from Pocketcast.

Requirements: Pocketcast dev hardware and protocol.

Status: 20%

Done:
- Core Location updates, altitudes, time, and precision information are saved to an internal ring buffer structure, LocationBuffer (instead of just the last value).
- LocationBuffer is implemented in pure ANSI C for portability
- LocationBuffer interpolates based upon timestamps and known locations, with some handling for edge cases (may need tweaking)
- Improved power savings.  CoreLocation updates are now tied to be connected to the device, or connecting to the device.  This may need future tweaking for timeouts and background modes, etc.

To Do:
- Must support receiving pGeigie "burst" transmissions, of several measurements [how many?] at a fixed time interval [when?]
- First, the time of each pGeigie measurement should be computed. [offset some pushlatency?]
- Next, each pGeigie measurement should be matched to the closest time index from LocationBuffer using LocationBuffer_Interpolate()

Update (2015-04-28): After feedback from Ray regarding a low-energy mode suitable for 24/7 operation using CoreLocation significant change functionality that would not be uploadable to the current API, some additional requirements to accomodate this emerged.

Low-Power To Do:
- Default to the low-power significant changes CoreLocation mode.  Note data recorded in this manner cannot be submitted to the API currently due to the assumptions made in point geometry regarding spatial precision.
- Allow a toggle to return to the normal high-energy, higher-precision dGPS mode suitable for Safecast surveys.  In the UI, this could be implemented by requiring the user to start and end a survey specifically. (TBD)


### Version 0.3

Goal: Functional proof-of-concept.  Store information to log file and post to Safecast API.

Status: 0%.  Marc has indicated he will be working on this component.

- A bGeigie-format log file should be synthesized to contain the measurements for a session
- The bGeigie serial number should come from the unit.  Exact details / format for this are unknown.
- Uploads of log files (once closed) should be demonstrated, using a RESTful HTTP POST to the Safecast API

Caveats:
- With a bGeigie, a log file "session" or survey is from the unit power-on to power-off.  It is possible that allowances may need to be made for resuming a survey due to BT connectivity failure.

Low-Power To Do:
- To support both power modes, data will be stored in a SQLite database.  Based on either survey start/end "tags", or a timestap query (TBD), the log file rows will be queried from the DB and then converted/exported to a log file at that time.
- For the UI to obtain a list of (possible) log files, the data provider layer will return query results from a survey table, joined to the measurement rows.
- For the UI to obtain a bGeigie log file of a survey for upload to the Safecast API, the data provider layer will convert the measurement rows to that format as needed, stripping out any 500m precision results.
- Nice to have: an alternate log format not importable into the Safecast API that could contain low-precision or mixed-precision data.  This would however require a query interface, as the results would not be by survey.


### Version 0.4

Goals: Add UI.

Status: 0%

User interface elements to support all of the above should be added at this point.

Interactive:
- Local log file management
- Configuration of automatated submission of log files.  Default to not use cellular data, with option to override.
- View upload status history for a log file (eg, if the automated upload fails)
- Safecast API key entry
- Device connection dialog, with multiple device support (do not autoconnect to devices unless previously connected)
- "Paired" device management, to disable autoconnection for specific devices that have been connected to previously

Data Transmission:
- Manual upload of log file to Safecast API.
- Log file retrieval / download to PC or online storage service via some method(s) of file transfer

UI Alerts/Messages:
- UI feedback of API and Bluetooth errors
- UI feedback of file upload / data transfer status
- UI feedback of internet connectivity ("reachability")
- UI feedback of use of airplane mode (user error) on iPhone, if possible to detect this.


Caveats:
- This is likely the most time-intensive development stage.
- Because the app is running in the background, minimizing RAM use with the UI is critical.
- Lazy load UIViews / UIViewControllers, and unload as much as possible when moving to the background.


### Version 0.5

Goal: Polish and make suitable for use

Requirements: Testing of Core Location precision to maximize battery use

Status: 5%

- Core Location should stop working / running in background if a device is not connected [DONE]
- Any timers or polling must also be stopped.  In general, the use of polling should be avoided.  Excessive wakeups will cause iOS to terminate background apps.
- The app should self-terminate, or stop Core Location / Bluetooth and all processing if < 20% battery remaining
- On AC, Core Location accuracy should be set to kCLLocationAccuracyBestForNavigation
- On battery, Core Location accuracy should be set to either kCLLocationAccuracyBest or perhaps kCLLocationAccuracyNearestTenMeters. [DONE]
- Test data should be collected and evaluated to determine if kCLLocationAccuracyNearestTenMeters is acceptable for Safecast data.  It should be compared to the actual results from kCLLocationAccuracyBest. [DONE]
- If test data is unavailable, kCLLocationAccuracyBest should be used as a default on battery.  Extending the user's battery life is nice, but is secondary.  There is no point in gathering data at all if the spatial resolution is unacceptable. [DONE]

Optional:
- The user might be allowed to disable geolocation or tweak the precision further.  However, no setting lower in precision than kCLLocationAccuracyNearestTenMeters, or without coordinates entirely, should be accepted for data submission to Safecast.
- For increasing geolocation precision at the expense of battery life, a timed mode may be useful, where it reverts to the default behavior when the timer expires.  This gives the user the ability to perform a specific survey or part of a survey with higher spatial precision.

Reference:
- kCLLocationAccuracyBestForNavigation: <10m precision, highest battery consumption
- kCLLocationAccuracyBest: <10m precision, high battery consumption
- kCLLocationAccuracyNearestTenMeters: Might be OK (needs testing), may be a compromise between precision and battery life.
- kCLLocationAccuracyHundredMeters: Do not use.
- kCLLocationAccuracyKilometer: Do not use.
- kCLLocationAccuracyThreeKilometers: Do not use.
- distanceFilter: Would suggest kCLDistanceFilterNone for AC power.  For battery, we should do some further testing.  Would assume 1.0m is a reasonable starting point.  Likely should not exceed 5.0m.

Update:
- kCLLocationAccuracyNearestTenMeters has acceptable precision, and resolves to the same 5m precision that kCLLocationAccuracyBest did when WiFi was available.  With Wifi disabled, it reported 10m, though eventually did better with time.

If all required features above are supported, this may be considered an early release candidate pending approval from Sean/Pieter.


### Version 0.5+

Goal: Implementation of "nice to haves".

Requirements: Apple Watch hardware if development of Apple Watch interface is desired.

Status: 0%

Note: The Safecast app for iOS already has some code for many of these things which may be of some use.

Local CPM / dose rate display, with optionally:
- Selectable measurement time
- Zero/clear/reset
- Dose equivalent (dosimeter)
- Statistical error (may not be possible to calculate given the 5s chunks)

Apple Watch support
- (assuming anyone buys one)

Option to disable logging, or flag a log as "do not upload".
- For users to measure things we don't want in the database.
- Alpha/beta sources, test sources, etc.

Graphing
- Unload/release these when app moves to background.

Mapping
- Mapping may be a bad idea for an app running in the background; it uses a lot of RAM.
- If mapping is used, map views must be released when the app moves to the background.
- Historically, releasing a map view (either MKMapView or Google Maps) did not recover all memory, as the map frameworks have memory leaks.  Verify they are not leaking memory before use.
- Another option for mapping it to send data to the "main" Safecast app for iOS, which does not run in the background.  This requires work on both ends.

Sound Output
- Synthesis of click sounds on device for the current CPM (I have code to do this)
- Alarm for radiation level threshold or for radiological anomalies outside of a statistical threshold

... etc.



### General

Code:
- Code should be written in ANSI C when possible and abstracted from platform-specific bits, to enable easier porting to other platforms in the future.
- Code should be ANSI C, Objective C, or SQL.

Hardware:
- It is possible the pGeigie *may* get a removable alpha/beta shield added, with some indication of this in the Bluetooth transmission.  If the shield is not in place, the data should either not be logged, or the log flagged as "do not upload".  This would be to support alpha/beta surface contamination scans which we don't want in the database.
- The sensor being used by the pGeigie may change from an LND7313.  This may present future headaches if the gamma sensitivity is not identical.

Platform:
- iOS will kill background apps pretty readily.
- The main reason is due to RAM.  Most iOS devices have <= 1 GB.  Using Safari on a complex webpage or webpages, viewing a map, or running a game will exhaust free RAM and create memory pressure.
- Thus, the app running in the background indefinately is not guaranteed.
- At some point unknown to the user, the app may be terminated.
- There may need to be some way to indirectly indicate this to the user, such as a regular heartbeat to a watchdog server that would send an iOS notification.  Perhaps something can be done in the applicationWillTerminate delegate override method.
- The best way to avoid this is to minimize memory use, and not do other things that raise iOS's ire, such as excessive wakeups. (eg, timers)
