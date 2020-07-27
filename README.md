Search Module
=============

![This script was last tested in Nuix 8.6](https://img.shields.io/badge/Script%20Tested%20in%20Nuix-8.6-green.svg)

View the GitHub project [here](https://github.com/Nuix/Smoke) or download the latest release [here](https://github.com/Nuix/Smoke/releases).

# Overview

**Written By:** Cameron Stiller

This script can be used to perform integrity checks or validate that migrations were successful.
Every object in the case will be counted and configuration dumped to a text file:
`%caseDirectory%\smoke\%version%.smoke`
e.g.
`C:\cases\Case 13\smoke\8.6.0.16.smoke`

# Getting Started

## Setup

Begin by downloading the latest release of this code.  Extract the contents of the archive into your Nuix scripts directory.  In Windows the script directory is likely going to be either of the following:

- `%appdata%\Nuix\Scripts` - User level script directory
- `%programdata%\Nuix\Scripts` - System level script directory

## Using the script

Select the smoke script from the scripts menu will run the script and dump to a text file.
Watching the progress can be done in the scripts -> script console.

When finished a smoke dump will be written to a text file:
`%caseDirectory%\smoke\%version%.smoke`

For integrity checks, simply run the smoke on the version you already use and as all the objects are touched if an issue exists it will propogate on screen or in the script console.

For migration checks:
1. Open the case in it's existing version and run smoke
2. Run the smoke script (confirm no errors, if errors... deal with them here )
3. Migrate the case
4. Run the smoke script (confirm no errors, if errors... deal with them here )
5. Navigate to the case directory and it's subdirectory 'smoke'
6. Open the two files inside a text comparison tool and validate the differences.

**Due to Nuix adding/moving features and settings the comparison must be done visually.**

**There will always be differences - it is your responsibility to check the differences are acceptable.**

**For counts these should always remain the same**

## Console mode

This script will work in console mode. Specify your switches at the command line:

`"nuix_console.exe" -licencesourcetype dongle smoke.rb -Dcase="C:\cases\Case 1" -Dmigrate=false`

# License

```
Copyright 2018 Nuix

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
