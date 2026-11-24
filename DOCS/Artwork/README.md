# Project icon

- `framenet-graph-icon.svg`: original 256 x 256 source supplied by the project owner.
- `framenet-graph-icon.png`: transparent PNG rendered from the SVG with Inkscape.
- `../../Media/Icon.tga`: runtime icon shared by the minimap launcher and addon list.

The runtime asset is an uncompressed 256 x 256, 32-bit true-color TGA with an 8-bit
alpha channel and bottom-left pixel origin. Pixels are written as BGRA, preserving
the rendered PNG's colors and transparency. The SVG and PNG are documentation/source
assets and are not copied into the game by `scripts/dev.ps1`.
