#ifndef SOLVER_CNF_H_
# define SOLVER_CNF_H_

# include <stddef.h>
# include <stdint.h>

typedef int8_t * clause_t;

/*
 * Inside a clause, variables can either have the
 * value 0 (absent), 1 (positive) or -1 (negative).
 */
struct cnf {
  size_t	var_n;
  size_t	clause_n;
  clause_t	*clauses;
  size_t	_clause_c;
};

int	init_cnf (struct cnf *, size_t, size_t);
int	copy_cnf (struct cnf *, struct cnf *);
size_t	add_clause (struct cnf *);
int	del_clause (struct cnf *, size_t);
void	destroy_cnf (struct cnf *);

#endif /* SOLVER_CNF_H_ */
