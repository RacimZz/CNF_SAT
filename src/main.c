#include <getopt.h>
#include <parser.h>
#include <cnf.h>
#include <linux/limits.h>
#include <solve.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>

/* Traitement d'un fichier contenant une formule CNF.
   Objectif : analyser, résoudre et afficher le résultat.
   Attention : gestion fine de la mémoire et des erreurs nécessaire. */
int
process_file (fp, outfp)
     FILE *fp;
     FILE *outfp;
{
  int		r = 1;
  size_t	rcl = 0;
  int8_t	*sig;
  int		sol = -1;
  struct cnf	cnf;

  clock_t	beg, end;

  (void)beg;
  (void)end;

  /* Lecture et parsing du fichier DIMACS */
  if ((r = parse_dimacs (fp, &cnf)))
    {
      fprintf (stderr, "hal: failed to read file\n");
      return r;
    }

  /* Allocation mémoire pour la solution potentielle */
  sig = malloc (cnf.var_n);

  if (!sig)
    {
        destroy_cnf (&cnf);
	goto cleanup;
    }

  memset (sig, 0, cnf.var_n);

  /* Début du chronométrage pour mesurer la performance */
  beg = clock ();
  sol = solve (&cnf, sig, &rcl);
  end = clock ();

  /* Vérification du résultat et affichage */
  switch (sol)
    {
    case 1:
      {
	size_t i;

	if (outfp)
	  fputs ("SAT\n", outfp);

	/* Affichage de la solution trouvée */
	for (i = 0; i < cnf.var_n; i++)
	  {
	    if (i)
	      putchar (' ');
	    if (sig[i] < 0)
	      putchar ('-');
	    printf ("%ld", i + 1);

	    if (outfp)
	      {
		if (sig[i] < 0)
		  fputc ('-', outfp);

		fprintf (outfp, "%ld ", i + 1);
	      }
	  }

	putchar ('\n');

	if (outfp)
	  {
	    fputs ("0\n", outfp);
	  }

	r = 0;
	goto cleanup;
      }
    case 0:
      /* L'affichage du symbole ⊥ pour indiquer une contradiction */
      puts ("⊥");

      if (outfp)
	fputs ("UNSAT", outfp);

      r = 1;
      goto cleanup;
    default:
      fprintf (stderr, "hal: failed to compute satisfiability\n");
      break;
    }

 cleanup:

#ifdef _HEURISTICS_JWOS
  free (jwos_j);
#endif

#ifdef _PERF
  /* Affichage des statistiques de performance */
  if (sol >= 0)
    printf ("solved in %ld calls (%f seconds)\n",
	    rcl, (double)(end - beg) / CLOCKS_PER_SEC);
#endif
  free (sig);

  return r;
}

/* Fonction principale : gestion des options, ouverture des fichiers et traitement CNF */
int
main (argc, argv)
     int argc;
     char *const argv[];
{
  FILE	*outfp;
  char	outfile[PATH_MAX] = { 0 };
  int	opt, i, r = 0;

  /* Lecture des arguments en ligne de commande */
  while ((opt = getopt (argc, argv, "s:")) != -1)
    {
      switch (opt)
	{
	case 's':
	  strcpy (outfile, optarg);
	  break;
	default:
	  fprintf (stderr, "Usage: %s [-s outfile] [file...]\n", argv[0]);
	  return EXIT_FAILURE;
	}
    }

  /* Gestion du fichier de sortie */
  if (strlen (outfile) == 0)
    outfp = NULL;
  else
    {
      outfp = fopen (outfile, "w");

      if (!outfp)
	{
	  perror ("hal");

	  return EXIT_FAILURE;
	}
    }

  /* Gestion des fichiers d'entrée */
  if (optind >= argc)
    {
      return process_file (stdin, outfp);
    }

  for (i = optind; i < argc; i++)
    {
      int s;
      FILE *fp;

      /* Possibilité de traiter l'entrée standard */
      if ((s = (strcmp (argv[i], "-") == 0)))
	fp = stdin;
      else
	fp = fopen (argv[i], "r");

      printf ("%s: ", argv[i]);

      r |= process_file (fp, outfp);

      if (!s)
	fclose (fp);
    }

  if (outfp)
    fclose (outfp);

  return r;
}