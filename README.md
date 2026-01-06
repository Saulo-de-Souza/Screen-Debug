# ScreenDebug Plugin for Godot 4.5

![ScreenDebug Icon](screenshots/icon_400.png)

## Overview

**ScreenDebug** is a professional runtime debug overlay for Godot 4.5 that allows developers to inspect node properties, call methods, and visualize real-time values directly on the screen. It is designed to help both debugging and learning the Godot engine by showing the effects of property changes instantly.

The plugin supports complex expressions including method calls, array and dictionary access, vector calculations, and chained expressions. It's particularly useful for character debugging, physics testing, and understanding how nodes interact in your scene.

## Features

- Real-time display of node properties and method results.
- Supports arrays, dictionaries, vectors, and transform types.
- Safe method filtering (prevents unsafe operations like `queue_free`).
- Customizable appearance: font size, colors, background size, padding, and opacity.
- Quick expressions for commonly used debug values.
- Ideal for learning the engine: type expressions in the Inspector and see the result visually.

## Installation

1. Copy the `addons/screen_debug/` folder into your Godot project.
2. Enable the plugin in `Project Settings -> Plugins -> ScreenDebug`.
3. Add a `ScreenDebug` node to your scene.

## Setup

1. Assign a **target node** to inspect in the `debug_target` export.
2. Toggle `debug_active` to show or hide the overlay.
3. Use `quick_expressions` for short debug values and `expressions` for longer or more complex expressions.

## Inspector Configuration Examples

Assume we have a **CharacterBody3D** node called `Player` with properties:

- `position` (Vector3)
- `velocity` (Vector3)
- `health` (float)
- `inventory` (Array of Items)
- `equipment` (Dictionary with keys like `Weapon`, `Armor`)

### Quick Expressions

```gdscript
quick_expressions = {
    "Health": "health",
    "Position": "position",
    "Velocity": "velocity",
    "Speed": "velocity.length()",
    "Forward Distance": "position.distance_to(Vector3:10,0,5)",
    "Direction to Target": "position.direction_to(get_node('Target').position)"
}
```

### Expressions (Longer Examples)

```gdscript
expressions = [
    ScreenDebugExpression.new("First Child Name", "get_children()[0].name"),
    ScreenDebugExpression.new("Weapon Damage", "get_node('Weapon').damage"),
    ScreenDebugExpression.new("Dot Product Velocity", "velocity.dot(Vector3:1,0,0)"),
    ScreenDebugExpression.new("Inventory First Item", "inventory[0].name"),
    ScreenDebugExpression.new("Armor Defense", "equipment.get('Armor').defense"),
    ScreenDebugExpression.new("Distance To Target", "get_node('Target').position.distance_to(position)"),
    ScreenDebugExpression.new("Direction To Target", "position.direction_to(get_node('Target').position)"),
]
```

### Dictionary Access

```gdscript
# Access by key
equipment.get('Weapon')

# Access by array-like index
equipment['Weapon']
```

### Array Access

```gdscript
# First child of the node
get_children()[0]

# Access the 3rd inventory item
inventory[2]
```

### Vector Methods

```gdscript
velocity.length()        # Returns speed
velocity.normalized()    # Returns unit vector
velocity.dot(Vector3:1,0,0)
velocity.cross(Vector3:0,1,0)
velocity.distance_to(Vector3:5,0,0)
velocity.angle_to(Vector3:0,0,1)
position.direction_to(get_node('Target').position)
```

### Transform3D / Basis Access

```gdscript
transform.origin
transform.basis
transform.basis.x
transform.basis.y
transform.basis.z
```

### Chained Expressions

```gdscript
# Access a child weapon's damage
get_children()[0].get_node('Weapon').damage

# Access first inventory item's name
get_children()[0].inventory[0].name
```

## Appearance Customization

```gdscript
# Font sizes
debug_font_size = 24

# Line spacing
debug_line_spacing = 5

# Outline thickness
debug_font_outline = 1

# Colors
debug_default_font_color = Color.white
debug_key_font_color = Color.orange
debug_value_font_color = Color.yellow

# Background panel
debug_background_color = Color.black
debug_background_opacity = 0.3
debug_background_size = Vector2(600, 400)
debug_background_position = Vector2(20, 20)
debug_background_padding = 20
```

## Safety

Some methods are blocked to prevent accidental modification or deletion of your nodes at runtime:

- `queue_free`
- `add_child`
- `set_process`
- `add_to_group`
- `move_and_slide`

## Advantages for Learning Godot

ScreenDebug is not only a debugging tool but also an **educational resource**:

- Type expressions in the Inspector and see their results live.
- Learn Godot node hierarchy, properties, and methods interactively.
- Understand vectors, transforms, arrays, and dictionaries by observing changes in real-time.
- Test method calls safely and instantly.

## Recommended Workflow

1. Add a `ScreenDebug` node to your scene.
2. Assign your player or main node to `debug_target`.
3. Fill `quick_expressions` with common checks (health, position, speed).
4. Use `expressions` for more advanced, chained, or vector calculations.
5. Observe results in-game to learn how nodes interact.

---

**ScreenDebug** is the ultimate runtime debug and learning tool for Godot 4.5 developers.
