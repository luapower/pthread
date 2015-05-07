
--POSIX threads binding.
--Written by Cosmin Apreutesei. Public Domain.
--Only stuff found in *all* supported platforms is defined.

if not ... then return require'pthread_demo' end

local ffi = require'ffi'
local lib = ffi.os == 'Windows' and 'libwinpthread-1' or 'pthread'
local C = ffi.load(lib)
local M = {C = C}
local PM = require'pthread_h'
--add wrappers from pthread_h
for k,v in pairs(PM) do
	M[k] = v
end

local function check(ok, ret)
	if ok then return end
	error(string.format('pthread error: %d', ret))
end

local function checkz(ret)
	check(ret == 0, ret)
end

--threads

function M.new(func_cb, attr, arg)
	local pthread = ffi.new'pthread_t[1]'
	checkz(C.pthread_create(pthread, attr, func_cb, arg))
	return pthread[0]
end

M.self = C.pthread_self
M.equal = C.pthread_equal --luajit converts 0/1 into true/false for __eq

--call from thread to exit with a status code (which is a pointer)
--call from the main thread to wait on all threads.
function M.exit(code)
	checkz(C.pthread_exit(code))
end

function M.join(pthread)
	local status = ffi.new('void*[1]')
	checkz(C.pthread_join(pthread, status))
	return status[0]
end

function M.cancel(pthread)
	checkz(C.pthread_cancel(pthread))
end

--thread attributes

function M.attr()
	local attr = ffi.new'pthread_attr_t'
	checkz(C.pthread_attr_init(attr))
	ffi.gc(attr, C.pthread_attr_destroy)
	return attr
end

local function invert(t)
	local dt = {}
	for k,v in pairs(t) do
		dt[v] = k
	end
	return dt
end

ffi.metatype('struct pthread_attr_t', {__index = {
	detachstate = function(attr, state)
		local flags = {
			joinable = C.PTHREAD_CREATE_JOINABLE,
			detached = C.PTHREAD_CREATE_DETACHED,
		}
		local invflags = invert(flags)
		if state == nil then
			state = ffi.new'int[1]'
			checkz(C.pthread_attr_getdetachstate(attr, state))
			return invflags[state[0]]
		else
			checkz(C.pthread_attr_setdetachstate(attr, flags[state]))
		end
	end,
	inheritsched = function(attr, inh)
		local flags = {
			inherit  = C.PTHREAD_INHERIT_SCHED,
			explicit = C.PTHREAD_EXPLICIT_SCHED,
		}
		local invflags = invert(flags)
		if inh == nil then
			inh = ffi.new'int[1]'
			checkz(C.pthread_attr_getinheritsched(attr, inh))
			return invflags[inh[0]]
		else
			checkz(C.pthread_attr_setinheritsched(attr, flags[inh]))
		end
	end,
	schedpriority = function(attr, prio)
		local flags = {
			other = C.SCHED_OTHER,
			fifo  = C.SCHED_FIFO,
			rr    = C.SCHED_RR,
		}
		local invflags = invert(flags)
		local param = ffi.new'sched_param'
		if prio == nil then
			checkz(M.pthread_attr_getschedparam(attr, param))
			return invflags[param.sched_priority]
		else
			param.sched_priority = flags[prio]
			checkz(M.pthread_attr_setschedparam(attr, param))
		end
	end,
	getscope = M.pthread_attr_getscope,
	setscope = M.pthread_attr_setscope,
	getstackaddr = M.pthread_attr_getstackaddr,
	setstackaddr = M.pthread_attr_setstackaddr,
	getstacksize = M.pthread_attr_getstacksize,
	setstacksize = M.pthread_attr_setstacksize,
}})

--mutexes

M.mutex = {}

function M.mutex.new(attr)
	local m = ffi.new'pthread_mutex_t'
	checkz(C.pthread_mutex_init(m, attr))
	return ffi.gc(m, M.mutex.free)
end

function M.mutex.free(m)
	checkz(C.pthread_mutex_destroy(m))
	ffi.gc(m, nil)
end

local EBUSY = 16

function M.mutex.lock(mutex)
	checkz(C.pthread_mutex_lock(mutex))
end

function M.mutex.trylock(mutex)
	local ret = C.pthread_mutex_trylock(mutex)
	check(ret == 0 or ret == EBUSY, ret)
	return ret == 0
end

function M.mutex.unlock(mutex)
	checkz(C.pthread_mutex_unlock(mutex))
end

-- conditions

M.cond = {}

function M.cond.new(attr)
	local cond = ffi.new'pthread_cond_t'
	checkz(C.pthread_cond_init(cond, attr))
	return ffi.gc(cond, M.cond.free)
end

function M.cond.free(cond)
	checkz(C.pthread_cond_destroy(cond))
	ffi.gc(cond, nil)
end

function M.cond.wait(cond, mutex)
	checkz(C.pthread_cond_wait(cond, mutex))
end

function M.cond.signal(cond)
	checkz(C.pthread_cond_signal(cond))
end

function M.cond.broadcast(cond)
	checkz(C.pthread_cond_broadcast(cond))
end

--object interface

ffi.metatype('struct pthread_t', {__index = {
	exit = M.exit,
	cancel = M.cancel,
	join = M.join,
	self = M.self,
}, __eq = M.equal})

ffi.metatype('struct pthread_mutex_t', {__index = {
	free = M.mutex.free,
	lock = M.mutex.lock,
	trylock = M.mutex.trylock,
	unlock = M.mutex.unlock,
}})

ffi.metatype('pthread_cond_t', {__index = {
	free = M.cond.free,
	signal = M.cond.signal,
	broadcast = M.cond.broadcast,
}})

return M
