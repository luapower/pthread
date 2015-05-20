--pthread.h from OSX 10.10 SDK

local ffi = require'ffi'
assert(ffi.os == 'OSX', 'Platform not OSX')

ffi.cdef[[
typedef long time_t;

enum {
	PTHREAD_CREATE_DETACHED = 2,
	PTHREAD_CANCEL_ENABLE = 0x01,
	PTHREAD_CANCEL_DISABLE = 0x00,
	PTHREAD_CANCEL_DEFERRED = 0x02,
	PTHREAD_CANCEL_ASYNCHRONOUS = 0x00,
	PTHREAD_CANCELED = 1,
	PTHREAD_EXPLICIT_SCHED = 2,
	PTHREAD_PROCESS_PRIVATE = 2,
	PTHREAD_MUTEX_NORMAL = 0,
	PTHREAD_MUTEX_ERRORCHECK = 1,
	PTHREAD_MUTEX_RECURSIVE = 2,
	SCHED_OTHER = 1,
	PTHREAD_STACK_MIN = 8192,
	CLOCK_REALTIME = 1, // CALENDAR_CLOCK
	CLOCK_MONOTONIC = 0, // SYSTEM_CLOCK
};

typedef void *real_pthread_t;
typedef struct { real_pthread_t _; } pthread_t;
]]

if ffi.abi'32bit' then
ffi.cdef[[
typedef struct pthread_attr_t {
	long __sig;
	char __opaque[36];
} pthread_attr_t;

typedef struct pthread_mutex_t {
	long __sig;
	char __opaque[40];
} pthread_mutex_t;

typedef struct pthread_cond_t {
	long __sig;
	char __opaque[24];
} pthread_cond_t;

typedef struct pthread_rwlock_t {
	long __sig;
	char __opaque[124];
} pthread_rwlock_t;

typedef struct pthread_mutexattr_t {
	long __sig;
	char __opaque[8];
} pthread_mutexattr_t;

typedef struct pthread_condattr_t {
	long __sig;
	char __opaque[4];
} pthread_condattr_t;

typedef struct pthread_rwlockattr_t {
	long __sig;
	char __opaque[12];
} pthread_rwlockattr_t;

// for pthread_cleanup_push()/_pop()
struct __darwin_pthread_handler_rec {
	void (*__routine)(void *);
	void *__arg;
	struct __darwin_pthread_handler_rec *__next;
};
]]
else --x64
ffi.cdef[[
typedef struct pthread_attr_t {
	long __sig;
	char __opaque[56];
} pthread_attr_t;

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
typedef struct pthread_key_t { unsigned long _; } pthread_key_t;

struct sched_param {
	int sched_priority;
	char __opaque[4];
};

unsigned int usleep(uint32_t seconds);
]]

local _PTHREAD_MUTEX_SIG_init  = 0x32AAABA7
local _PTHREAD_COND_SIG_init   = 0x3CB0B1BB
local _PTHREAD_RWLOCK_SIG_init = 0x2DA8B3B4

local H = {}

H.EINTR     = 4
H.EBUSY     = 16
H.ETIMEDOUT = 60

function H.PTHREAD_RWLOCK_INITIALIZER() return _PTHREAD_RWLOCK_SIG_init end
function H.PTHREAD_MUTEX_INITIALIZER()  return _PTHREAD_MUTEX_SIG_init end
function H.PTHREAD_COND_INITIALIZER()   return _PTHREAD_COND_SIG_init end

function H.sleep(s)
	ffi.C.usleep(s * 10^6)
end

--clock_gettime() emulation

ffi.cdef[[
// NOTE: unlike timespec, mach_timespec is 32bit on x64,
// which means it will wrap around in year 2038.
typedef struct mach_timespec {
	unsigned int tv_sec;
	int tv_nsec;
} mach_timespec_t;

int host_get_clock_service(unsigned int host, int clock_id, int *clock_serv);
int clock_get_time(int clock_serv, mach_timespec_t *cur_time);
unsigned int mach_host_self(void);
unsigned int mach_task_self_;
int mach_port_deallocate(int task, int name);
]]

local cclock = ffi.new'int[1]'
local mts = ffi.new'mach_timespec_t'
local C = ffi.C
function H.clock_gettime(clk_id, tp)
	C.host_get_clock_service(C.mach_host_self(), clk_id, cclock)
	local retval = C.clock_get_time(cclock[0], mts)
	C.mach_port_deallocate(C.mach_task_self_, cclock[0])
	tp.s = mts.tv_sec
	tp.ns = mts.tv_nsec
	return retval
end

return H
