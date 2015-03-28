--pthread binding (Cosmin Apreutesei, public domain)
require'_attic.pthread_h'
local ffi = require'ffi'
local C = ffi.load'pthread'

local M = {C = C}

local function check(ok, ret)
	if ok then return end
	error(string.format('errno %d', ret))
end

local function checkz(ret)
	check(ret == 0, ret)
end

--threads

function M.new(func_cb, attr, arg)
	local pthread = ffi.new'pthread_t'
	checkz(C.pthread_create(pthread, attr, func_cb, arg))
	return pthread
end

--call from thread to exit with a status code (which is a pointer)
--call from the main thread to wait on all threads.
function M.exit(code)
	checkz(C.pthread_exit(code))
end

function M.cancel(pthread)
	checkz(C.pthread_cancel(pthread))
end

function M.join(pthread)
	local status = ffi.new('void*[1]')
	checkz(C.pthread_join(pthread, status))
	return status[0]
end

M.self = C.pthread_self
M.equal = C.pthread_equal --luajit converts 0/1 into true/false for __eq

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

ffi.metatype('pthread_t', {__index = {
	exit = M.exit,
	cancel = M.cancel,
	join = M.join,
	self = M.self,
}, __eq = M.equal})

ffi.metatype('pthread_mutex_t', {__index = {
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

if not ... then require 'pthread_demo' end

return M
