# pGeigie-prototype
Dev for pGeigie client on iOS, initially using a bGeigie BLE proxy

### Version 0.1

Goal: Get bGeigie BLE input going with the location (NMEA + altitude) and timestamp coming from the iOS device.

Status: Done, but need to fix the following bGeigie columns:
- "number of satellites" (not obtainable on iOS.  crude approximation should be used.)
- "HDOP" (different on iOS iirc.  again, approximate best as possible.)
- "gpsIsValid" (not sure what should determine this in iOS)
- "checksum" (ref: https://github.com/Safecast/SafecastBGeigie/blob/master/GPS.cpp#L157)

Additionally, simulated Bluetooth input has been added.


### Version 0.2

Goal: Support "burst" transmissions from pGeigie.
Requirements: pGeigie dev hardware

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

- A bGeigie-format log file should be synthesized to contain the measurements for a session
- The bGeigie serial number should come from the unit.  Exact details / format for this are unknown.
- Uploads of log files (once closed) should be demonstrated, using a RESTful HTTP POST to the Safecast API

Caveats:
- Multiple pGeigies may be connected at the same time, thus recording to multiple log files at the same time.
- With a bGeigie, a log file "session" is from the unit power-on to power-off.  It is possible that allowances may need to be made for resuming a log file due to BT connectivity failure.


### Version 0.4

Goals: Add UI.

User interface elements to support all of the above should be added at this point, such as:
- Local log file management
- Log file retrieval / download via some method(s) of file transfer
- Manually or automatically submit closed/completed log files
- Upload status history for a log file (eg, if the automated upload fails)
- Safecast API key entry
- Device connectivity with multiple device support (only autoconnect if the user has previously connected to a device. allow this to be disabled/"unpaired".)
- UI feedback of API and Bluetooth errors
- Optional alarm upon Bluetooth connectivity loss

Caveats:
- This is likely the most time-intensive development stage.
- Because the app is running in the background, minimizing RAM use with the UI is critical.
- Lazy load UIViews / UIViewControllers, and unload as much as possible when moving to the background.


### Version 0.5

Goal: Polish and make suitable for use

- Core Location should stop working / running in background if a device is not connected
- Any timers or polling must also be stopped.  In general, the use of polling should be avoided.  Excessive wakeups will cause iOS to terminate background apps.
- The app should self-terminate, or stop Core Location / Bluetooth if < 20% battery remaining
- Core Location accuracy should be set to best possible when plugged into AC, but on battery the accuracy and minimum distance required for an update should be set more conservatively.  This will likely require testing.  Ideally, a precision of 10m - 20m is acceptable.
- Optionally, the user may be allowed to set the geolocation precision higher or lower.  If set lower than ~20m precision, the log files should be flagged as not suitable for upload or submission to Safecast.

If all required features above are supported, this may be considered an early release candidate pending approval from Sean/Pieter.


### Version 0.5+

Goal: Implementation of "nice to haves":

- Local CPM / dose rate display
- Option to disable logging or flag a log as "do not upload".  This is especially relevant if the user is measuring alpha/beta radiation, which we don't want in the database.
- Graphing
- Mapping(?) (maybe a bad idea for an app running in the background, uses a lot of RAM)
- Apple Watch support (assuming anyone buys one)
- Synthesis of click sounds on device for the current CPM (I have code to do this)
- Alarm for radiation level threshold or for radiological anomalies outside of a statistical threshold
- etc.

Again, note that as an app running in the background, RAM is at a premium and must be used conservatively.  Processing and rendering of most everything should stop in the background to conserve battery.
Everything that can be unloaded should be unloaded when moving into the background.


### General

Code:
- Code should be written in ANSI C when possible and abstracted from platform-specific bits, to enable easier porting to other platforms in the future.
- Code should be ANSI C, Objective C, or SQL.

Hardware:
- It is possible the pGeigie *may* get a removable alpha/beta shield added, with some indication of this in the Bluetooth transmission.  If the shield is not in place, the data should either not be logged, or the log flagged as "do not upload".  This would be to support alpha/beta surface contamination scans which we don't want in the database.
- The sensor being used by the pGeigie may change from an LND7313.  This may present future headaches if the gamma sensitivity is not identical.
