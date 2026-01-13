## Floating Menu Expendable

A draggable floating handle that opens a customizable panel (side or vertical).

Designed for:

- Quick actions / shortcuts
- Floating toolbars
- Chat / support / menu buttons

### Features

- Draggable and snaps to the nearest screen edge
- Two open modes:
	- `FloatingMenuExpendableOpenMode.side`: panel opens horizontally next to the handle
	- `FloatingMenuExpendableOpenMode.vertical`: panel opens below the handle (or above if near bottom)
- Background barrier with blur + color, dismissible on tap
- UI customization via `FloatingMenuExpendableStyle`
- `FloatingMenuExpendableController` for open/close/toggle and side tracking

New:

- Expand from the handle (unified handle + panel) using `expandPanelFromHandle`
- Switch handle content while open using `handleOpenChild` (defaults to a close icon)

### Preview

Note: pub.dev does not reliably render relative image paths.
Use GitHub raw URLs for previews.

Default behavior:

![Preview](https://raw.githubusercontent.com/hawazenmahmood/floating_menu_expendable/main/doc/preview.gif)

Expand-from-handle behavior:

![Preview (Expand From Handle)](https://raw.githubusercontent.com/hawazenmahmood/floating_menu_expendable/main/doc/preview2.gif)

### Installation

Add the package to your `pubspec.yaml`.

### Import

```dart
import 'package:floating_menu_expendable/floating_menu_expendable.dart';
```

### Quick usage

```dart
final controller = FloatingMenuExpendableController();

Stack(
	children: [
		FloatingMenuExpendable(
			controller: controller,
			panelWidth: 320,
			panelHeight: 240,
			handleChild: const Icon(Icons.menu),
			panelChild: const ColoredBox(color: Colors.white),
		),
	],
)
```

### Expand from handle (new)

If you want the panel to expand from the same handle (so it looks like one widget),
enable `expandPanelFromHandle`.

```dart
FloatingMenuExpendable(
	controller: controller,
	panelWidth: 320,
	panelHeight: 240,
	expandPanelFromHandle: true,
	// Optional: what to show inside the handle when open.
	handleOpenChild: const Icon(Icons.close_rounded),
	handleChild: const Icon(Icons.menu),
	panelChild: const ColoredBox(color: Colors.white),
)
```

### Customize the UI (Style)

Use `FloatingMenuExpendableStyle` to customize blur, barrier color, panel radius, and handle ink effects.

```dart
FloatingMenuExpendable(
	controller: controller,
	panelWidth: 320,
	panelHeight: 240,
	handleChild: const Icon(Icons.menu),
	panelChild: const ColoredBox(color: Colors.white),
	style: const FloatingMenuExpendableStyle(
		// Background barrier
		showBarrierWhenOpen: true,
		barrierDismissible: true,
		barrierColor: Color(0x66000000),
		barrierBlurSigmaX: 10,
		barrierBlurSigmaY: 10,

		// Panel
		panelBorderRadius: BorderRadius.all(Radius.circular(18)),
	),
)
```

### Controller

```dart
controller.open();
controller.close();
controller.toggle();
```

You can also listen to where the handle is docked:

- `controller.physicalSide` (left / right)
- `controller.verticalSide` (top / bottom) when using vertical mode

### Example app

See the runnable Flutter demo in the `example/` folder.

### Notes

- The widget is intended to be used inside a `Stack`.
- Provide your own `panelChild` and `handleChild` to match your app UI.
