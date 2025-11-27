#!/bin/bash
##############################################
#                   CONFIG
##############################################
SOURCE_DIR="./Documents/Edition-files"
DEST_DIR="./Documents/Graph"
TRANSLATIONS_DIR="./Translations/Mermaid"
MMDC="./node_modules/.bin/mmdc"
MERMAID_CONFIG="./mermaid-config.json"

# Déclaration globale du tableau associatif
declare -A TRANSLATIONS

# Variables pour les options
PROCESS_ALL=false
TARGET_FILES=()

##############################################
#               AIDE
##############################################
show_help() {
    cat << EOF
Usage: $0 [OPTIONS] [FICHIERS...]

Options:
  -a, --all              Générer tous les fichiers (défaut si aucun fichier spécifié)
  -h, --help             Afficher cette aide
  
Arguments:
  FICHIERS               Liste de fichiers .mmd à traiter (avec ou sans .mmd)
                         Peut être un nom de fichier ou un chemin relatif
                         
Exemples:
  $0 -a                                    # Tout générer
  $0 diagram1.mmd diagram2.mmd            # Fichiers spécifiques
  $0 subfolder/diagram.mmd                # Fichier dans un sous-dossier
  $0 diagram1 diagram2                    # Sans extension .mmd

EOF
}

##############################################
#            PARSING ARGUMENTS
##############################################
parse_arguments() {
    if [[ $# -eq 0 ]]; then
        PROCESS_ALL=true
        return
    fi
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -a|--all)
                PROCESS_ALL=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            -*)
                echo "❌ Option inconnue : $1"
                show_help
                exit 1
                ;;
            *)
                TARGET_FILES+=("$1")
                shift
                ;;
        esac
    done
    
    # Si des fichiers sont spécifiés, on ne traite pas tout
    if [[ ${#TARGET_FILES[@]} -gt 0 ]]; then
        PROCESS_ALL=false
    else
        PROCESS_ALL=true
    fi
}

##############################################
#          RECHERCHE DE FICHIERS
##############################################
find_file() {
    local target="$1"
    
    # Ajouter .mmd si absent
    if [[ ! "$target" =~ \.mmd$ ]]; then
        target="${target}.mmd"
    fi
    
    # Chercher le fichier
    local found=$(find "$SOURCE_DIR" -type f -name "$target" -o -path "*/$target" | head -n 1)
    
    if [[ -z "$found" ]]; then
        echo "❌ Fichier introuvable : $target" >&2
        return 1
    fi
    
    echo "$found"
    return 0
}

get_files_to_process() {
    if [[ "$PROCESS_ALL" == true ]]; then
        find "$SOURCE_DIR" -type f -name "*.mmd"
    else
        for target in "${TARGET_FILES[@]}"; do
            find_file "$target"
        done
    fi
}

##############################################
#               UTILITAIRES
##############################################
# Chargement d'un fichier JSON en tableau associatif
load_translations() {
    local lang="$1"
    local file="$TRANSLATIONS_DIR/$lang.json"
    
    echo "→ Chargement des traductions : $file"
    
    if [[ ! -f "$file" ]]; then
        echo "❌ Fichier de traduction introuvable : $file"
        return 1
    fi
    
    # Réinitialiser le tableau
    TRANSLATIONS=()
    
    echo "→ Parsing JSON..."
    
    # Charger dans le tableau global
    while IFS="=" read -r key value; do
        TRANSLATIONS["$key"]="$value"
    done < <(jq -r 'to_entries | .[] | "\(.key)=\(.value)"' "$file")
    
    echo "→ ${#TRANSLATIONS[@]} traductions chargées"
    
    return 0
}

# Remplacement des placeholders {{KEY}}
apply_translations() {
    local file="$1"
    local content=$(cat "$file")
    
    for key in "${!TRANSLATIONS[@]}"; do
        local value="${TRANSLATIONS[$key]}"
        # Échapper les caractères spéciaux pour sed
        local escaped_value=$(echo "$value" | sed 's/[&/\]/\\&/g')
        content=$(echo "$content" | sed "s/{{$key}}/$escaped_value/g")
    done
    
    echo "$content"
}

# Convertit un .mmd en .svg
convert_to_svg() {
    local input="$1"
    local output="$2"
    
    # Si un fichier de config existe, l'utiliser
    if [[ -f "$MERMAID_CONFIG" ]]; then
        $MMDC -i "$input" -o "$output" -c "$MERMAID_CONFIG" -b transparent >/dev/null 2>&1
    else
        # Sinon, utiliser le thème dark en ligne de commande
        $MMDC -i "$input" -o "$output" -t dark -b transparent >/dev/null 2>&1
    fi
    
    return $?
}

# Formatage du temps (secondes -> HH:MM:SS ou MM:SS)
format_time() {
    local seconds=$1
    
    if [[ $seconds -lt 60 ]]; then
        printf "%ds" "$seconds"
    elif [[ $seconds -lt 3600 ]]; then
        printf "%dm %ds" $((seconds / 60)) $((seconds % 60))
    else
        printf "%dh %dm %ds" $((seconds / 3600)) $(((seconds % 3600) / 60)) $((seconds % 60))
    fi
}

# Affichage barre progression avec temps restant
show_progress() {
    local current="$1"
    local total="$2"
    local start_time="$3"
    
    local percentage=$((current * 100 / total))
    local bar_length=40
    local filled=$((percentage * bar_length / 100))
    local empty=$((bar_length - filled))
    
    # Calcul du temps écoulé
    local elapsed=$(($(date +%s) - start_time))
    
    # Calcul du temps restant (seulement après quelques fichiers)
    local eta_str=""
    if [[ $current -gt 0 ]]; then
        local avg_time=$((elapsed / current))
        local remaining=$((total - current))
        local eta=$((avg_time * remaining))
        eta_str=" | ETA: $(format_time $eta)"
    fi
    
    # Affichage de la barre
    printf "\033[J["
    printf "%${filled}s" | tr ' ' '#'
    printf "%${empty}s" | tr ' ' '-'
    printf "] %3d%% (%d/%d)%s\r" "$percentage" "$current" "$total" "$eta_str"
}

##############################################
#           TRAITEMENT PAR LANGUE
##############################################
process_language() {
    local lang="$1"
    
    echo ""
    echo "=============================="
    echo "   🌐 Langue : $lang"
    echo "=============================="
    
    load_translations "$lang" || return 1
    
    local OUTPUT="$DEST_DIR/$lang"
    mkdir -p "$OUTPUT"
    
    # Obtenir la liste des fichiers à traiter
    local files_to_process=()
    while IFS= read -r file; do
        files_to_process+=("$file")
    done < <(get_files_to_process)
    
    local total_files=${#files_to_process[@]}
    local current=0
    local errors=0
    
    if [[ $total_files -eq 0 ]]; then
        echo "❌ Aucun fichier à traiter"
        return 1
    fi
    
    echo "→ $total_files fichier(s) Mermaid à traiter"
    echo ""
    
    # Démarrer le chronomètre
    local start_time=$(date +%s)
    
    for file in "${files_to_process[@]}"; do
        ((current++))
        
        rel_path="${file#$SOURCE_DIR/}"
        subdir="$(dirname "$rel_path")"
        mkdir -p "$OUTPUT/$subdir"
        
        filename="$(basename -- "$file")"
        name="${filename%.*}"
        tmp="/tmp/${name}_${lang}.mmd"
        svg="$OUTPUT/$subdir/$name.svg"
        
        # Génération du fichier MMD traduit
        apply_translations "$file" > "$tmp"
        
        # Conversion
        convert_to_svg "$tmp" "$svg"
        status=$?
        
        # Supprimer le fichier temporaire
        rm -f "$tmp"
        
        if [[ $status -ne 0 ]] || [[ ! -s "$svg" ]]; then
            printf "\033[J"
            echo "❌ Erreur : $file"
            ((errors++))
        fi
        
        show_progress "$current" "$total_files" "$start_time"
    done
    
    # Calcul du temps total
    local end_time=$(date +%s)
    local total_time=$((end_time - start_time))
    
    echo ""
    echo ""
    
    if [ $errors -gt 0 ]; then
        echo "✓ Terminé avec $errors erreur(s) sur $total_files fichiers en $(format_time $total_time)."
    else
        echo "✓ Tous les fichiers traités avec succès en $(format_time $total_time)."
    fi
}

##############################################
#              PROGRAMME PRINCIPAL
##############################################

# Parser les arguments
parse_arguments "$@"

echo ""
if [[ "$PROCESS_ALL" == true ]]; then
    echo "Mode : Traitement de tous les fichiers"
else
    echo "Mode : Traitement de fichiers spécifiques"
    echo "Fichiers cibles : ${TARGET_FILES[*]}"
fi

echo ""
echo "Recherche des langues dans : $TRANSLATIONS_DIR"

LANG_LIST=($(ls "$TRANSLATIONS_DIR"/*.json 2>/dev/null | sed 's/.*\///; s/.json//'))

if [[ ${#LANG_LIST[@]} -eq 0 ]]; then
    echo "❌ Aucun fichier de langue trouvé."
    exit 1
fi

echo "Langues détectées : ${LANG_LIST[*]}"
echo ""

# Temps de début global
GLOBAL_START=$(date +%s)

for lang in "${LANG_LIST[@]}"; do
    process_language "$lang"
done

# Temps total de toutes les langues
GLOBAL_END=$(date +%s)
GLOBAL_TIME=$((GLOBAL_END - GLOBAL_START))

echo ""
echo "🎉 Génération multi-langue terminée en $(format_time $GLOBAL_TIME)."