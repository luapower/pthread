--cdefs for winpthreads v0.5.0 from mingw-w64 4.9.2
local ffi = require'ffi'
assert(ffi.os == 'Windows', 'platform not Windows')

ffi.cdef[[
enum {
	PTHREAD_CREATE_JOINABLE = 0,
	PTHREAD_CREATE_DETACHED = 0x04,
	PTHREAD_CANCEL_ENABLE = 0x01,
	PTHREAD_CANCEL_DISABLE = 0,
	PTHREAD_CANCEL_DEFERRED = 0,
	PTHREAD_CANCEL_ASYNCHRONOUS = 0x02,
	PTHREAD_CANCELED = 0xDEADBEEF,
	PTHREAD_INHERIT_SCHED = 0x08,
	PTHREAD_EXPLICIT_SCHED = 0,
	PTHREAD_SCOPE_SYSTEM = 0x10,
	PTHREAD_SCOPE_PROCESS = 0,
	PTHREAD_PROCESS_PRIVATE = 0,
	PTHREAD_PROCESS_SHARED = 1,
	PTHREAD_PRIO_NONE = 0,
	PTHREAD_PRIO_INHERIT = 8,
	PTHREAD_PRIO_PROTECT = 16,
	PTHREAD_MUTEX_NORMAL = 0,
	PTHREAD_MUTEX_ERRORCHECK = 1,
	PTHREAD_MUTEX_RECURSIVE = 2,
	PTHREAD_MUTEX_DEFAULT = PTHREAD_MUTEX_NORMAL,
	SCHED_OTHER          = 0,
	SCHED_FIFO           = 1,
	SCHED_RR             = 2,
};

typedef int pid_t;
typedef unsigned short mode_t;

typedef uintptr_t pthread_t;
typedef struct pthread_attr_t pthread_attr_t;
struct pthread_attr_t {
    unsigned p_state;
    void *stack;
    size_t s_size;
    struct sched_param param;
};
typedef long pthread_once_t;
typedef void *pthread_mutex_t;
typedef void *pthread_cond_t;
typedef void *pthread_rwlock_t;
typedef unsigned pthread_mutexattr_t;
typedef int pthread_condattr_t;
typedef int pthread_rwlockattr_t;
typedef unsigned pthread_key_t;
struct sched_param {
  int sched_priority;
};
typedef void *sem_t;

// for pthread_cleanup_push()/_pop()
typedef struct _pthread_cleanup _pthread_cleanup;
struct _pthread_cleanup {
	void (*func)(void *);
	void *arg;
	_pthread_cleanup *next;
};
struct _pthread_cleanup **pthread_getclean(void);
]]

local M = {}

function M.pthread_cleanup_stack()
	local stack = {}
	function M.pthread_cleanup_push(F, A)
		local _pthread_cup = ffi.new('_pthread_cleanup',
			F, A, M.C.pthread_getclean())
		pthread_getclean()[0] = _pthread_cup
		local function pthread_cleanup_pop(E)
			pthread_getclean()[0] = _pthread_cup.next
			if E then func(A) end
		end
		table.insert(stack, pthread_cleanup_pop)
		function stack.pthread_cleanup_pop(E)
			assert(table.remove(stack), 'cleanup stack empty')(E)
		end
		return stack
	end
end

local GENERIC_INITIALIZER            = -1
local GENERIC_ERRORCHECK_INITIALIZER = -2
local GENERIC_RECURSIVE_INITIALIZER  = -3
local GENERIC_NORMAL_INITIALIZER     = -1

function M.PTHREAD_MUTEX_INITIALIZER() return GENERIC_INITIALIZER end
function M.PTHREAD_RECURSIVE_MUTEX_INITIALIZER() return GENERIC_RECURSIVE_INITIALIZER end
function M.PTHREAD_ERRORCHECK_MUTEX_INITIALIZER() return GENERIC_ERRORCHECK_INITIALIZER end
function M.PTHREAD_NORMAL_MUTEX_INITIALIZER() return GENERIC_NORMAL_INITIALIZER end
function M.PTHREAD_DEFAULT_MUTEX_INITIALIZER() return PTHREAD_NORMAL_MUTEX_INITIALIZER end
function M.PTHREAD_COND_INITIALIZER() return GENERIC_INITIALIZER end
function M.PTHREAD_RWLOCK_INITIALIZER() return GENERIC_INITIALIZER end
function M.PTHREAD_ONCE_INIT() return 0 end

return M
