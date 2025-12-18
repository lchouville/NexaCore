#!/bin/bash

##############################################
#               AIDE
##############################################
show_help() {
    cat << EOF
Usage: $0 [OPTIONS] [ARGUMENTS]

Options:
  -m, --mmdToSVG [OPTIONS] [FICHIERS...]
                        Convertir les fichiers Mermaid en SVG
                        
Options pour -m:
  -a, --all            Générer tous les fichiers (défaut)
  FICHIERS...          Liste de fichiers spécifiques à traiter
  
Exemples:
  $0 -m                              # Tout générer
  $0 -m -a                           # Tout générer (explicite)
  $0 -m diagram1.mmd                 # Un fichier spécifique
  $0 -m diagram1.mmd diagram2.mmd    # Plusieurs fichiers
  $0 -m subfolder/diagram.mmd        # Fichier dans sous-dossier
  
Autres options:
  -s, --status          Afficher le statut
  -h, --help            Afficher cette aide
  -b, --build           Construire l'application .NET
  -ra, --runApi         Lancer l'application .NET API
  -ru, --runUi          Lancer l'application .NET UI
  -db                   Recréer la base de données

EOF
}

##############################################
#         TRAITEMENT DES OPTIONS
##############################################
case "$1" in
    -db)
        # Drop and recreate the database
        dotnet ef database drop --project ./Ticketing.Api --force
        dotnet ef database update --project ./Ticketing.Api
        ;;
    -b|--build)
        # Build the .NET application
        dotnet build ./Ticketing.Api
        ;;
    -ra|--runApi)
        # Launch the .NET application
        dotnet run --project ./Ticketing.Api
        ;;
    -ru|--runUi)
        # Launch the .NET UI application
        dotnet run --project ./Ticketing.Ui
        ;;
    -m|--mmdToSVG)
        shift  # Enlever le premier argument (-m)
        
        # Passer tous les arguments restants au script
        if [[ $# -eq 0 ]]; then
            # Aucun argument supplémentaire = tout générer
            ./Script/generate_mmd-svg.sh -a
        else
            # Passer tous les arguments au script
            ./Script/generate_mmd-svg.sh "$@"
        fi
        ;;
        
    -s|--status)
        # Votre code pour status
        echo "Status..."
        ;;
        
    -h|--help)
        show_help
        ;;
        
    *)
        echo "❌ Option inconnue : $1"
        echo ""
        show_help
        exit 1
        ;;
esac