**blockmy (v1.0)**

**Copyright (C) 2025 Theodoros Arvanitis (Author)**

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see [https://www.gnu.org/licenses/](https://www.gnu.org/licenses/)

Email: *theodorosarv@gmail.com*

## blockmy

This is a script written in Shell/Bash, which allows user to:

* Block & Unblock their integrated Camera and/or USB external Storage

### Usage:

blockmy [DEVICE] [OPTION]

**DEVICE:**
 
* camera
* usbstor

**OPTION:**
 
*  -on	    *blocks DEVICE*
 
*  -off	    *unblocks DEVICE*
 
*  --status	   *DEVICE's current block status*
 
*  -h, --help	   *for this info*

*e.g.  blockmy camera -on,  blockmy usbstor --status*
