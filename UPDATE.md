# Fix 1
You implemented the terrain tiles incorrectly.

Read `TASK.md` again, especially the **Tiles** section. The terrain MUST use `spritesheet-tiles-double.png`. Do not use the individual terrain tile PNG files as substitutes.

Your task is to inspect the existing project and correct this implementation.

Requirements:

1. Find `spritesheet-tiles-double.png` in the project and inspect the actual spritesheet layout.
2. Determine the tile/frame dimensions, rows, columns, biome groupings, edge pieces, corner pieces, center/fill pieces, platform pieces, and any other terrain variants contained in the spritesheet. Do not guess based on filenames if the spritesheet itself can be inspected.
3. Create the appropriate engine-native spritesheet/atlas/tileset configuration so terrain tiles are rendered by selecting regions/frames from `spritesheet-tiles-double.png`.
4. Modify the procedural terrain generation code so it uses those spritesheet regions instead of loading individual terrain tile image files.
5. The pieces in the spritesheet are designed to fit together. Use the appropriate tile piece according to its surrounding terrain / platform geometry so that:

   * left and right platform edges use the correct edge pieces,
   * tops, bottoms, sides, corners, and interior/fill pieces use their corresponding sprites,
   * connected terrain visually joins correctly,
   * caves, mountains, floating platforms, ledges, gaps, and other generated terrain do not look like repeated arbitrary blocks.
6. Preserve the biome system described in `TASK.md`:

   * Grass
   * Tundra
   * Snow
   * Desert
   * Astro
   * Fort

   Each biome must use the appropriate terrain section/pieces from `spritesheet-tiles-double.png`.
7. Do NOT solve this by cropping the spritesheet into separate PNG files on disk and then continuing to load them individually. Runtime/editor atlas regions, source rectangles, tile IDs, TileSet resources, sprite regions, or the equivalent feature of the current game engine should reference the original spritesheet.
8. Remove or replace the old terrain code/resources that use the individual tile image files so there is only one authoritative terrain rendering system. Do not leave the old implementation active as a fallback.
9. Do not change unrelated gameplay systems unless required to integrate the corrected tile system.
10. Update tests to verify that:

    * terrain rendering references `spritesheet-tiles-double.png`;
    * procedural generation no longer depends on individual terrain tile PNGs;
    * all six biomes map to valid spritesheet tiles;
    * generated neighboring tiles select compatible edge/corner/interior pieces where applicable.
11. Update the README to document that terrain uses `spritesheet-tiles-double.png` and explain briefly how spritesheet regions/tile IDs are mapped to the six biomes.

Before making changes, inspect the current implementation and identify exactly where individual tile files are being loaded or selected. Then replace that path through the rendering pipeline rather than adding a second system alongside it.

After implementing the fix, run the relevant tests/build and fix any errors caused by the change.

At the end, report:

* which files you changed,
* where the spritesheet is configured,
* the tile/frame dimensions you determined,
* how spritesheet regions/IDs map to each biome,
* how connected-tile selection works,
* which old individual-tile references were removed,
* and the test/build results.

Important: Do not claim this is fixed merely because `spritesheet-tiles-double.png` is loaded somewhere in the project. The actual procedurally generated terrain visible during gameplay must be rendered from regions of that spritesheet.
