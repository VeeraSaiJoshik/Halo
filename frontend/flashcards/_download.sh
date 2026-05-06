#!/bin/bash
set -u
cd "$(dirname "$0")/images"

UA="halo-flashcards/1.0 (veera@recess.gg)"

JOBS=$(cat <<'EOF'
01_mona_lisa.jpg https://upload.wikimedia.org/wikipedia/commons/thumb/e/ec/Mona_Lisa%2C_by_Leonardo_da_Vinci%2C_from_C2RMF_retouched.jpg/300px-Mona_Lisa%2C_by_Leonardo_da_Vinci%2C_from_C2RMF_retouched.jpg
02_nighthawks.jpg https://upload.wikimedia.org/wikipedia/commons/thumb/a/a8/Nighthawks_by_Edward_Hopper_1942.jpg/400px-Nighthawks_by_Edward_Hopper_1942.jpg
03_liberty_leading.jpg https://upload.wikimedia.org/wikipedia/commons/thumb/5/5d/Eug%C3%A8ne_Delacroix_-_La_libert%C3%A9_guidant_le_peuple.jpg/300px-Eug%C3%A8ne_Delacroix_-_La_libert%C3%A9_guidant_le_peuple.jpg
04_nude_descending.jpg https://upload.wikimedia.org/wikipedia/commons/thumb/c/c0/Duchamp_-_Nude_Descending_a_Staircase.jpg/250px-Duchamp_-_Nude_Descending_a_Staircase.jpg
05_birth_of_venus.jpg https://upload.wikimedia.org/wikipedia/commons/thumb/2/26/Sandro_Botticelli_-_La_nascita_di_Venere_-_Google_Art_Project_-_edited.jpg/400px-Sandro_Botticelli_-_La_nascita_di_Venere_-_Google_Art_Project_-_edited.jpg
06_jahangir.jpg https://upload.wikimedia.org/wikipedia/commons/thumb/a/a7/Jahangir_preferring_a_sufi_shaikh_to_kings.jpg/250px-Jahangir_preferring_a_sufi_shaikh_to_kings.jpg
07_demoiselles.jpg https://upload.wikimedia.org/wikipedia/en/thumb/4/4c/Les_Demoiselles_d%27Avignon.jpg/270px-Les_Demoiselles_d%27Avignon.jpg
08_school_of_athens.jpg https://upload.wikimedia.org/wikipedia/commons/thumb/4/49/%22The_School_of_Athens%22_by_Raffaello_Sanzio_da_Urbino.jpg/400px-%22The_School_of_Athens%22_by_Raffaello_Sanzio_da_Urbino.jpg
09_kerry_marshall.jpg https://upload.wikimedia.org/wikipedia/commons/thumb/7/7a/Kerry_James_Marshall_-_Untitled_%28Studio%29_2014.jpg/300px-Kerry_James_Marshall_-_Untitled_%28Studio%29_2014.jpg
10_american_gothic.jpg https://upload.wikimedia.org/wikipedia/commons/thumb/c/cc/Grant_Wood_-_American_Gothic_-_Google_Art_Project.jpg/300px-Grant_Wood_-_American_Gothic_-_Google_Art_Project.jpg
11_nefertiti.jpg https://upload.wikimedia.org/wikipedia/commons/thumb/a/a0/Nofretete_Neues_Museum.jpg/250px-Nofretete_Neues_Museum.jpg
12_vietnam_memorial.jpg https://upload.wikimedia.org/wikipedia/commons/thumb/1/1f/Vietnam_Veterans_Memorial_reflection.jpg/400px-Vietnam_Veterans_Memorial_reflection.jpg
13_augustus.jpg https://upload.wikimedia.org/wikipedia/commons/thumb/9/9e/Statue-Augustus.jpg/250px-Statue-Augustus.jpg
14_parthenon.jpg https://upload.wikimedia.org/wikipedia/commons/thumb/d/da/The_Parthenon_in_Athens.jpg/400px-The_Parthenon_in_Athens.jpg
15_creation_of_adam.jpg https://upload.wikimedia.org/wikipedia/commons/thumb/5/5b/Michelangelo_-_Creation_of_Adam_%28cropped%29.jpg/400px-Michelangelo_-_Creation_of_Adam_%28cropped%29.jpg
16_doryphoros.jpg https://upload.wikimedia.org/wikipedia/commons/thumb/b/b5/Polykleitos%2C_Doryphoros_%28Spear-bearer%29%2C_Roman_marble_copy_of_a_Greek_bronze_from_ca._450-440_BCE%2C_Museo_Archeologico_Nazionale%2C_Naples_%282%29.jpg/250px-Polykleitos%2C_Doryphoros_%28Spear-bearer%29%2C_Roman_marble_copy_of_a_Greek_bronze_from_ca._450-440_BCE%2C_Museo_Archeologico_Nazionale%2C_Naples_%282%29.jpg
17_venus_de_milo.jpg https://upload.wikimedia.org/wikipedia/commons/thumb/4/4e/Venus_de_Milo_Louvre_Ma399_n4.jpg/200px-Venus_de_Milo_Louvre_Ma399_n4.jpg
18_hagia_sophia.jpg https://upload.wikimedia.org/wikipedia/commons/thumb/2/22/Hagia_Sophia_Istanbul_2014.jpg/400px-Hagia_Sophia_Istanbul_2014.jpg
19_oba_head.jpg https://upload.wikimedia.org/wikipedia/commons/thumb/4/43/Oba_head_Benin.jpg/250px-Oba_head_Benin.jpg
20_el_anatsui.jpg https://upload.wikimedia.org/wikipedia/commons/thumb/1/18/El_Anatsui_-_Bleeding_Takari_II_%282007%29.jpg/300px-El_Anatsui_-_Bleeding_Takari_II_%282007%29.jpg
21_grande_odalisque.jpg https://upload.wikimedia.org/wikipedia/commons/thumb/4/4f/La_Grande_Odalisque%2C_Ingres%2C_1814.jpg/400px-La_Grande_Odalisque%2C_Ingres%2C_1814.jpg
22_arnolfini.jpg https://upload.wikimedia.org/wikipedia/commons/thumb/3/33/Van_Eyck_-_Arnolfini_Portrait.jpg/250px-Van_Eyck_-_Arnolfini_Portrait.jpg
23_giotto_lamentation.jpg https://upload.wikimedia.org/wikipedia/commons/thumb/3/3e/Giotto_di_Bondone_-_No._36_Scenes_from_the_Life_of_Christ_-_20._Lamentation_%28The_Mourning_of_Christ%29_-_WGA09283.jpg/400px-Giotto_di_Bondone_-_No._36_Scenes_from_the_Life_of_Christ_-_20._Lamentation_%28The_Mourning_of_Christ%29_-_WGA09283.jpg
24_marilyn_warhol.jpg https://upload.wikimedia.org/wikipedia/commons/thumb/4/47/Marilyn_Monroe_-_Warhol_-_1962.jpg/300px-Marilyn_Monroe_-_Warhol_-_1962.jpg
25_donatello_david.jpg https://upload.wikimedia.org/wikipedia/commons/thumb/3/3b/Donatello-Davide.jpg/200px-Donatello-Davide.jpg
26_bernini_david.jpg https://upload.wikimedia.org/wikipedia/commons/thumb/5/54/Bernini%27s_David.jpg/250px-Bernini%27s_David.jpg
27_calling_matthew.jpg https://upload.wikimedia.org/wikipedia/commons/thumb/4/4b/The_Calling_of_Saint_Matthew-Caravaggo_%281599-1600%29.jpg/400px-The_Calling_of_Saint_Matthew-Caravaggo_%281599-1600%29.jpg
28_judith_holofernes.jpg https://upload.wikimedia.org/wikipedia/commons/thumb/4/4a/Artemisia_Gentileschi_-_Judith_Slaying_Holofernes_%28Uffizi%29.jpg/250px-Artemisia_Gentileschi_-_Judith_Slaying_Holofernes_%28Uffizi%29.jpg
29_migrant_mother.jpg https://upload.wikimedia.org/wikipedia/commons/thumb/5/54/Lange-MigrantMother02.jpg/250px-Lange-MigrantMother02.jpg
30_rembrandt_self.jpg https://upload.wikimedia.org/wikipedia/commons/thumb/b/bd/Rembrandt_van_Rijn_-_Self-Portrait_-_Google_Art_Project.jpg/250px-Rembrandt_van_Rijn_-_Self-Portrait_-_Google_Art_Project.jpg
31_death_of_marat.jpg https://upload.wikimedia.org/wikipedia/commons/thumb/a/aa/Death_of_Marat_by_David.jpg/300px-Death_of_Marat_by_David.jpg
32_saturn_goya.jpg https://upload.wikimedia.org/wikipedia/commons/thumb/8/82/Francisco_de_Goya%2C_Saturno_devorando_a_su_hijo_%281819-1823%29.jpg/250px-Francisco_de_Goya%2C_Saturno_devorando_a_su_hijo_%281819-1823%29.jpg
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

fetch_one() {
  local name="$1" url="$2"
  local code
  code=$(curl -sS -L --globoff -A "$UA" -o "$name" -w "%{http_code}" --max-time 30 "$url" 2>/dev/null || echo "ERR")
  if [[ "$code" != "200" ]] || [[ ! -s "$name" ]]; then
    echo "FAIL [$code] $name"
    rm -f "$name"
    return 1
  fi
  echo "OK   $name"
}
export -f fetch_one
export UA

# 4 parallel workers via xargs
echo "$JOBS" | xargs -n 2 -P 4 bash -c 'fetch_one "$0" "$1"'
echo "---"
echo "Got $(ls *.jpg 2>/dev/null | wc -l | tr -d ' ') of 44"
