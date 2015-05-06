--cdefs for pthread on OSX 10.10 SDK
local ffi = require'ffi'

ffi.cdef[[
enum {
	PTHREAD_CREATE_JOINABLE = 1,
	PTHREAD_CREATE_DETACHED = 2,
	PTHREAD_CANCEL_ENABLE = 0x01,
	PTHREAD_CANCEL_DISABLE = 0x00,
	PTHREAD_CANCEL_DEFERRED = 0x02,
	PTHREAD_CANCEL_ASYNCHRONOUS = 0x00,
	PTHREAD_CANCELED = 1,
	PTHREAD_INHERIT_SCHED = 1,
	PTHREAD_EXPLICIT_SCHED = 2,
	PTHREAD_SCOPE_SYSTEM = 1,
	PTHREAD_SCOPE_PROCESS = 2,
	PTHREAD_PROCESS_PRIVATE = 2,
	PTHREAD_PROCESS_SHARED = 1,
	PTHREAD_PRIO_NONE = 0,
	PTHREAD_PRIO_INHERIT = 1,
	PTHREAD_PRIO_PROTECT = 2,
	PTHREAD_MUTEX_NORMAL = 0,
	PTHREAD_MUTEX_ERRORCHECK = 1,
	PTHREAD_MUTEX_RECURSIVE = 2,
	PTHREAD_MUTEX_DEFAULT = PTHREAD_MUTEX_NORMAL,
	SCHED_OTHER          = 1,
	SCHED_FIFO           = 4,
	SCHED_RR             = 2,
};

typedef int32_t pid_t;
typedef uint16_t mode_t;
]]

if ffi.abi'32bit' then
ffi.cdef[[
struct _opaque_pthread_t {
 long __sig;
 struct __darwin_pthread_handler_rec *__cleanup_stack;
 char __opaque[4088];
};

struct _opaque_pthread_attr_t {
 long __sig;
 char __opaque[36];
};

struct _opaque_pthread_once_t {
 long __sig;
 char __opaque[4];
};

struct _opaque_pthread_mutex_t {
 long __sig;
 char __opaque[40];
};

struct _opaque_pthread_cond_t {
 long __sig;
 char __opaque[24];
};

struct _opaque_pthread_rwlock_t {
 long __sig;
 char __opaque[124];
};

struct _opaque_pthread_mutexattr_t {
 long __sig;
 char __opaque[8];
};

struct _opaque_pthread_condattr_t {
 long __sig;
 char __opaque[4];
};

struct _opaque_pthread_rwlockattr_t {
 long __sig;
 char __opaque[12];
};

// for pthread_cleanup_push()/_pop()
struct __darwin_pthread_handler_rec {
	void (*__routine)(void *);
	void *__arg;
	struct __darwin_pthread_handler_rec *__next;
};
]]
else --x64
ffi.cdef[[
typedef struct pthread_t {
 long __sig;
 struct __darwin_pthread_handler_rec *__cleanup_stack;
 char __opaque[8176];
} *pthread_t;

typedef struct pthread_attr_t {
 long __sig;
 char __opaque[56];
} pthread_attr_t;

typedef struct pthread_once_t {
 long __sig;
 char __opaque[8];
} pthread_once_t;

typedef struct pthread_mutex_t {
 long __sig;
 char __opaque[56];
} pthread_mutex_t;

typedef struct pthread_cond_t {
 long __sig;
 char __opaque[40];
} pthread_cond_t;

typedef struct pthread_rwlock_t {
 long __sig;
 char __opaque[192];
} pthread_rwlock_t;

typedef struct pthread_mutexattr_t {
 long __sig;
 char __opaque[8];
} pthread_mutexattr_t;

typedef struct pthread_condattr_t {
 long __sig;
 char __opaque[8];
} pthread_condattr_t;

typedef struct pthread_rwlockattr_t {
 long __sig;
 char __opaque[16];
} pthread_rwlockattr_t;
]]
end

ffi.cdef[[
typedef unsigned long pthread_key_t;
struct sched_param {
	int sched_priority;
	char __opaque[4];
};
typedef int sem_t;
]]

local M = {}

function M.pthread_cleanup_stack()
	local stack = {}
	function stack.pthread_cleanup_push(func, val)
		local __handler = ffi.new'__darwin_pthread_handler_rec'
		local __self = M.C.pthread_self()
		__handler.__routine = func
		__handler.__arg = val
		__handler.__next = __self.__cleanup_stack
		__self.__cleanup_stack = __handler
		local function pthread_cleanup_pop(execute)
			__self.__cleanup_stack = __handler.__next
			if execute then func(val) end
		end
		table.insert(stack, pthread_cleanup_pop)
	end
	function stack.pthread_cleanup_pop(execute)
		assert(table.remove(stack), 'cleanup stack empty')(execute)
	end
	return stack
end

local _PTHREAD_MUTEX_SIG_init = 0x32AAABA7
local _PTHREAD_ERRORCHECK_MUTEX_SIG_init = 0x32AAABA1
local _PTHREAD_RECURSIVE_MUTEX_SIG_init = 0x32AAABA2
local _PTHREAD_FIRSTFIT_MUTEX_SIG_init = 0x32AAABA3
local _PTHREAD_COND_SIG_init = 0x3CB0B1BB
local _PTHREAD_ONCE_SIG_init = 0x30B1BCBA
local _PTHREAD_RWLOCK_SIG_init = 0x2DA8B3B4

function M.PTHREAD_RWLOCK_INITIALIZER() return _PTHREAD_RWLOCK_SIG_init, 0 end
function M.PTHREAD_MUTEX_INITIALIZER()  return _PTHREAD_MUTEX_SIG_init, 0 end
function M.PTHREAD_COND_INITIALIZER()   return _PTHREAD_COND_SIG_init, 0 end
function M.PTHREAD_ONCE_INIT()          return _PTHREAD_ONCE_SIG_init, 0 end

return M
