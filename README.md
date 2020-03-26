<p align="center">
  <img src="https://raw.githubusercontent.com/austineast/echo/gh-pages/logo.png">
</p>

# echo
A 2D Physics library written in Haxe.

[![Build Status](https://travis-ci.org/AustinEast/echo.svg?branch=master)](https://travis-ci.org/AustinEast/echo)

It focuses on maintaining a simple API that is easy to integrate into any engine/framework (Heaps, OpenFL, Kha, etc). All Echo needs is an update loop and its ready to go!

Try the [Samples 🎮](https://austineast.dev/echo)!

Check out the [API 📖](https://austineast.dev/echo/api/)!

## Features
* Semi-implicit euler integration physics
* SAT-powered collision detection
* Quadtree for broadphase collision querying
* Collision listeners to provide collision callbacks
* Traversable Physics State History with built-in Undo/Redo functionality
* Extendable debug drawing

## Getting Started

Echo requires [Haxe 4](https://haxe.org/download/) to run.

Install the library from haxelib:
```
haxelib install echo
```
Alternatively the dev version of the library can be installed from github:
```
haxelib git echo https://github.com/AustinEast/echo.git
```

Then include the library in your project's `.hxml`:
```hxml
-lib echo
```
For OpenFL users, add this into your `Project.xml`:

```xml
<haxelib name="echo" />
```

For Kha users (who don't use haxelib), clone echo and [hxmath](https://github.com/tbrosman/hxmath) to `Libraries` folder in your project root, and then add the following to your `khafile.js`:

```js
project.addLibrary('echo');
project.addLibrary('hxmath');
```

## Usage

### Concepts

#### Echo

The `Echo` Class holds helpful utility methods to help streamline the creation and management of Physics Simulations.

#### World

A `World` is an Object representing the state of a Physics simulation and it configurations. 

#### Bodies

A `Body` is an Object representing a Physical Body in a `World`. A `Body` has a position, velocity, mass, optional collider shapes, and many other properties that are used in a `World` simulation.

#### Shapes

A Body's collider is represented by different Shapes. Available Shapes:
* Rectangle
* Circle
* Polygon (Convex Only)

#### Lines

Use Lines to perform Linecasts against other Lines, Bodies, and Shapes.

#### Listeners

Listeners keep track of collisions between Bodies - enacting callbacks and physics responses depending on their configurations.

### Integration

Echo has a couple of ways to help integrate itself into codebases through the `Body` class. 

First, the `Body` class has two public fields named `on_move` and `on_rotate`. If these are set on a body, they'll be called any time the body moves or rotates:
```haxe
var body = new echo.Body();
body.on_move = (x,y) -> entity.position.set(x,y);
body.on_rotate = (rotation) -> entity.rotation = rotation;
```

Second, a build macro is available to add custom fields to the `Body` class, such as an `Entity` class:

in build.hxml:
```hxml
--macro echo.Macros.add_data("entity", "some.package.Entity")
```

in Main.hx
```haxe
var body = new echo.Body();
body.entity = new some.package.Entity();
```

### Example
```haxe
import echo.Echo;

class Main {
  static function main() {
    // Create a World to hold all the Physics Bodies
    // Worlds, Bodies, and Listeners are all created with optional configuration objects.
    // This makes it easy to construct object configurations, reuse them, and even easily load them from JSON!
    var world = Echo.start({
      width: 64, // Affects the bounds that collision checks.
      height: 64, // Affects the bounds for collision checks.
      gravity_y: 20, // Force of Gravity on the Y axis. Also available on for the X axis.
      iterations: 2 // Sets the number of iterations each time the World steps.
    });

    // Create a Body with a Circle Collider and add it to the World
    var a = world.make({
      elasticity: 0.2,
      shape: {
        type: CIRCLE,
        radius: 16,
      }
    });

    // Create a Body with a Rectangle collider and add it to the World
    // This Body will have a Mass of zero, rendering it as unmovable
    // This is useful for things like platforms or walls.
    var b = world.make({
      mass: 0, // Setting this to zero makes the body unmovable by forces and collisions
      y: 48, // Set the object's Y position below the Circle, so that gravity makes them collide
      elasticity: 0.2,
      shape: {
        type: RECT,
        width: 10,
        height: 10
      }
    });

    // Create a listener and attach it to the World.
    // This listener will react to collisions between Body "a" and Body "b", based on the configuration options passed in
    world.listen(a, b, {
      separate: true, // Setting this to true will cause the Bodies to separate on Collision. This defaults to true
      enter: (a, b, c) -> trace("Collision Entered"), // This callback is called on the first frame that a collision starts
      stay: (a, b, c) -> trace("Collision Stayed"), // This callback is called on frames when the two Bodies are continuing to collide
      exit: (a, b) -> trace("Collision Exited"), // This callback is called when a collision between the two Bodies ends
    });

    // Set up a Timer to act as an update loop
    new haxe.Timer(16).run = () -> {
      // Step the World's Physics Simulation forward
      world.step(16 / 1000);
      // Log the World State in the Console
      echo.util.Debug.log(world);
    }
  }
}
```
