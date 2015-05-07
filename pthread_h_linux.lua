--cdefs for pthread on EGLIBC 2.11.1 from Ubuntu 10.04
local ffi = require'ffi'

ffi.cdef[[
enum {
	PTHREAD_CREATE_JOINABLE = 0,
	PTHREAD_CREATE_DETACHED = 1,
	PTHREAD_CANCEL_ENABLE = 0,
	PTHREAD_CANCEL_DISABLE = 1,
	PTHREAD_CANCEL_DEFERRED = 0,
	PTHREAD_CANCEL_ASYNCHRONOUS = 1,
	PTHREAD_CANCELED = -1,
	PTHREAD_INHERIT_SCHED = 0,
	PTHREAD_EXPLICIT_SCHED = 1,
	PTHREAD_SCOPE_SYSTEM = 0,
	PTHREAD_SCOPE_PROCESS = 1,
	PTHREAD_PROCESS_PRIVATE = 0,
	PTHREAD_PROCESS_SHARED = 1,
	PTHREAD_PRIO_NONE = 0,    //TODO: not on linux32?
	PTHREAD_PRIO_INHERIT = 1, //TODO: not on linux32?
	PTHREAD_PRIO_PROTECT = 2, //TODO: not on linux32?
	PTHREAD_MUTEX_NORMAL = 0,
	PTHREAD_MUTEX_ERRORCHECK = 2,
	PTHREAD_MUTEX_RECURSIVE = 1,
	PTHREAD_MUTEX_DEFAULT = PTHREAD_MUTEX_NORMAL,
	SCHED_OTHER          = 0,
	SCHED_FIFO           = 1,
	SCHED_RR             = 2,
};

typedef int pid_t;
typedef unsigned int mode_t;

typedef unsigned long int pthread_t;
]]

if ffi.abi'32bit' then
ffi.cdef[[
typedef union {
  char __size[36];
  long int __align;
} pthread_attr_t;

typedef union {
  char __size[24];
  long int __align;
} pthread_mutex_t;

typedef union {
  char __size[48];
  long long int __align;
} pthread_cond_t;

typedef union {
  char __size[32];
  long int __align;
} pthread_rwlock_t;

typedef union {
  char __size[16];
  long int __align;
} sem_t;
]]
else --x64
ffi.cdef[[
typedef union {
  char __size[56];
  long int __align;
} pthread_attr_t;

typedef union {
  char __size[40];
  long int __align;
} pthread_mutex_t;

typedef union {
  char __size[48];
  long long int __align;
} pthread_cond_t;

typedef union {
  char __size[56];
  long int __align;
} pthread_rwlock_t;

typedef union {
  char __size[32];
  long int __align;
} sem_t;
]]
end

ffi.cdef[[
typedef int pthread_once_t;

typedef union {
  char __size[4];
  int __align;
} pthread_mutexattr_t;

typedef union {
  char __size[4];
  int __align;
} pthread_condattr_t;

typedef union {
  char __size[8];
  long int __align;
} pthread_rwlockattr_t;

typedef unsigned int pthread_key_t;

struct sched_param { int __sched_priority; };

// for pthread_cleanup_push()/_pop()
struct _pthread_cleanup_buffer {
  void (*__routine)(void *);
  void *__arg;
  int __canceltype;
  struct _pthread_cleanup_buffer *__prev;
};
]]

local M = {}

--[[
function M.pthread_cleanup_push(routine, arg)
  __pthread_unwind_buf_t __cancel_buf
  void (*__cancel_routine) (void *) = (routine)
  void *__cancel_arg = (arg)
  int not_first_call = __sigsetjmp ((struct __jmp_buf_tag *) (void *) __cancel_buf.__cancel_jmp_buf, 0)
  if (__builtin_expect (not_first_call, 0)) {
    __cancel_routine (__cancel_arg)
    __pthread_unwind_next (&__cancel_buf)
  }

  __pthread_register_cancel (&__cancel_buf) {
    void __pthread_register_cancel (__pthread_unwind_buf_t *__buf);
  function pthread_cleanup_pop(execute) do { } while (0); }
    while (0)
      __pthread_unregister_cancel (&__cancel_buf)
      if (execute)
        __cancel_routine (__cancel_arg); } while (0)
        void __pthread_unregister_cancel (__pthread_unwind_buf_t *__buf);
  end
end
]]

local function zeroinit() return end
M.PTHREAD_MUTEX_INITIALIZER  = zeroinit
M.PTHREAD_RWLOCK_INITIALIZER = zeroinit
M.PTHREAD_COND_INITIALIZER   = zeroinit
M.PTHREAD_ONCE_INIT          = zeroinit

return M