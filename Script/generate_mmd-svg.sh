#!/bin/bash
##############################################
#                   CONFIG
##############################################
SOURCE_DIR="./Documents/Edition-files"
DEST_DIR="./Documents/Graph"
TRANSLATIONS_DIR="./Translations/Mermaid"
MMDC="./node_modules/.bin/mmdc"

# Déclaration globale du tableau associatif
declare -A TRANSLATIONS

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
    $MMDC -i "$input" -o "$output" >/dev/null 2>&1
    return $?
}

# Affichage barre progression
show_progress() {
    local current="$1"
    local total="$2"
    local percentage=$((current * 100 / total))
    local bar_length=50
    local filled=$((percentage * bar_length / 100))
    local empty=$((bar_length - filled))
    
    printf "\033[J["
    printf "%${filled}s" | tr ' ' '#'
    printf "%${empty}s" | tr ' ' '-'
    printf "] %3d%% (%d/%d)\r" "$percentage" "$current" "$total"
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
    
    local total_files=$(find "$SOURCE_DIR" -type f -name "*.mmd" | wc -l)
    local current=0
    local errors=0
    
    echo "→ $total_files fichiers Mermaid trouvés"
    echo ""
    
    while IFS= read -r file; do
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
        
        # Ne pas supprimer le tmp pour déboguer
        # rm -f "$tmp"
        
        if [[ $status -ne 0 ]] || [[ ! -s "$svg" ]]; then
            printf "\033[J"
            echo "❌ Erreur : $file"
            ((errors++))
        fi
        
        show_progress "$current" "$total_files"
        
    done < <(find "$SOURCE_DIR" -type f -name "*.mmd")
    
    echo ""
    echo ""
    
    if [ $errors -gt 0 ]; then
        echo "✓ Terminé avec $errors erreur(s) sur $total_files fichiers."
    else
        echo "✓ Tous les fichiers traités avec succès."
    fi
}

##############################################
#              PROGRAMME PRINCIPAL
##############################################
echo ""
echo "Recherche des langues dans : $TRANSLATIONS_DIR"

LANG_LIST=($(ls "$TRANSLATIONS_DIR"/*.json 2>/dev/null | sed 's/.*\///; s/.json//'))

if [[ ${#LANG_LIST[@]} -eq 0 ]]; then
    echo "❌ Aucun fichier de langue trouvé."
    exit 1
fi

echo "Langues détectées : ${LANG_LIST[*]}"
echo ""

for lang in "${LANG_LIST[@]}"; do
    process_language "$lang"
done

echo ""
echo "🎉 Génération multi-langue terminée."