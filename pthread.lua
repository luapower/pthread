
--POSIX threads binding.
--Written by Cosmin Apreutesei. Public Domain.

if not ... then return require'pthread_test' end

local ffi = require'ffi'
local lib = ffi.os == 'Windows' and 'libwinpthread-1' or 'pthread'
local C = ffi.load(lib)
local M = {C = C}
local H = require'pthread_h'

--helpers

local function check(ok, ret)
	if ok then return end
	error(string.format('pthread error: %d', ret))
end

--return-value checker for '0 means OK' functions
local function checkz(ret)
	check(ret == 0, ret)
end

--return-value checker for 'try' functions
local function checkbusy(tryfunc, obj)
	local ret = tryfunc(obj)
	check(ret == 0 or ret == H.EBUSY, ret)
	return ret == 0
end

--seconds to timespec conversion
local function timespec(sec)
	local int, frac = math.modf(sec)
	return ffi.new('struct timespec', int, frac * 10^9)
end

--threads

--create a new thread with a C callback. to use with a Lua callback,
--create a Lua state and a ffi callback pointing to a function inside
--the state, and use that as func_cb.
function M.new(func_cb, attrs)
	local thread = ffi.new'pthread_t'
	local attr
	if attrs then
		attr = ffi.new'pthread_attr_t'
		C.pthread_attr_init(attr)
		if attrs.detached then
			checkz(C.pthread_attr_setdetachstate(attr, C.PTHREAD_CREATE_DETACHED))
		end
		if attrs.priority then
			checkz(C.pthread_attr_setinheritsched(attr, C.PTHREAD_EXPLICIT_SCHED))
			local param = ffi.new'struct sched_param'
			param.sched_priority = prio
			checkz(C.pthread_attr_setschedparam(attr, param))
		end
		if attrs.stackaddr then
			checkz(C.pthread_attr_setstackaddr(attr, attrs.stackaddr))
		end
		if attrs.stacksize then
			checkz(C.pthread_attr_setstacksize(attr, attrs.stacksize))
		end
	end
	local ret = C.pthread_create(thread, attr, func_cb, nil)
	if attr then
		C.pthread_attr_destroy(attr)
	end
	checkz(ret)
	return thread
end

M.self = C.pthread_self --current thread

--test two thread objects for equality.
function M.equal(t1, t2)
	return C.pthread_equal(t1, t2) ~= 0
end

--call from thread to exit with a status code (probably unsafe,
--though there is a test for it that passes but it might leak).
--call from the main thread to wait on all threads.
function M.exit(code)
	checkz(C.pthread_exit(code))
end

--wait for a thread to finish.
function M.join(thread)
	local status = ffi.new'void*[1]'
	checkz(C.pthread_join(thread, status))
	return status[0]
end

--cancel a thread, either synchronously (when the thread calls testcancel())
--or asynchronously (inside various OS calls). neither one is probably safe.
function M.cancel(thread)
	checkz(C.pthread_cancel(thread))
end

