# Zorya-BIOS

An advanced BIOS for OpenComputers. There are two ways to install/update:

  * Run `update/install.lua`
  * Using the Zorya BIOS Update option.

## Features
The Zorya BIOS comes built in with support for booting OpenOS, Plan9k, and Tsuki Kernel. Other OSes can install their own boot modules. The BIOS also has support for network booting and booting Netinstall scripts. Also OEFI compliant.

## OEFI Compliance
Zorya is *almost* OEFI complient. Report any problems with OEFI.

OEFI library support:

| Method | Status | Notes |
| --- | --- | --- |
| `oefi.getApplications()` | Supported |  |
| `oefi.getAPIVersion()` | Supported | Returns 2. |
| `oefi.getImplementationName()` | Supported | Returns `Zorya BIOS` |
| `oefi.getImplementationVersion()` | Supported | Returns the version of the Zorya bootloader |
| `oefi.returnToOEFI()` | Implemented | Will forcefully reboot. |
| `oefi.execOEFIApp(drive, path)` | Supported |  |
| `computer.getBootAddress()` | Sometimes supported | Only defined when booting OpenOS or a similar OS. Tsuki kernel does not have this set. (It uses the `bootaddr` argument.) |
| `computer.setBootAddress(addr)` | Supported | Does nothing. |

Zorya also extends OEFI with a few extra methods:

| Method | Returns | Notes |
| --- | --- | --- |
| `zorya.getEntries()` | `table` | The table contains the raw data of the zoryarc boot entries. |
| `zorya.addEntry(name:string,handler:string,fs:string,...)` | nothing | Adds an entry to the zoryarc file. |
| `zorya.getVersion()` | `number` | The same as `_ZVER` |
| `zorya.getEntryID()` | `number` | Returns the entry ID of the booted entry. |
| `zorya.removeEntry(id:number)` | nothing | Removes an entry from the zoryarc file. |
| `zorya.getMode()` | `string` | Returns `zorya`, `oefi`, `compat`, `fallback`, or `error` |

**Note**: Only `zorya.getMode()` is available in fallback mode.

## Zorya Modes

### Zorya Mode
"Zorya mode" is when Zorya has booted straight from a Zorya module (such as p9kboot or tsukiboot). This has the entire Zorya library available and also provides the OEFI library

### OEFI Mode
OEFI mode is when Zorya has loaded an application from the OEFI module. This may result in instability as Zorya is not 100% compliant. Also provides the Zorya library.

### Compatibility mode
Compatibility mode is engaged when Zorya loads an OS from `init.lua`. This disables the OEFI and most of the Zorya libraries. Mostly used for OpenOS and compatible OSes. Still may expose advanced features to the OS via virtual devices (overriding the component library)

### Fallback mode
Fallback mode is when Zorya fails to load modules, and still has the BIOS pointing to a device. This will only load from `init.lua` and tends to boot much slower. Only intended to be used to fix Zorya.

### Error mode
This is when Zorya has encountered an unrecoverable error. Usually, it will try to enter the OEFI terminal. If it can't, it will let the machine handle the error.

## OEFI Booting
Zorya supports booting OEFI apps. Be warned, it may still be buggy.
