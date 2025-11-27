# options and arguments at execution time:
# mmdToSVG | -m : convert all mermaid files to SVG
#!/bin/bash

case "$1" in
    -m|--mmdToSVG)
        ./Script/generate_mmd-svg.sh
        ;;
    *)
        echo "Usage: $0 {-s|--status|-m|--mmdToSVG}"
        ;;
esac