--set a thread loose (not very useful because a Lua state can't free itself
--from the thread callback, unless you don't care for the leak)
function M.detach(thread)
	checkz(C.pthread_detach(thread))
end

--create a cancelation point (probably unsafe to call form a Lua state).
M.testcancel = C.pthread_testcancel

local cstates = {
	[true]    = C.PTHREAD_CANCEL_ENABLE,
	[false]   = C.PTHREAD_CANCEL_DISABLE,
}
function M.setcancelable(state)
	assert(state ~= nil, 'state expected')
	oldstate = oldstate or ffi.new'int[1]'
	checkz(C.pthread_setcancelstate(cstates[state], oldstate))
	return oldstate[1] == C.PTHREAD_CANCEL_ENABLE
end

local ctypes = {
	deferred = C.PTHREAD_CANCEL_DEFERRED,
	async    = C.PTHREAD_CANCEL_ASYNCHRONOUS, --unsafe!
}
local ctypenames = {
	[C.PTHREAD_CANCEL_DEFERRED]     = 'deferred',
	[C.PTHREAD_CANCEL_ASYNCHRONOUS] = 'async',
}
function M.setcanceltype(type)
	assert(type ~= nil, 'type expected')
	oldtype = oldtype or ffi.new'int[1]'
	checkz(C.pthread_setcanceltype(ctypes[type], oldtype))
	return ctypenames[oldtype[1]]
end

--set thread priority: level is between min_priority() and max_priority().
--NOTE: on Linux, min_priority() == max_priority() == 0 for SCHED_OTHER
--(which is the only cross-platform SCHED_* value), and SCHED_RR needs root
--which is a major usability hit, so it's not included.
function M.priority(thread, sched, level)
	assert(not sched or sched == 'other')
	local param = ffi.new'sched_param'
	if level then
		param.sched_priority = level
		checkz(C.pthread_setschedparam(thread, C.SCHED_OTHER, param))
	else
		checkz(C.pthread_getschedparam(thread, C.SCHED_OTHER, param))
		return param.sched_priority
	end
end
function M.min_priority(sched)
	assert(not sched or sched == 'other')
	return C.sched_get_priority_min(C.SCHED_OTHER)
end
function M.max_priority(sched)
	assert(not sched or sched == 'other')
	return C.sched_get_priority_max(C.SCHED_OTHER)
end

ffi.metatype('pthread_t', {
		__index = {
			equal = M.equal,
			join = M.join,
			cancel = M.cancel,
			detach = M.detach,
			setcancelable = M.setcancelable,
			setcanceltype = M.setcanceltype,
			priority = M.priority,
		},
	})

--mutexes

local mutex = {}

local mtypes = {
	normal     = C.PTHREAD_MUTEX_NORMAL,
	errorcheck = C.PTHREAD_MUTEX_ERRORCHECK,
	recursive  = C.PTHREAD_MUTEX_RECURSIVE,
}

function M.mutex(mattrs)
	local mutex = ffi.new('pthread_mutex_t', H.PTHREAD_MUTEX_INITIALIZER())
	local mattr
	if mattrs then
		mattr = ffi.new'pthread_mutexattr_t'
		checkz(C.pthread_mutexattr_init(mattr))
		if mattrs.type then
			local mtype = assert(mtypes[mattrs.type], 'invalid mutex type')
			checkz(C.pthread_mutexattr_settype(mattr, mtype))
		end
	end
	local ret = C.pthread_mutex_init(mutex, mattr)
	if mattr then
		C.pthread_mutexattr_destroy(mattr)
	end
	checkz(ret)
	ffi.gc(mutex, mutex.free)
	return mutex
end

function mutex.free(mutex)
	checkz(C.pthread_mutex_destroy(mutex))
	ffi.gc(mutex, nil)
end

function mutex.lock(mutex)
	checkz(C.pthread_mutex_lock(mutex))
end

function mutex.unlock(mutex)
	checkz(C.pthread_mutex_unlock(mutex))
end


function mutex.trylock(mutex)
	return checkbusy(C.pthread_mutex_trylock(mutex))
end

ffi.metatype('pthread_mutex_t', {__index = mutex})

--conditions

local cond = {}

function M.cond()
	local cond = ffi.new('pthread_cond_t', H.PTHREAD_COND_INITIALIZER())
	checkz(C.pthread_cond_init(cond, nil))
	return ffi.gc(cond, cond.free)
end

function cond.free(cond)
	checkz(C.pthread_cond_destroy(cond))
	ffi.gc(cond, nil)
end

function cond.broadcast(cond)
	checkz(C.pthread_cond_broadcast(cond))
end

function cond.signal(cond)
	checkz(C.pthread_cond_signal(cond))
end

function cond.wait(cond, mutex)
	checkz(C.pthread_cond_wait(cond, mutex))
end

function cond.timedwait(cond, mutex, sec)
	checkz(C.pthread_cond_timedwait(cond, mutex, timespec(sec)))
end

ffi.metatype('pthread_cond_t', {__index = cond})

--read/write locks

local rwlock = {}

function M.rwlock()
	local rwlock = ffi.new('pthread_rwlock_t', H.PTHREAD_RWLOCK_INITIALIZER())
	checkz(C.pthread_rwlock_init(rwlock, nil))
	return ffi.gc(rwlock, rwlock.free)
end

function rwlock.free(rwlock)
	checkz(C.pthread_rwlock_destroy(rwlock))
	ffi.gc(rwlock, nil)
end

function rwlock.writelock(rwlock)
	checkz(C.pthread_rwlock_wrlock(rwlock))
end

function rwlock.readlock(rwlock)
	checkz(C.pthread_rwlock_rdlock(rwlock))
end

function rwlock.trywritelock(rwlock)
	checkbusy(C.pthread_rwlock_trywrlock(rwlock))
end

function rwlock.tryreadlock(rwlock)
	checkbusy(C.pthread_rwlock_tryrdlock(rwlock))
end

function rwlock.unlock(rwlock)
	checkz(C.pthread_rwlock_unlock(rwlock))
end

--keys

--int pthread_key_create(pthread_key_t *key, void (* dest)(void *));
--int pthread_key_delete(pthread_key_t key);
--void *pthread_getspecific(pthread_key_t key);
--int pthread_setspecific(pthread_key_t key, const void *value);

local SC = ffi.os == 'Windows' and C or ffi.C
function M.yield()
	checkz(SC.sched_yield())
end

--semaphores

local sem = {}

function M.sem(val)
	local sem = ffi.new'sem_t'
	checkz(C.sem_init(sem, C.PTHREAD_PROCESS_PRIVATE, val))
	ffi.gc(sem, sem.free)
	return sem
end

function sem.free(sem)
	checkz(C.sem_destroy(sem))
	ffi.gc(sem, nil)
end

function sem.wait(sem)
	checkz(C.sem_wait(sem))
end

function sem.trywait(sem)
	return checkbusy(C.sem_trywait(sem))
end

function sem.post(sem)
	checkz(C.sem_post(sem))
end

function sem.value()
	local sval = ffi.new'int[1]'
	checkz(C.sem_getvalue(sem, sval))
	return sval[0]
end

ffi.metatype('sem_t', {__index = sem})

--sleep

M.sleep = H.sleep

return M
