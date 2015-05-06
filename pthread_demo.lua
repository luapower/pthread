local pthread = require'pthread'
local lua = require'luastate'
local ffi = require'ffi'
local glue = require'glue'

--create a new Lua state and a new thread, and run a worker function in that state and thread.
local function create_thread(worker, args)
	local state = lua.open()
	state:openlibs()
	state:push(function(worker, args)
		local ffi = require'ffi'
		local function wrapper()
			worker(args)
		end
		local wrapper_cb = ffi.cast('void *(*)(void *)', wrapper)
		return tonumber(ffi.cast('intptr_t', wrapper_cb))
	end)
	local wrapper_cb_ptr = ffi.cast('void *', state:call(worker, args))
	local thread = pthread.new(wrapper_cb_ptr)
	local function join()
		thread:join()
		state:close()
	end
	return join
end

--worker function that takes a mutex, a Lua state and a thread object.
--sets thread.shared so that the thread can access the shared state and calls thread:run().
local function worker(args)
	local ffi = require'ffi'
	local pthread = require'pthread'
	local lua = require'luastate'
	local state = ffi.cast('lua_State*', args.state)
	local mutex = ffi.cast('pthread_mutex_t*', args.mutex)
	local function pass(...)
		mutex:unlock()
		return ...
	end
	local function call_shared(api, ...)
		mutex:lock()
		state:getglobal(api)
		return pass(state:call(...))
	end
	local shared_vt = setmetatable({}, {__index = function(t, k)
		return
	end})
	args.thread.shared = call_shared
	args.thread:run()
end

local function addr(cdata)
	return tonumber(ffi.cast('intptr_t', ffi.cast('void*', cdata)))
end

--creates a shared state and a thread generator which can make threads that can access the shared state.
local function thread_gen(shared_api)
	local state = lua.open()
	state:openlibs()
	state:push(function(api)
		for k,v in pairs(api) do
			_G[k] = v
		end
	end)
	state:call(shared_api)
	local mutex = pthread.mutex.new()

	local function new_thread(thread)
		return create_thread(worker, {
			state = addr(state),
			mutex = addr(mutex),
			thread = thread,
		})
	end

	return new_thread
end

----

local shared = {}

function shared.exp(x, e)
	return x^e
end

local thread = {}

function thread:new(t)
	return glue.update(t, self)
end

function thread:run()
	print(self.shared('exp', self.x, self.e))
end

local new_thread = thread_gen(shared)
local join1 = new_thread(thread:new{x = 5, e = 2})
local join2 = new_thread(thread:new{x = 12, e = 2})
join1()
join2()
