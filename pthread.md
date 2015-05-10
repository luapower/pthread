---
tagline: POSIX threads
platforms: mingw, linux, osx
---

## `local pthread = require'pthread'`

A lightweight ffi binding of POSIX threads. Includes [winpthreads] from
MinGW-w64 for Windows support (uses the pthread library found on the
system otherwise).

[winpthreads]: http://sourceforge.net/p/mingw-w64/mingw-w64/ci/master/tree/mingw-w64-libraries/winpthreads/

## API

----------------------------------------------- ----------------------------------
__threads__
pthread.new(func_ptr[, attrs]) -> th            create and start a new thread
th:equal(other_th) -> true | false              check if two threads are equal
th:join() -> status                             wait for a thread to finish
th:cancel()                                     cancel a thread (possibly unsafe)
th:detach()                                     detach a thread
th:setcancelable(true|false) -> oldval          set thread as cancelable or not
th:setcanceltype('deferred'|'async') -> oldtype set cancelation type
th:priority(new_priority)                       set thread priority
th:priority() -> priority                       get thread priority
pthread.min_priority() -> priority              get min. priority
pthread.max_priority() -> priority              get max. priority
__mutexes__
pthread.mutex([mattrs]) -> mutex                create a mutex
mutex:free()                                    free a mutex
mutex:lock()                                    lock a mutex
mutex:unlock()                                  unlock a mutex
mutex:trylock() -> true | false                 lock a mutex or return false
__condition variables__
pthread.cond() -> cond                          create a condition variable
cond:free()                                     free the condition variable
cond:broadcast()                                broadcast
cond:signal()                                   signal
cond:wait(mutex)                                wait
cond:timedwait(mutex, seconds) -> true | false  wait with timeout
__read/write locks__
pthread.rwlock() -> rwlock                      create a r/w  lock
rwlock:free()                                   free a r/w  lock
rwlock:writelock()                              lock for writing
rwlock:readlock()                               lock for reading
rwlock:trywritelock() -> true | false           try to lock for writing
rwlock:tryreadlock() -> true | false            try to lock for reading
rwlock:unlock()                                 unlock the r/w lock
__scheduler__
pthread.yield()                                 relinquish control to the scheduler
pthread.sleep(seconds)                          suspend current thread
__semaphores__
pthread.sem(val) -> sem                         create a semaphore
sem:free()                                      free a semaphore
sem:wait()                                      wait on a semaphore
sem:trywait() -> true | false                   check if a semaphore is busy
sem:post()                                      increment the value
sem:value() -> val                              return the current value
----------------------------------------------- ----------------------------------


## Portability notes

POSIX is a standard hostile to binary compatibility, resulting in each
implementation having a different ABI. Moreso, different implementations
cover different parts of the API.

The list of currently supported pthreads implementations are:

  * winpthreads 0.5.0 from Mingw-w64 4.9.2 (binary included)
  * libpthread from EGLIBC 2.11 (tested on Ubuntu 10.04)
  * libpthread from OSX SDK 10.10 (tested on OSX 10.9)

Only functionality that is common _to all_ of the above is available.
Winpthreads dumbs down the API the most (no shared objects, no scheduling
policies, no priority protocols), but OSX too (no timedwaits, no spin-locks,
no barriers, no priority protocols) and even Linux (setting priority
levels needs root access). Functions that don't make sense with Lua
(pthread_once) or are stubs in one or more implementations
(pthread_setconcurrency) or are unsafe (pthread_kill) were also dropped.
All in all you get a pretty thin library with just the basics covered.
The good news is that this is really all you need to write portable apps.
In any case, I cannot personally support extra functionality,
but patches welcome.

Next are a few tips to get a rough idea of the portability situation.

To find out (part of) the truth about API coverage, you can start by
checking the exported symbols on the pthreads library on each platform
and compare them:

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

Next step is to look at the source code for winpthreads and find out what
is really implemented.
