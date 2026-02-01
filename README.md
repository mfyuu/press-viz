# PressViz

A native macOS app for visualizing keyboard presses.

## Installation

1. Download the latest DMG from [Releases](https://github.com/mfyuu/press-viz/releases)
2. Open the DMG file
3. Drag PressViz to your Applications folder
4. Launch PressViz from Applications

### Requirements

- macOS 26.2+

### Permissions

PressViz requires **Accessibility** permission to monitor keyboard input.

1. Open System Settings > Privacy & Security > Accessibility
2. Enable PressViz

## Development

### Prerequisites

- Xcode
- [mise](https://mise.jdx.dev/) (optional, for task runner)
- [create-dmg](https://github.com/create-dmg/create-dmg) (for DMG creation)

### Build

```bash
# Debug build
mise run build

# Release build
mise run release

# Clean
mise run clean
```

### Version Management

```bash
# Show current version
mise run version

# Set version
mise run version:set 0.2.0
```

### Create DMG

```bash
mise run dmg
```

## License

MIT
