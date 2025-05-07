# 🧩 Tetravex-SAT

[![Build](https://img.shields.io/badge/build-passing-brightgreen)](https://github.com/<ton-user>/<ton-repo>/actions)
[![OCaml](https://img.shields.io/badge/OCaml-≥4.10-blue)](https://ocaml.org/)
[![Python](https://img.shields.io/badge/Python-≥3.6-yellow)](https://python.org)
[![License](https://img.shields.io/badge/license-MIT-lightgrey)](LICENSE)

**Tetravex-SAT** est une application permettant de résoudre automatiquement des grilles du jeu Tetravex en traduisant le problème sous forme logique (SAT), puis en l'interprétant via un solveur SAT. Le projet allie programmation fonctionnelle (OCaml), algorithmique logique (SAT), et interface graphique (Python + pygame).

ℹ️ Le mode d’emploi détaillé est disponible dans le fichier [`LISEZMOI.txt`](./LISEZMOI.txt).

---

### 🔧 PRÉREQUIS

1. 🧠 OCaml (≥ 4.10) — pour générer le fichier DIMACS
   ➜ https://ocaml.org

2. 🛠️ Un solveur SAT compatible DIMACS (par exemple `MiniSAT` ou `HAL`)
   Ou bien notre SAT solver (dossier src/ et include/)

3. 🐍 Python 3 (≥ 3.6) avec les bibliothèques suivantes :
   - pygame
   - colorsys (standard)
   ➜ Installation : `pip install pygame`

4. (Facultatif) VS Code ou éditeur similaire avec support Markdown (`.md`) pour lire la documentation.
---

### 🛠️ Compilation et exécution du projet Tetravex-SAT

1. **Compiler le projet** :
```bash
make
```

2. **Installer localement les exécutables** :
```bash
make install PREFIX=$(pwd)
```

3. **Générer l’instance du problème Tetravex au format DIMACS** :
```bash
ocaml tetravex_sat.ml
```

4. **Résoudre le problème avec un solveur SAT** (ici `hal`) :
```bash
./hal tetravex.cnf -s result.sat
```
👉 Cela produit un fichier `result.sat` contenant l’assignation des variables.

5. **Interpréter la solution dans une interface graphique Python** :
```bash
python3 interface.py
```
👉 Cette étape affiche graphiquement la solution du Tetravex, en lisant :
- les tuiles depuis `tuiles_[tailleGrille].json`
- et la solution SAT depuis `result.sat`

### **Auteurs**
Racim ZENATI - Augustin MANIAK - Arris ZAIDI
