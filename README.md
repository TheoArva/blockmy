**blockmy (v1.0)**

# MIT License

**Copyright (c) 2025 theodorosarv@gmail.com**

---

## Grant of Permissions

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to:

- **Use** the Software
- **Copy** the Software
- **Modify** the Software
- **Merge** the Software
- **Publish** the Software
- **Distribute** the Software
- **Sublicense** the Software
- **Sell** copies of the Software

and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

> **Condition:** The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

---

## Disclaimer of Warranty & Liability

THE SOFTWARE IS PROVIDED **"AS IS"**, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.

IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

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
