import pygame, json, colorsys

# === Lecture du fichier result.txt (MiniSat) ===
def read_sat_solution(path):
    with open(path) as f:
        lines = f.readlines()
    # Vérification que la solution SAT est bien présente
    if lines[0].strip() != "SAT":
        raise ValueError("❌ Pas de solution SAT trouvée.")
    
    values = []
    for line in lines[1:]:
        for token in line.strip().split():
            # Extraction des variables SAT (ignorant les 0 et négations)
            if token != "0" and token.lstrip('-').isdigit():
                val = int(token)
                if val > 0:
                    values.append(val)

    return values

# === Décodage (var_id -> i,j,t) ===
def decode_solution(literals, n, nb_tuiles):
    placement = {}
    for var in literals:
        var -= 1  # Ajustement pour l'indexation Python
        i = var // (n * nb_tuiles)  # Ligne du placement
        j = (var % (n * nb_tuiles)) // nb_tuiles  # Colonne du placement
        t = (var % (n * nb_tuiles)) % nb_tuiles  # ID de la tuile
        placement[(i, j)] = t  # Enregistrement de l'emplacement de la tuile

    return placement

# === Génère une couleur vive à partir d'un entier ===
def get_color(val):
    hue = (val * 0.19) % 1.0  # Détermination de la teinte via un modulo
    r, g, b = colorsys.hsv_to_rgb(hue, 0.7, 0.95)  # Conversion en RVB
    return int(r * 255), int(g * 255), int(b * 255)

# === Affichage Pygame ===
def afficher_grille(tiles, placement, n):
    pygame.init()
    screen = pygame.display.set_mode((800, 800), pygame.RESIZABLE)
    pygame.display.set_caption("🧩 Tetravex Résolu")
    font = pygame.font.SysFont("Arial", 36, bold=True)

    running = True
    while running:
        screen.fill((230, 230, 230))  # Fond gris clair
        w, h = screen.get_size()
        tile_size = min(w, h) // n  # Ajustement dynamique de la taille des tuiles
        offset_x = (w - tile_size * n) // 2
        offset_y = (h - tile_size * n) // 2

        for (i, j), t_id in placement.items():
            tile = tiles[t_id]
            x = offset_x + j * tile_size
            y = offset_y + i * tile_size
            cx, cy = x + tile_size // 2, y + tile_size // 2  # Centre de la tuile

            # Définition des triangles formant la tuile
            triangles = {
                "haut": [(x, y), (x + tile_size, y), (cx, cy)],
                "droite": [(x + tile_size, y), (x + tile_size, y + tile_size), (cx, cy)],
                "bas": [(x + tile_size, y + tile_size), (x, y + tile_size), (cx, cy)],
                "gauche": [(x, y + tile_size), (x, y), (cx, cy)]
            }

            # Dessin des triangles avec bordure fine
            for side, points in triangles.items():
                color = get_color(tile[side])
                pygame.draw.polygon(screen, color, points)                  # Remplissage
                pygame.draw.polygon(screen, (30, 30, 30), points, width=1)  # Contour fin
            
            # Bordure de la tuile
            pygame.draw.rect(screen, (50, 50, 50), (x, y, tile_size, tile_size), 2)

            # Affichage du numéro de tuile centré
            label = font.render(str(t_id), True, (0, 0, 0))
            rect = label.get_rect(center=(cx, cy))
            screen.blit(label, rect)

        # Gestion des événements Pygame (fermeture, redimensionnement)
        for event in pygame.event.get():
            if event.type == pygame.QUIT or (
                event.type == pygame.KEYDOWN and event.key == pygame.K_ESCAPE):
                running = False
            if event.type == pygame.VIDEORESIZE:
                screen = pygame.display.set_mode((event.w, event.h), pygame.RESIZABLE)

        pygame.display.flip()

    pygame.quit()

# === Programme principal ===

# Chargement des tuiles à partir du fichier JSON
tiles = json.load(open("tuiles/tuiles_4x4.json"))
# Attention : le fichier JSON doit correspondre aux entrées utilisées dans "tetravex_sat.ml"

nb_tuiles = len(tiles)
n = int(nb_tuiles ** 0.5)  # Déduction de la taille de la grille
true_vars = read_sat_solution("result.sat")  # Lecture de la solution SAT
solution = decode_solution(true_vars, n, nb_tuiles)  # Décodage en positions
afficher_grille(tiles, solution, n)  # Affichage graphique