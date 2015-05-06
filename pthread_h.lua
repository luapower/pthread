--pthread cdefs for winpthreads, Linux/GLIBC and OSX.
--NOTE: POSIX is a standard hostile to binary compatibility, resulting in
--substantially different ABIs for each platform/arch. Don't even think of
--running on an unsupported platform with these cdefs.
local ffi = require'ffi'
local M = require('pthread_h_'..ffi.os:lower())

ffi.cdef[[
int pthread_create(pthread_t *th, const pthread_attr_t *attr, void *(*func)(void *), void *arg);
pthread_t pthread_self(void);
int pthread_equal(pthread_t th1, pthread_t th2);
void pthread_exit(void *retval);
int pthread_join(pthread_t, void **retval);
int pthread_cancel(pthread_t);
int pthread_detach(pthread_t);
void pthread_testcancel(void);
int pthread_kill(pthread_t, int sig);
int pthread_once(pthread_once_t *o, void (*func)(void));
int pthread_setcancelstate(int state, int *oldstate);
int pthread_setcanceltype(int type, int *oldtype);
int pthread_getconcurrency(void); // TODO: not on linux32?
int pthread_setconcurrency(int new_level);  // TODO: not on linux32?
int pthread_getschedparam(pthread_t thread, int *pol, struct sched_param *param);
int pthread_setschedparam(pthread_t thread, int pol, const struct sched_param *param);

int pthread_attr_init(pthread_attr_t *attr);
int pthread_attr_destroy(pthread_attr_t *attr);
int pthread_attr_getdetachstate(const pthread_attr_t *a, int *flag);
int pthread_attr_setdetachstate(pthread_attr_t *a, int flag);
int pthread_attr_getinheritsched(const pthread_attr_t *a, int *flag);
int pthread_attr_setinheritsched(pthread_attr_t *a, int flag);
int pthread_attr_getschedparam(const pthread_attr_t *attr, struct sched_param *param);
int pthread_attr_setschedparam(pthread_attr_t *attr, const struct sched_param *param);
int pthread_attr_getschedpolicy (pthread_attr_t *attr, int *pol);
int pthread_attr_setschedpolicy (pthread_attr_t *attr, int pol);
int pthread_attr_getscope(const pthread_attr_t *a, int *flag);
int pthread_attr_setscope(pthread_attr_t *a, int flag);
int pthread_attr_getstackaddr(pthread_attr_t *attr, void **stack);
int pthread_attr_setstackaddr(pthread_attr_t *attr, void *stack);
int pthread_attr_getstacksize(const pthread_attr_t *attr, size_t *size);
int pthread_attr_setstacksize(pthread_attr_t *attr, size_t size);

int pthread_cond_init(pthread_cond_t *cv, const pthread_condattr_t *a);
int pthread_cond_destroy(pthread_cond_t *cv);
int pthread_cond_broadcast(pthread_cond_t *cv);
int pthread_cond_signal(pthread_cond_t *cv);
int pthread_cond_timedwait(pthread_cond_t *cv, pthread_mutex_t *external_mutex, const struct timespec *t);
int pthread_cond_wait(pthread_cond_t *cv, pthread_mutex_t *external_mutex);

int pthread_condattr_init(pthread_condattr_t *a);
int pthread_condattr_destroy(pthread_condattr_t *a);
int pthread_condattr_getpshared(const pthread_condattr_t *a, int *s);
int pthread_condattr_setpshared(pthread_condattr_t *a, int s);

int pthread_key_create(pthread_key_t *key, void (* dest)(void *));
int pthread_key_delete(pthread_key_t key);
void *pthread_getspecific(pthread_key_t key);
int pthread_setspecific(pthread_key_t key, const void *value);

int pthread_rwlock_init(pthread_rwlock_t *l, const pthread_rwlockattr_t *attr);
int pthread_rwlock_destroy(pthread_rwlock_t *l);
int pthread_rwlock_wrlock(pthread_rwlock_t *l);
int pthread_rwlock_rdlock(pthread_rwlock_t *l);
int pthread_rwlock_trywrlock(pthread_rwlock_t *l);
int pthread_rwlock_tryrdlock(pthread_rwlock_t *l);
int pthread_rwlock_unlock(pthread_rwlock_t *l);

int pthread_rwlockattr_init(pthread_rwlockattr_t *a);
int pthread_rwlockattr_destroy(pthread_rwlockattr_t *a);
int pthread_rwlockattr_getpshared(pthread_rwlockattr_t *a, int *s);
int pthread_rwlockattr_setpshared(pthread_rwlockattr_t *a, int s);

int pthread_mutex_init(pthread_mutex_t *m, const pthread_mutexattr_t *a);
int pthread_mutex_destroy(pthread_mutex_t *m);
int pthread_mutex_lock(pthread_mutex_t *m);
int pthread_mutex_unlock(pthread_mutex_t *m);
int pthread_mutex_trylock(pthread_mutex_t *m);

int pthread_mutexattr_init(pthread_mutexattr_t *a);
int pthread_mutexattr_destroy(pthread_mutexattr_t *a);
int pthread_mutexattr_getpshared(const pthread_mutexattr_t *a, int *type);
int pthread_mutexattr_setpshared(pthread_mutexattr_t * a, int type);
int pthread_mutexattr_gettype(const pthread_mutexattr_t *a, int *type);
int pthread_mutexattr_settype(pthread_mutexattr_t *a, int type);
int pthread_mutexattr_getprioceiling(const pthread_mutexattr_t *a, int * prio);
int pthread_mutexattr_setprioceiling(pthread_mutexattr_t *a, int prio);
int pthread_mutexattr_getprotocol(const pthread_mutexattr_t *a, int *type);
int pthread_mutexattr_setprotocol(pthread_mutexattr_t *a, int type);

int sched_yield(void);
int sched_get_priority_min(int pol);
int sched_get_priority_max(int pol);
int sched_getscheduler(pid_t pid);
int sched_setscheduler(pid_t pid, int pol, const struct sched_param *param);

int sem_init(sem_t * sem, int pshared, unsigned int value);
int sem_destroy(sem_t *sem);
sem_t * sem_open(const char * name, int oflag, mode_t mode, unsigned int value);
int sem_close(sem_t * sem);
int sem_unlink(const char * name);
int sem_wait(sem_t *sem);
int sem_trywait(sem_t *sem);
int sem_post(sem_t *sem);
int sem_getvalue(sem_t * sem, int * sval);
]]

return M
