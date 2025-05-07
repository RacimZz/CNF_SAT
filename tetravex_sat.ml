(* === Types et variables === *)

(* Type représentant une tuile avec ses quatre côtés et son identifiant *)
type tuile = {
  id : int;
  haut : int;
  bas : int;
  gauche : int;
  droite : int;
}

(* Fonction pour générer un identifiant unique pour une variable (tuile t en (i,j)) *)
let var_id (i : int) (j : int) (t : int) (n : int) (nb_tuiles : int) : int =
  (i * n * nb_tuiles) + (j * nb_tuiles) + t + 1

(* === Génération des contraintes SAT pour le jeu Tetravex === *)

(* Clause : chaque case (i, j) reçoit au moins une tuile *)
(* On génère une clause contenant toutes les variables représentant chaque tuile possible à cette position.
   Cela garantit qu'au moins une tuile est placée dans chaque case. *)
   let clause_case (i : int) (j : int) (nb_tuiles : int) (n : int) : int list =
    List.init nb_tuiles (fun t -> var_id i j t n nb_tuiles)
  
  (* Clauses d'exclusivité : une tuile ne peut apparaître qu'une seule fois *)
  (* Pour chaque paire de positions différentes, on ajoute une clause interdisant que la tuile t
     soit présente sur ces deux positions à la fois. Cela force une tuile à n'apparaître qu'une seule fois. *)
  let exclusivite_tuile (t : int) (n : int) (nb_tuiles : int) : int list list =
    let positions = List.init n (fun i -> List.init n (fun j -> (i, j))) |> List.flatten in
    List.flatten (
      List.map (fun (i1, j1) ->
        List.filter_map (fun (i2, j2) ->
          if (i1, j1) < (i2, j2) then
            Some [- (var_id i1 j1 t n nb_tuiles); - (var_id i2 j2 t n nb_tuiles)]
          else None
        ) positions
      ) positions
    )
  
  (* Contrainte d’adjacence horizontale : droite(t1) doit correspondre à gauche(t2) *)
  (* Si ce n’est pas le cas, on interdit que t1 soit à (i,j) et t2 à (i,j+1) en même temps *)
  let contrainte_horizontale (t1 : tuile) (t2 : tuile)
      (i : int) (j : int) (n : int) (nb_tuiles : int) : int list option =
    if t1.droite <> t2.gauche then
      let v1 = var_id i j t1.id n nb_tuiles in
      let v2 = var_id i (j+1) t2.id n nb_tuiles in
      Some [-v1; -v2]
    else None
  
  (* Contrainte d’adjacence verticale : bas(t1) doit correspondre à haut(t2) *)
  (* Si ce n’est pas le cas, on interdit que t1 soit à (i,j) et t2 à (i+1,j) en même temps *)
  let contrainte_verticale (t1 : tuile) (t2 : tuile)
      (i : int) (j : int) (n : int) (nb_tuiles : int) : int list option =
    if t1.bas <> t2.haut then
      let v1 = var_id i j t1.id n nb_tuiles in
      let v2 = var_id (i+1) j t2.id n nb_tuiles in
      Some [-v1; -v2]
    else None
  
  (* Génère toutes les contraintes d’adjacence pour la grille n x n *)
  (* Pour chaque case (i,j), on teste toutes les paires de tuiles possibles t1 et t2,
     et on ajoute les contraintes d’incompatibilité horizontale et verticale si nécessaire.
     Chaque clause est annotée avec la position (i,j) où elle s’applique. *)
  let contraintes_adjacence (tuiles : tuile list) (n : int) : (int * int * int list) list =
    let nb_tuiles = List.length tuiles in
    let clauses = ref [] in
    for i = 0 to n - 1 do
      for j = 0 to n - 1 do
        List.iter (fun t1 ->
          List.iter (fun t2 ->
            if j < n - 1 then (  (* Vérifie s’il y a une case à droite *)
              match contrainte_horizontale t1 t2 i j n nb_tuiles with
              | Some clause -> clauses := (i, j, clause) :: !clauses
              | None -> ()
            );
            if i < n - 1 then (  (* Vérifie s’il y a une case en bas *)
              match contrainte_verticale t1 t2 i j n nb_tuiles with
              | Some clause -> clauses := (i, j, clause) :: !clauses
              | None -> ()
            )
          ) tuiles
        ) tuiles
      done
    done;
    !clauses
  (* === Fin de la génération des contraintes === *)  

(* === Écriture du fichier DIMACS === *)

(* Écrit toutes les clauses logiques dans un fichier au format DIMACS .cnf pour le problème Tetravex *)
let write_dimacs (filename : string)
    (n : int)  (* Taille de la grille n x n *)
    (nb_vars : int)  (* Nombre total de variables dans la formule CNF *)
    (clauses_case : int list list)  (* Clauses : chaque case reçoit au moins une tuile *)
    (clauses_exclus : int list list)  (* Clauses : chaque tuile apparaît à une seule position *)
    (clauses_adj : (int * int * int list) list)  (* Clauses d'adjacence annotées par case (i,j) *) : unit =

  let oc = open_out filename in  (* Ouvre le fichier en écriture *)

  (* === Écriture de l’en-tête DIMACS === *)
  Printf.fprintf oc "c Fichier DIMACS pour Tetravex généré automatiquement\n";
  Printf.fprintf oc "c Format: 1 clause par ligne, 0 final pour terminer chaque clause\n";
  Printf.fprintf oc "p cnf %d %d\n"
    nb_vars
    (List.length clauses_case + List.length clauses_exclus + List.length clauses_adj);

  (* === 1. Contraintes : chaque case doit contenir au moins une tuile === *)
  Printf.fprintf oc "c === Chaque case doit contenir au moins une tuile ===\n";
  List.iter (fun cl ->       (* Pour chaque clause *)
    List.iter (fun lit -> Printf.fprintf oc "%d " lit) cl;  (* Écrit chaque littéral *)
    Printf.fprintf oc "0\n"  (* Termine la clause par 0 *)
  ) clauses_case;

  (* === 2. Contraintes : chaque tuile apparaît à un seul endroit === *)
  Printf.fprintf oc "c === Chaque tuile apparaît à un seul endroit ===\n";
  List.iter (fun cl ->
    List.iter (fun lit -> Printf.fprintf oc "%d " lit) cl;
    Printf.fprintf oc "0\n"
  ) clauses_exclus;

  (* === 3. Contraintes d'adjacence === *)
  Printf.fprintf oc "c === Contraintes d'adjacence entre cases ===\n";

  (* Regroupe les clauses d’adjacence par case (i,j) pour les commenter lors de l’écriture *)
  let contraintes_par_case =
    List.fold_left (fun acc (i, j, clause) ->
      let prev = try List.assoc (i, j) acc with Not_found -> [] in
      ((i, j), clause :: prev) :: (List.remove_assoc (i, j) acc)
    ) [] clauses_adj
  in

  (* Parcours de chaque case (i,j) de la grille *)
  for i = 0 to n - 1 do
    for j = 0 to n - 1 do
      (* Écrit un commentaire pour indiquer à quelles cases les contraintes s'appliquent *)
      Printf.fprintf oc "c Contraintes d'adjacence pour la case (%d,%d)\n" i j;
      match List.assoc_opt (i, j) contraintes_par_case with
      | Some clauses ->  (* Si des clauses existent pour cette case *)
          List.iter (fun cl ->
            List.iter (fun lit -> Printf.fprintf oc "%d " lit) cl;
            Printf.fprintf oc "0\n"
          ) clauses
      | None -> ()  (* Aucun voisin : pas de clause *)
    done
  done;

  close_out oc  (* Ferme le fichier *)


(* === Main === *)

(* Exemple de grille à encoder *)
let () =
(********************* A Completer par l'entree choisie ****************** *)
let tuiles = [
  {id=0; haut=1; bas=2; gauche=1; droite=2};
  {id=1; haut=1; bas=2; gauche=2; droite=3};
  {id=2; haut=1; bas=2; gauche=3; droite=4};
  {id=3; haut=1; bas=2; gauche=4; droite=5};

  {id=4; haut=2; bas=3; gauche=1; droite=2};
  {id=5; haut=2; bas=3; gauche=2; droite=3};
  {id=6; haut=2; bas=3; gauche=3; droite=4};
  {id=7; haut=2; bas=3; gauche=4; droite=5};

  {id=8; haut=3; bas=4; gauche=1; droite=2};
  {id=9; haut=3; bas=4; gauche=2; droite=3};
  {id=10; haut=3; bas=4; gauche=3; droite=4};
  {id=11; haut=3; bas=4; gauche=4; droite=5};

  {id=12; haut=4; bas=5; gauche=1; droite=2};
  {id=13; haut=4; bas=5; gauche=2; droite=3};
  {id=14; haut=4; bas=5; gauche=3; droite=4};
  {id=15; haut=4; bas=5; gauche=4; droite=5};
] in
let n = 4 in


(***************************************************************************)
  (* Nombre total de tuiles dans la grille *)
  let nb_tuiles = List.length tuiles in

  (* === Génération des clauses de type 1 : chaque case reçoit une tuile === *)
  let clauses_case =
    List.init n (fun i ->                  (* Pour chaque ligne i *)
      List.init n (fun j ->                (* Pour chaque colonne j *)
        clause_case i j nb_tuiles n        (* Génère les clauses pour la case (i, j) *)
      )
    ) |> List.flatten                      (* Aplatit la liste 2D en une seule liste *)
  in

  (* === Génération des clauses de type 2 : chaque tuile est placée à un seul endroit === *)
  let clauses_exclus =
    List.init nb_tuiles (fun t ->          (* Pour chaque tuile t *)
      exclusivite_tuile t n nb_tuiles      (* Génère les clauses d’unicité pour la tuile t *)
    ) |> List.flatten
  in

  (* === Génération des clauses de type 3 : contraintes d'adjacence === *)
  let clauses_adj = contraintes_adjacence tuiles n in

  (* === Calcul du nombre total de variables (chaque case x chaque tuile) === *)
  let nb_vars = n * n * nb_tuiles in

  (* === Écriture finale du fichier CNF au format DIMACS === *)
  write_dimacs "tetravex.cnf" n nb_vars clauses_case clauses_exclus clauses_adj;

  (* === Affichage d’un résumé dans le terminal === *)
  Printf.printf "✅ Fichier tetravex.cnf généré avec %d variables et %d clauses.\n"
    nb_vars (List.length clauses_case + List.length clauses_exclus + List.length clauses_adj)
