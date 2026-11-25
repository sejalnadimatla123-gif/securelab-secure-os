// stackbomb.c — Mission 22 xv6 experiment: deliberately overrun the user
// stack to observe whether xv6's guard page catches it (instead of silently
// corrupting whatever memory sits below the stack).
#include "kernel/types.h"
#include "user/user.h"

static int
eat_stack(int depth)
{
  char buf[512];              // ~0.5KB of stack per call
  buf[0] = depth & 0xff;      // touch the page so the compiler can't elide it
  printf("depth=%d sp-ish local addr=%p\n", depth, &buf[0]);
  // Unreachable in practice: the guard page faults long before this. Only
  // here so gcc can't prove the recursion unbounded (-Werror=infinite-recursion).
  if (depth > 1000000)
    return buf[0];
  return eat_stack(depth + 1) + buf[0];
}

int
main(void)
{
  printf("stackbomb: recursing until the stack guard page faults...\n");
  eat_stack(0);
  printf("stackbomb: returned normally (unexpected — guard page did not trigger)\n");
  exit(0);
}
