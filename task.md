Read the description below and create the game with a README file. Create unit tests for each aspect of the game and list them in the README. Note that the words written in constant case are variables that are to be set by the user of the source code. Decide on the default values for the variables yourself. The expressions between brackets are placeholders.

# Overview
The game is a 2D platformer game that spawns tiles procedurally. The player runs from left to right nonstop with a speed SPEED as new flying platforms, mountains or caves generate. Collectibles and enemies spawn along the way. The player should try to evade the obstacles, falling and taking any damage. The camera is always following the player alongside the horizontal axis. The players health is down to zero when it falls down the map. If players health is down to zero or it is stuck for GAME_OVER_NUMBER_OF_SECS secs the player is given a COUNTDOWN_SECS secs countdown to use revival potion. If the player does not use revival potion the game is over. 

# Tiles
Each group of the same tiles is a biome and biome changes at each BIOME_INTERVAL number of horizontal tiles in order from 1 to the last in the first encounter of each run. After the last biome of the first encounter, the next biome appears randomly without order for next encounters. Use the terrain tiles in spritesheet-tiles-double.png for the tiles. 

## Terrain tiles
1) Green grass on brown dirt (Grass)
2) Orange grass on gray dirt (Tundra)
3) Snow: It adds randomness to MAX_JUMP, maximum vertical distance in tiles that player can reach after jump.
4) Desert: Deals damage to the player with flame particles.
5) Purple glass on gray block (Astro): Falls whenever the player steps on. If there is another block that fall on it, it will fall as well.
6) Black brick on gray/white block (Fort): Has spikes that move up and down. When the spikes are visible, they deal damage to the player.

# Player
Player has stats to upgrade. It also has characters, consumables, abilities and weapons to buy which is done with the golds it has. For each run, it has health and horizontal tiles run so far. Player turns red for the moment it takes damage. For the characters use the Characters folder. The player jumps over when jump action is triggered or rolls under when roll action is triggered with user input. Player has MAX_JUMP in tiles and ROLL_DURATION in secs. The player does a melee attack whenever it is in proximity of an enemy. 

## Stats
A stat is either increasing or decreasing between MIN_[Stat name] and MAX_[Stat name] with [Stat name]_UPGRADE variables. Each stat upgrade is worth [Stat name]_UPGRADE_GOLDS golds.
* Maximum health (Increasing): Maximum health of the player. Integer
* Defense (Decreasing): It is a floating point multiplier on damage taken. 
* Melee power (Increasing): Damage dealt to enemies on melee attack hit. Integer
* Enemy fire rate (Increasing): A multiplier on the interval at which enemies fire.

* Invisibility duration (Increasing): Only available after player unlocks invisibility ability.
* Slow-down duration (Increasing): Only available after player unlocks slow down time ability.

## Weapons
Weapons become available when player unlocks shooting ability. Each weapon can be unlocked and equipped. At most NUM_EQUIPPABLE_WEAPONS can be equipped. Assets are under Props/Weapons. Player fires the weapon at regular intervals when enemies appear on screen. Weapons differ in certain ways:

* Damage: Each weapon deals different damage to enemies
* Trajectory: Some weapons such as axes move like projectiles. Some weapons only move in straight line. 
* Aim: Some weapons are fired directed to enemies. Some weapons are fired in randomly directed trajectories. Some weapons are fired in determined trajectories. Some weapons are fired only forward.
* Number of targets: Number of enemies on-screen that the weapon is fired to at the same time. 

Using the criteria above and the assets under Prop/Weapons, create different types of weapons to the game.  

## Abilities
Each ability can be unlocked and equipped. At most NUM_EQUIPABLE_ABILITIES can be equipped. Some of the unlocked abilities can be upgraded. Jump and Reverse gravity cannot be equipped at the same time. Some abilities have cooldown period given by COOLDOWN_PERIOD. Unless stated otherwise, the ability has cooldown. If the ability has cooldown, its cooldown stat will become available after the ability is unlocked. All cooldown stats are decreasing. 

