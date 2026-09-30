# Vialbound

A medieval-punk cryptid keeper. Your friends live in essence vials on your bracers,
and wearing one means taking its shape — the cryptid you are wearing *is* your tool,
your weapon and your shield.

This repository is the Godot 4.7.2 build. The design it implements was worked out
first in an HTML prototype, which stays the place to try a mechanic before it is
built here.

## Running it

Open the project folder in Godot 4.7.2 and press play. From a terminal:

    godot --path .

Controls: **WASD / arrows** move · **1**, **2** wear the vial in that bracer (press
again to pour yourself back out) · **Q** return to human form · **F3** step down the
render stack — full pass, lights only, raw sprites.

## What is in here so far

This is the first slice: the render pipeline, a walkable test map, the player, and
one cryptid you can wear. It exists to prove the stack end to end, not to be a game.

    art/            generated PNGs, each with a height map and a normal map beside it
    data/           tileset, and one Species resource per cryptid
    scenes/         main, world, player, friend
    scripts/        game state, player, follower, world build, render stack
    shaders/        the two that define the look
    tools/gen_art.py  draws every sprite and tile; re-run to regenerate art/

## How the look is made

The world draws into a **320×180 viewport** that is scaled up by a whole number, so
every pixel on screen is a whole virtual pixel. Nothing in the game is drawn at
display resolution. Two shaders do the rest:

**`shaders/cel_light.gdshader`** runs on sprites and tiles. Godot's own 2D lights
already sample each sprite's normal map — that is why a lantern wraps around a crop
row instead of just tinting it. The shader's job is to refuse the smooth falloff: it
snaps light to four steps, which is what keeps a lit scene reading as pixel art.

**`shaders/post_palette.gdshader`** runs once over the small viewport: a 4×4 ordered
dither at virtual-pixel scale, then a hard snap to `art/palette.png`. Every frame the
game shows uses only colours from that ramp, and gradients become texture instead of
banding.

Art is generated, not hand-drawn: `tools/gen_art.py` writes the colour layer and a
height layer in the same pass, and the height becomes the normal map the lights read.
Editing a sprite means editing the shapes that draw it and re-running the script, so
the art and its normals can never drift apart.

## Regenerating art

    python3 tools/gen_art.py        # needs Pillow and numpy

Deterministic — a regenerated sheet diffs cleanly against the committed one.

## Capturing frames

Useful for reviewing the look without a screen:

    godot --path . -- --shot           # writes user://shot.png at 320×180
    godot --path . -- --shot-stages    # one frame per render stage

## Next

Port the prototype's systems one at a time, keeping a running build at every step:
callings and aiming, build mode and claims, farming and the day/night cycle,
terrariums, benches and rapport, mount and swim. The tileset is currently a small
generated atlas; the real terrain set with transitions comes with the world port.
