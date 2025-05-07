#include <parser.h>
#include <string.h>
#include <sys/types.h>

static ssize_t
llabs (x)
     ssize_t x;
{
  if (x < 0)
    return -x;

  return x;
}

int
parse_dimacs (fp, cnf)
     FILE	*fp;
     struct cnf *cnf;
{
  char c;
  size_t i;

  for (; (c = fgetc (fp));)
    {
      switch (c)
	{
	case 'c':
	  for (; c != '\n' && c != 0; c = fgetc (fp))
	    ;
	  break;
	case 'p':
	  if (fscanf (fp, " cnf %lu %lu", &cnf->var_n, &cnf->clause_n) != 2)
	    {
	      fprintf (stderr, "hal: invalid problem string\n");
	      return 1;
	    }
	  goto clauses;
	default:
	  fprintf (stderr, "hal: invalid character: %c\n", c);
	  return 1;
	}
    }

  return 1;
 clauses:
  if (init_cnf (cnf, cnf->var_n, cnf->clause_n))
      return -1;

  for (i = 0; i < cnf->clause_n;)
    {
      /* if the clause is valid, this will be set to 0 and the total
       * number of clauses decreased
       */
      int skip = 1;

      for (;;)
	{
	  char c;
	  ssize_t v = 0;
	  size_t w;
	  int8_t x, y;

	  switch ((c = fgetc (fp)))
	    {
	    case 'c':
	      for (; c != '\n' && c != 0; c = fgetc (fp))
		;
	      continue;
	    case ' ':
	    case '\n':
	    case '\t':
	    case '\r':
	      for (; c == ' ' || c == '\n' || c == '\t' || c == '\r'; c = fgetc (fp))
		;
	      if (c != 0)
		ungetc (c, fp);
	      continue;
	    default:
	      ungetc (c, fp);
	      break;
	    }

	  if (fscanf (fp, " %ld", &v) != 1)
	    {
	      fprintf (stderr, "hal: failed to read character\n");
	      return 1;
	    }

	  if (v == 0)
	      break;

	  /* indexing starts at 1 */
	  w = llabs (v) - 1;

	  if (w > cnf->var_n)
	    {
	      fprintf (stderr, "hal: invalid variable: %lu\n", w);

	      return 1;
	    }

	  y = v < 0 ? -1 : 1;
	  x = cnf->clauses[i][w];

	  if (x != y && x != 0)
	    skip = 0;

	  cnf->clauses[i][w] = y;
	}

      if (!skip)
	{
	  /* reset clause */
	  memset (cnf->clauses[i], 0, cnf->var_n);
	  cnf->clause_n -= 1;
	}
      else
	i += 1;
    }

  return 0;
}