### Movement Related Abilities
* Jump (no cooldown)
    * Level 1: Single jump before landing. Unlocked by default.
    * Level 2: Double jumps before landing
    * Level 3: Triple jumps before landing

* Climb (no cooldown)
    * Level 1: When player is touching a tile from left and triggers jump at the same time, it can jump. Its like additional jump but on walls. This wall jump can be done once before landing.
    * Level 2: Increase the number of wall jumps to 2 before landing.

* Glide/hang (no cooldown): Triggering jump action for a moment will make player glide/hang on air for maximum of MAX_GLIDE_DURATION secs before landing.
* Reverse gravity: Triggering jump action reverses gravity.
* Fly (no cooldown): Infinite jumps.

* Dash: Triggering dash action will make player move horizontally fast determined by DASH_SPEED in tiles and DASH_TILES number of tiles.

### Attack Related Abilities
* Shooting: Player automatically fires assets. Asset is one of the pngs in Props/Weapons 
* Explode: Triggering explode action will deal damage to enemies in proximity and break the tiles in vicinity. Explode radius is controlled by 
EXPLODE_RADIUS in tiles.

### Miscellanous Abilities
* Slow down time: Reduces SPEED and increases enemy fire rate for slow-down duration when slow down time action is triggered.
* Invisibility: Enemies don't see the player for invisibility duration secs when invisibility action is triggered.

## Consumables
### Revival potion
Uses revival_potion.png as icon. When game is over and the player uses the potion, the game continues from where it is left off.
# Enemies
Look at the Enemies folder and map each enemy to a biome so that it spawns only in that biome. Do the mapping so that 
the enemy is consistent with the theme of the biome. For example frost knights for snow and desert nomads for desert. Ensure that each biome has more than one enemies. Some enemies will spawn in the first encounter in that biome whereas some will spawn later on in the run. This is the level of the enemy. Enemies with higher levels will deal more damage and have more health. Show their health on top of their head as health bar.

Some enemies will walk back and forth and some enemies will be only standing. Some enemies can do only melee attack, some can only shoot and some can do both. Shooting enemies start to shoot the player when player enters their vicinity defined by [Enemy name]_VICINITY tiles. Shooting enemies vary with what they shoot. They can shoot beams or particles at the player which is created with game engines particle system. Each enemy have a different interval at which they fire controlled by [Enemy name]_SHOOTING_INTERVAL. Each enemy should have a unique effect consistent with their biome (Grass biome enemies are exception). For example snow biome enemies will freeze the player on hit, desert biome enemies will burn the player on hit and vampyre hit should give blood loss, draining health from the player and so on. To give freeze effect, the player turns ice blue. The player blinks red when health drain is happening. 

# Actions
## Smartphone build
Actions other than below will have their buttons on screen on bottom right corner by default. The location can be set in settings as bottom left corner too.  
* Jump action - tap on the screen
* Roll action - swipe down
## Computer build
Actions other than below will use 1 through NUM_EQUIPABLE_ABILITIES and the mapping will be shown on bottom left corner.
* Jump action - up button
* Roll action - down button
# Collectibles
Spawnable collectibles spawn along the way. Droppable collectibles are dropped when an enemy is killed, with a probability of [Enemy name]_[Collectible name]_PROB which is a floating number between 0 and 1. Different types of coins and gems increase the gold that the player has in different amounts. Make sure that gems are worth more golds.

# UI
Use UI folder for UI elements.

## Screens
Weapons screen should include each weapon with the description of its damage, trajectory, aim and number of targets.

* Main menu screen: Start screen to access other screens
* Level screen: Where the run/game happens
* Character screen: Screen to unlock and choose characters
* Stats screen: Screen to upgrade stats
* Abilities screen: Screen to buy abilities
* Weapons screen: Screen to buy weapons
* Settings screen

## HUD Elements in Level Screen
* Health of player as a health bar
* Number of golds the player has 
* Number of consumables the player has 
* Number of tiles horizontally run so far