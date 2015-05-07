---
tagline: POSIX threads
platforms: mingw, linux, osx
---

## `local pthread = require'pthread'`

A lightweight ffi binding of POSIX threads. Includes libwinpthread from
MinGW-w64 for Windows support (uses the pthread library found on the
system otherwise).

## API

Coming soon.

## Portability notes

POSIX is a standard hostile to binary compatibility, resulting in each
implementation having a different ABI. Moreso, different implementations
cover different parts of the API.

The list of currently supported pthreads implementations are:

  * winpthreads 0.5.0 from Mingw-w64 4.9.2 (binary included)
  * libpthread from EGLIBC 2.11 (tested on Ubuntu 10.04)
  * libpthread from OSX SDK 10.10 (tested on OSX 10.9)

Only functionality that is common _to all_ of the above is available.
I cannot personally support extra functionality but patches welcome.
Next are a few tips to shed some light into the portability situation.

To find out the truth about API coverage (functions, not flags),
you can check the exported symbols on the pthreads library for each
platform and compare them:

	On Linux:

		mgit syms /lib/libpthread.so.0 | \
			grep '^pthread' > pthread_syms_linux.txt

	On OSX:

		(mgit syms /usr/lib/libpthread.dylib
		mgit syms /usr/lib/system/libsystem_pthread.dylib) | \
			grep '^pthread' > pthread_syms_osx.txt

	On Windows:

		mgit syms bin\mingw64\libwinpthread-1.dll | \
			grep ^^pthread > pthread_syms_mingw.txt

	Compare the results (the first column tells the number of platforms
	that a symbol was found on):

		sort pthread_syms_* | uniq -c | sort -nr

To find out the differences in ABI and supported flags, you can preprocess
the headers on different platforms and compare them:

	mgit preprocess pthread.h sched.h semaphore.h > pthread_h_<platform>.lua

The above will use gcc to preprocess the headers and generate a
(very crude, mind you) Lua cdef template file that you can use
as a starting point for a binding and/or to check ABI differences.

