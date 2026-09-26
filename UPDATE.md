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

# Fix 2
Make the following corrections to the existing game. Inspect the current implementation first and modify the existing systems directly. Do not add duplicate systems or temporary workarounds.

## 1. Increase the player character size

The player character is currently visually much smaller than the enemies.

Change the player's rendered size so that the player is approximately the same visual height/scale as the normal enemies.

Requirements:

* Use the existing enemy size as the visual reference.
* Do not shrink the enemies.
* Increase the player's rendered character size instead.
* Preserve the character sprite's aspect ratio.
* Make sure all playable characters from the `Characters` folder use a consistent appropriate visual scale.
* Check animations after resizing so frames do not change size, jitter, or shift unexpectedly.
* Make sure the player's feet still visually align with the terrain.

Do not blindly scale the physics collider together with the sprite.

After increasing the visual size, inspect the player's collision shape/hitbox separately and adjust it only if necessary so that:

* feet align correctly with terrain,
* jumping and landing still work correctly,
* rolling still works correctly,
* wall contact and wall jumping still work correctly,
* enemy/projectile collisions still make sense,
* the hitbox reasonably matches the visible player body.

The goal is for the PLAYER to visually be approximately the same size as the normal enemies while preserving correct gameplay behavior.

## 2. Make walking enemies face the direction they are moving

Enemies that walk back and forth must visually face their current movement direction.

Behavior:

* moving right -> sprite faces right,
* moving left -> sprite faces left.

Update the facing direction whenever the enemy changes movement direction.

Use the game engine's normal horizontal sprite-flipping mechanism, such as horizontal sprite flip / `flip_h`, rather than creating duplicate textures.

Prefer flipping only the enemy's visual sprite/animation node.

Do not flip the entire enemy hierarchy if that would incorrectly flip:

* health bars,
* UI elements,
* labels,
* collision shapes,
* projectile spawn points,
* attack logic,
* or other child nodes that should not be mirrored.

Inspect the existing enemy scene/node structure and implement the flip at the correct visual level.

Also verify directional attack behavior:

* If an enemy's projectile or attack direction depends on its facing direction, make sure it remains consistent with the visual facing.
* Projectile spawn positions should still be correct when the enemy turns around.
* Health bars and other UI should always remain readable and unflipped.

Standing enemies do not need to change facing unless the existing gameplay logic specifically requires it.

## 3. Remove the large red flash that occurs when an enemy fires a bullet

There is currently a large red visual flash/blink that appears in the middle of the screen at the exact moment an enemy fires a bullet/projectile.

This effect is caused by the ENEMY FIRING/SHOOTING system.

It is NOT related to:

* the player taking damage,
* player hit feedback,
* player status effects,
* player health,
* or player damage animations.

Do not investigate or modify the player damage system as part of this fix.

Trace the exact code path that runs when an enemy fires a bullet/projectile and identify what creates the large red flash.

It may be caused by something such as:

* a firing or muzzle-flash effect,
* a particle system,
* a temporary Sprite/Sprite2D,
* a ColorRect,
* a CanvasLayer overlay,
* an animation triggered during shooting,
* a projectile-spawn visual,
* a debug effect,
* a shader effect,
* or an effect instantiated at incorrect world/screen coordinates.

Remove the source of that red flash completely.

Do not merely:

* reduce its opacity,
* move it offscreen,
* hide it behind something,
* make it smaller,
* or disable it conditionally.

Remove or correct the actual firing-related effect that is causing the visible red blink.

Enemy bullets/projectiles must continue to:

* spawn normally,
* move normally,
* damage the player normally,
* use their intended graphics,
* and preserve their existing gameplay behavior.

The only behavior that should disappear is:

ENEMY FIRES BULLET -> LARGE RED FLASH APPEARS IN THE MIDDLE OF THE SCREEN

After the fix, enemy shooting should happen without any large red screen-center flash.

## 4. Do not break unrelated visual effects

Do not remove legitimate effects elsewhere in the game.

In particular, preserve:

* intended player damage feedback,
* biome-specific enemy effects,
* enemy projectile graphics,
* enemy hit effects,
* collectible effects,
* terrain effects,
* and other unrelated particle/animation systems.

Only remove the red flash that is specifically triggered by enemy projectile firing.

## 5. Verify the changes in actual gameplay

After making the changes, run the game if the environment allows it and verify the behavior visually.

Verify all of the following:

1. The player is approximately the same visual size as normal enemies.
2. The player is not still noticeably tiny compared with enemies.
3. Player sprite proportions remain correct.
4. Player feet line up correctly with terrain.
5. Jumping still works.
6. Landing still works.
7. Rolling still works.
8. Player collision still behaves correctly.
9. Walking enemies face right while walking right.
10. Walking enemies face left while walking left.
11. Enemy sprites change facing immediately when their movement direction changes.
12. Enemy health bars and UI do not flip.
13. Enemy collision shapes are not incorrectly mirrored.
14. Enemy projectile spawn positions remain correct after enemies turn.
15. Enemy projectiles continue to spawn and travel correctly.
16. Repeated enemy shooting no longer produces the large red flash in the middle of the screen.
17. Removing the firing flash does not remove the projectile itself.
18. Player damage feedback and unrelated visual effects remain intact.

Do not consider this task complete based only on reading the code. Verify the resulting behavior in the running game if possible.

## 6. Keep the changes focused

Do not rewrite unrelated systems.

Do not make unnecessary changes to:

* procedural terrain generation,
* biome generation,
* weapons,
* abilities,
* collectibles,
* menus,
* progression,
* or other systems unrelated to these three fixes.

Use the existing architecture whenever possible.

## Final report

At the end, report:

* all files changed,
* how the player visual scale was changed,
* the old and new relevant scale values if applicable,
* whether the player's collider/hitbox needed adjustment,
* any collider changes made,
* how enemy facing direction is implemented,
* which node/sprite is flipped,
* how projectile spawn behavior remains correct after enemies turn,
* exactly what code/node/effect was causing the large red firing flash,
* exactly what was changed or removed to eliminate that flash,
* and the results of any tests/build/run verification.
