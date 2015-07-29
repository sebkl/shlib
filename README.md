# shlib
A quick shellscript containing some frequently used shell functions.


## Shell functions
The below table shows some main shell functions implemented by the library

| **function** | **description** | 
|-----|-----|
| ```lock``` | create a global filesystem lock. |
| ```unlock``` | remove a global filesystem lock. |
| ```service_start ./path/PIDFILE "sleep 1000"``` | Start a service launch loop referred by the given PIDFILE. |
| ```service_stop ./path/PIDFILE``` | Try to stop a service with several tries. |

## Usage
```
#!/bin/sh
set +e
source path/to/shlib.sh path/to/optional/confdir
```
