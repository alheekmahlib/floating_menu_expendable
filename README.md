## Floating Menu Expendable

A draggable floating handle that opens a customizable panel (side or vertical).

Designed for:

- Quick actions / shortcuts
- Floating toolbars
- Chat / support / menu buttons

### Features

- Draggable and snaps to the nearest screen edge
- Two open modes:
	- `FloatingMenuPanelOpenMode.side`: panel opens horizontally next to the handle
	- `FloatingMenuPanelOpenMode.vertical`: panel opens below the handle (or above if near bottom)
- Background barrier with blur + color, dismissible on tap
- UI customization via `FloatingMenuPanelStyle`
- `FloatingMenuPanelController` for open/close/toggle and side tracking

### Preview

![Preview](doc/preview.gif)

### Installation

Add the package to your `pubspec.yaml`.

### Import

```dart
import 'package:floating_menu_expendable/floating_menu_expendable.dart';
```

### Quick usage

```dart
final controller = FloatingMenuPanelController();

Stack(
	children: [
		FloatingMenuPanel(
			controller: controller,
			panelWidth: 320,
			panelHeight: 240,
			handleChild: const Icon(Icons.menu),
			panelChild: const ColoredBox(color: Colors.white),
		),
	],
)
```

### Customize the UI (Style)

Use `FloatingMenuPanelStyle` to customize blur, barrier color, panel radius, and handle ink effects.

```dart
FloatingMenuPanel(
	controller: controller,
	panelWidth: 320,
	panelHeight: 240,
	handleChild: const Icon(Icons.menu),
	panelChild: const ColoredBox(color: Colors.white),
	style: const FloatingMenuPanelStyle(
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
