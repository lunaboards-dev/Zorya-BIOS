# OEFI Module
It's name doesn't cover all it provides. The OEFI module provides the OEFI library, OEFI booting, *and* the Zorya library.

## OEFI Library
| --- | --- |
| Method | Notes |
| --- | --- |
| `getAPIVersion():number` | Returns the OEFI API version. In this case, it returns `1`. |
| `getApplications():table` | Returns a list of applications. |
| `getImplementationName():string` | Returns the implementation name. In this case, it returns `"Zorya BIOS"` |
| `getImplementationVersion():number` | Returns the implementation version. In this case, it returns `2` |
| `returnToOEFI()` | Basically an alias for `computer.shutdown(true)` in this case. |
| `execOEFIApp(fs:string, path:string, args:table)` | Executes an OEFI app. Probably won't return anything. Probably. |

## Zorya Library
| --- | --- |
| Method | Notes |
| --- | --- |
| `getVersion():number` | Returns the version, `2.0` |
| `getEntries():table` | Returns the list of entries. |
| `addEntry(name:string, handler:string, fs:string, ...)` | Adds an entry to the Zorya boot menu. |
| `removeEntry(id:number)` | Removes an entry. |
| `rescanEntries()` | Scans for more entries. Internally, runs a boot handler. |

## Zorya OEFI extension library
| --- | --- |
| Method | Notes |
| --- | --- |
| `loadfile(path:string):function` | Loads a lua file from the boot drive |

## OEFI boot entry arguments
| --- | --- | --- |
| Name | Type | Notes |
| --- | --- | --- |
| `fs` | `string` | The filesystem the .efi file is stored on |
| `file` | `string` | Path to the file |
| `args` | `table` | Any arguments. If none, pass a blank table. |