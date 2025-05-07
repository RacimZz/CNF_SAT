#ifndef SOLVER_SOLVE_H_
# define SOLVER_SOLVE_H_

# include <cnf.h>
# include <stdbool.h>

int solve (struct cnf *, int8_t *, size_t *);

static double *jwos_j = NULL;

#endif /* SOLVER_SOLVE_H_ */
