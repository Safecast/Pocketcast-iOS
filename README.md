# pGeigie-prototype
Dev for pGeigie client on iOS, initially using a bGeigie BLE proxy

### Version 0.1

Goal: Get bGeigie BLE input going with the location (NMEA + altitude) and timestamp coming from the iOS device.

Status: 90%.

Need to fix the following bGeigie columns:
- "number of satellites" (not obtainable on iOS.  crude approximation should be used.)
- "HDOP" (different on iOS iirc.  again, approximate best as possible.)
- "gpsIsValid" (not sure what should determine this in iOS)
- "checksum" (ref: https://github.com/Safecast/SafecastBGeigie/blob/master/GPS.cpp#L157)

Additionally, simulated Bluetooth input has been added.


### Version 0.2

Goal: Support "burst" transmissions from pGeigie.

Requirements: pGeigie dev hardware

Status: 0%

- Core Location updates, altitudes, time, and precision information should be saved to an internal ring buffer structure (instead of just the last value.  Do not convert to string/NMEA immediately.)
- Must support receiving pGeigie "burst" transmissions, of several measurements [how many?] at a fixed time interval [when?]

pGeigie Data Processing:
- First, the time of each pGeigie measurement should be computed
- Next, each pGeigie measurement should be matched to the closest time index in the ring buffer of Core Location updates
- Linear interpolation should be used to determine an approximate location for the pGeigie measurement
- Some checking may need to be done to not match or use low-precision data from Core Location.  This needs further research.
- A further tricky issue for iOS is that it is not possible to determine if hardware GPS is present directly.  This may need to be determined indirectly, and tested with WiFi-only iPads and iPod Touches, such that low-precision location information does not contaminate the spatial precision of the Safecast dataset.


### Version 0.3

Goal: Functional proof-of-concept.  Store information to log file and post to Safecast API.

Status: 0%.  Marc has indicated he will be working on this component.

- A bGeigie-format log file should be synthesized to contain the measurements for a session
- The bGeigie serial number should come from the unit.  Exact details / format for this are unknown.
- Uploads of log files (once closed) should be demonstrated, using a RESTful HTTP POST to the Safecast API

Caveats:
- Multiple pGeigies may be connected at the same time, thus recording to multiple log files at the same time.
- With a bGeigie, a log file "session" is from the unit power-on to power-off.  It is possible that allowances may need to be made for resuming a log file due to BT connectivity failure.


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

Status: 0%

- Core Location should stop working / running in background if a device is not connected
- Any timers or polling must also be stopped.  In general, the use of polling should be avoided.  Excessive wakeups will cause iOS to terminate background apps.
- The app should self-terminate, or stop Core Location / Bluetooth if < 20% battery remaining
- On battery, Core Location accuracy should be set to either kCLLocationAccuracyBest or kCLLocationAccuracyNearestTenMeters.  The power consumption and actual precision of these modes should be tested in more detail.
- Test data should be collected and evaluated to determine if kCLLocationAccuracyNearestTenMeters is acceptable for Safecast data.

Optional:
- The user might be allowed to disable geolocation or tweak the precision further.  However, no setting lower in precision than kCLLocationAccuracyNearestTenMeters, or without coordinates entirely, should be accepted for data submission to Safecast.
- For increasing geolocation precision at the expense of battery life, a timed mode may be useful, where it reverts to the default behavior when the timer expires.

Reference:
- kCLLocationAccuracyBestForNavigation: <10m precision, highest battery consumption
- kCLLocationAccuracyBest: <10m precision, high battery consumption
- kCLLocationAccuracyNearestTenMeters: Probably OK (needs testing), may be best compromise between precision and battery life.
- kCLLocationAccuracyHundredMeters: Not good enough for data submission.
- kCLLocationAccuracyKilometer: Useless.
- kCLLocationAccuracyThreeKilometers: Useless.
- distanceFilter: Would suggest kCLDistanceFilterNone for AC power.  For battery, we should do some further testing.  My assumption is a value of 5.0 meters is appropriate for ~10m precision, but that is making assumptions about how things are implemented that may not be so.

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
