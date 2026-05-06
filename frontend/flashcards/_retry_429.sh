#!/bin/bash
set -u
cd "$(dirname "$0")/images"

UA="halo-flashcards/1.0 (veera@recess.gg)"

JOBS=$(cat <<'EOF'
14_parthenon.jpg https://upload.wikimedia.org/wikipedia/commons/thumb/d/da/The_Parthenon_in_Athens.jpg/400px-The_Parthenon_in_Athens.jpg
15_creation_of_adam.jpg https://upload.wikimedia.org/wikipedia/commons/thumb/5/5b/Michelangelo_-_Creation_of_Adam_%28cropped%29.jpg/400px-Michelangelo_-_Creation_of_Adam_%28cropped%29.jpg
16_doryphoros.jpg https://upload.wikimedia.org/wikipedia/commons/thumb/b/b5/Polykleitos%2C_Doryphoros_%28Spear-bearer%29%2C_Roman_marble_copy_of_a_Greek_bronze_from_ca._450-440_BCE%2C_Museo_Archeologico_Nazionale%2C_Naples_%282%29.jpg/250px-Polykleitos%2C_Doryphoros_%28Spear-bearer%29%2C_Roman_marble_copy_of_a_Greek_bronze_from_ca._450-440_BCE%2C_Museo_Archeologico_Nazionale%2C_Naples_%282%29.jpg
17_venus_de_milo.jpg https://upload.wikimedia.org/wikipedia/commons/thumb/4/4e/Venus_de_Milo_Louvre_Ma399_n4.jpg/200px-Venus_de_Milo_Louvre_Ma399_n4.jpg
18_hagia_sophia.jpg https://upload.wikimedia.org/wikipedia/commons/thumb/2/22/Hagia_Sophia_Istanbul_2014.jpg/400px-Hagia_Sophia_Istanbul_2014.jpg
19_oba_head.jpg https://upload.wikimedia.org/wikipedia/commons/thumb/4/43/Oba_head_Benin.jpg/250px-Oba_head_Benin.jpg
20_el_anatsui.jpg https://upload.wikimedia.org/wikipedia/commons/thumb/1/18/El_Anatsui_-_Bleeding_Takari_II_%282007%29.jpg/300px-El_Anatsui_-_Bleeding_Takari_II_%282007%29.jpg
21_grande_odalisque.jpg https://upload.wikimedia.org/wikipedia/commons/thumb/4/4f/La_Grande_Odalisque%2C_Ingres%2C_1814.jpg/400px-La_Grande_Odalisque%2C_Ingres%2C_1814.jpg
23_giotto_lamentation.jpg https://upload.wikimedia.org/wikipedia/commons/thumb/3/3e/Giotto_di_Bondone_-_No._36_Scenes_from_the_Life_of_Christ_-_20._Lamentation_%28The_Mourning_of_Christ%29_-_WGA09283.jpg/400px-Giotto_di_Bondone_-_No._36_Scenes_from_the_Life_of_Christ_-_20._Lamentation_%28The_Mourning_of_Christ%29_-_WGA09283.jpg
24_marilyn_warhol.jpg https://upload.wikimedia.org/wikipedia/commons/thumb/4/47/Marilyn_Monroe_-_Warhol_-_1962.jpg/300px-Marilyn_Monroe_-_Warhol_-_1962.jpg
25_donatello_david.jpg https://upload.wikimedia.org/wikipedia/commons/thumb/3/3b/Donatello-Davide.jpg/200px-Donatello-Davide.jpg
26_bernini_david.jpg https://upload.wikimedia.org/wikipedia/commons/thumb/5/54/Bernini%27s_David.jpg/250px-Bernini%27s_David.jpg
27_calling_matthew.jpg https://upload.wikimedia.org/wikipedia/commons/thumb/4/4b/The_Calling_of_Saint_Matthew-Caravaggo_%281599-1600%29.jpg/400px-The_Calling_of_Saint_Matthew-Caravaggo_%281599-1600%29.jpg
28_judith_holofernes.jpg https://upload.wikimedia.org/wikipedia/commons/thumb/4/4a/Artemisia_Gentileschi_-_Judith_Slaying_Holofernes_%28Uffizi%29.jpg/250px-Artemisia_Gentileschi_-_Judith_Slaying_Holofernes_%28Uffizi%29.jpg
31_death_of_marat.jpg https://upload.wikimedia.org/wikipedia/commons/thumb/a/aa/Death_of_Marat_by_David.jpg/300px-Death_of_Marat_by_David.jpg
33_dejeuner.jpg https://upload.wikimedia.org/wikipedia/commons/thumb/9/90/Edouard_Manet_-_Le_d%C3%A9jeuner_sur_l%27herbe_-_Google_Art_Project.jpg/400px-Edouard_Manet_-_Le_d%C3%A9jeuner_sur_l%27herbe_-_Google_Art_Project.jpg
34_grande_jatte.jpg https://upload.wikimedia.org/wikipedia/commons/thumb/7/7d/A_Sunday_on_La_Grande_Jatte%2C_Georges_Seurat%2C_1884-86.jpg/400px-A_Sunday_on_La_Grande_Jatte%2C_Georges_Seurat%2C_1884-86.jpg
35_starry_night.jpg https://upload.wikimedia.org/wikipedia/commons/thumb/e/ea/Van_Gogh_-_Starry_Night_-_Google_Art_Project.jpg/400px-Van_Gogh_-_Starry_Night_-_Google_Art_Project.jpg
36_dinner_party.jpg https://upload.wikimedia.org/wikipedia/commons/thumb/9/97/Judy_Chicago%27s_The_Dinner_Party_%28Brooklyn_Museum%29.jpg/400px-Judy_Chicago%27s_The_Dinner_Party_%28Brooklyn_Museum%29.jpg
37_frida_kahlo.jpg https://upload.wikimedia.org/wikipedia/commons/thumb/1/1e/Frida_Kahlo_%28self_portrait%29.jpg/250px-Frida_Kahlo_%28self_portrait%29.jpg
38_matisse_dance.jpg https://upload.wikimedia.org/wikipedia/commons/thumb/a/a7/Matissedance.jpg/400px-Matissedance.jpg
39_ai_weiwei.jpg https://upload.wikimedia.org/wikipedia/commons/thumb/1/10/Ai_Weiwei_Sunflower_Seeds_Turbine_Hall_Tate_Modern.jpg/400px-Ai_Weiwei_Sunflower_Seeds_Turbine_Hall_Tate_Modern.jpg
40_persistence.jpg https://upload.wikimedia.org/wikipedia/commons/thumb/d/dd/The_Persistence_of_Memory.jpg/400px-The_Persistence_of_Memory.jpg
41_lavender_mist.jpg https://upload.wikimedia.org/wikipedia/commons/thumb/5/54/Jackson_Pollock%2C_Lavender_Mist%2C_1950%2C_National_Gallery_of_Art.jpg/400px-Jackson_Pollock%2C_Lavender_Mist%2C_1950%2C_National_Gallery_of_Art.jpg
42_guggenheim.jpg https://upload.wikimedia.org/wikipedia/commons/thumb/4/4f/Frank_Lloyd_Wright%27s_Guggenheim_Museum.jpg/300px-Frank_Lloyd_Wright%27s_Guggenheim_Museum.jpg
43_titian.jpg https://upload.wikimedia.org/wikipedia/commons/thumb/b/b1/Tizian_073.jpg/300px-Tizian_073.jpg
44_water_lilies.jpg https://upload.wikimedia.org/wikipedia/commons/thumb/a/aa/Claude_Monet_-_Water_Lilies_-_1906%2C_Ryerson.jpg/400px-Claude_Monet_-_Water_Lilies_-_1906%2C_Ryerson.jpg
EOF
)

# Sequential, with small delay, retry up to 3x on 429
echo "$JOBS" | while read -r name url; do
  [[ -z "$name" ]] && continue
  [[ -s "$name" ]] && { echo "SKIP $name (already have)"; continue; }
  for attempt in 1 2 3; do
    code=$(curl -sS -L --globoff -A "$UA" -o "$name" -w "%{http_code}" --max-time 30 "$url" 2>/dev/null || echo "ERR")
    if [[ "$code" == "200" ]] && [[ -s "$name" ]]; then
      echo "OK   $name"
      break
    fi
    rm -f "$name"
    if [[ "$code" == "429" ]]; then
      echo "RETRY $name (attempt $attempt, code 429)"
      sleep $((attempt * 2))
      continue
    fi
    echo "FAIL [$code] $name"
    break
  done
  sleep 0.4
done

echo "---"
echo "Got $(ls *.jpg 2>/dev/null | wc -l | tr -d ' ') of 44"
