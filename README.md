# pGeigie-prototype
Dev for pGeigie client on iOS, initially using a bGeigie BLE proxy

### Version 0.1

The initial goal is to get bGeigie BLE input going with the location (NMEA + altitude) and timestamp coming from the iOS device.  This will be accomplished by string substitution.

Status: Done, but need to fix "number of satellites" (not obtainable on iOS), "HDOP" (different on iOS), "gpsIsValid", and "checksum" columns in each bGeigie rows.

Additionally, simulated Bluetooth input has been added.

### Version 0.2

Next, location, altitude and timestamps should be saved to an internal ring buffer, instead of merely the last value used.  (also, this includes some analog of num sats, HDOP, gpsIsValid, etc)

This has no meaning whatsoever with a bGeigie BLE, but will eventually be used to determine geolocation and time for a pGeigie.  Obviously, this quickly degenerates into a theoeretical exercise without hardware.

Once that is done, linear interpolation should be used to determine the geolocation for times that are matched to input samples.  Allowances for low-precision initial lockons and a 5-sigma distance filter may need to be used to prevent outliers from tainting this.

Again, for development to effectively proceed to this stage, prototype hardware should be available at this point.

### Version 0.3

Next up is bGeigie log file synthesis.  A complete logfile must be reconstructed and saved on device, with an appropriate header for the pGeigie and device ID.  Exact details of interface for that may change(?).

The Safecast API should be used to via a RESTful HTTP PUT to submit data to the server.

NOTE: allowances should be made for connecting multiple pGeigies to a single device at the same time.

### Version 0.4

User interface elements for the above should be added, such as local log file management, the ability to automatically or manually submit log files, upload status history (eg, informing the user if the automated upload fails), device selection if multiple units are present (many:many), API key entry, UI feedback of API and Bluetooth errors, etc.

This is likely a larger time cost most of the above items.

NOTE: As this app will be running in the background, it is important to lazy load UI Views / ViewControllers dynamically and dispose of them when done.

### Version 0.5

If all required features above are supported, this may be considered a release candidate pending approval from Sean/Pieter.

### Version 0.5+

Implementation of "nice to haves":
- local CPM / dose rate display
- graphing
- mapping(?) (maybe a bad idea for an app running in the background, uses a lot of RAM)
- Apple Watch support (assuming anyone buys one)
- etc.

Again, note that as an app running in the background, RAM is at a premium and must be used conservatively.
