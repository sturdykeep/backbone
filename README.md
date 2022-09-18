# backbone
## What is backbone?
Lightweight, ECS-like package for Flame and Flutter. Backbone doesn't seek to replace the component system in Flame, it extends it by ECS patterns and a unified multi-platform input system.

## Is it ready for production?
*No*, we are still working on this package, currently we are using it in a not yet announced project.

## What does backbone do for me?
It helps you to organize and structure features of your game and still use the many great features Flame ships. With backbone you can also increase the reusability of code. Backbone comes with a some build in features to support you. 

- Multiplatform input system for:
    - Taps
    - Drags
    - Long press 
    - Keyboard events
    - All pointer types are supported (touch, mouse, stylus)
- Message system to decouple game elements from each other
- Fast queries for your nodes (game elements)

## Can I use backbone beside the existing component system?
Yes! Backbone doesn't try to replace the component system at all. You can see it as an addition/upgrade to it.

## Is it only something for new projects?
No! You can add backbone to any Flame game and use it alongside the existing components.

## Do you have an example?
Yes, there is simple example application that showcases all basic uses-cases of backbone. The code for the app can be found in [example](https://github.com/sturdykeep/backbone/tree/main/example/lib), a [live demo can be found here](https://sturdykeep.github.io/backbone/example_app/).

## Check out the docs
Check out our [documentation here](https://github.com/sturdykeep/backbone/blob/main/docs/docs.md) in the repository or directly in the code.
