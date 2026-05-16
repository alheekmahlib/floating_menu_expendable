## 1.1.1

- Fix floating menu opening on the opposite side after restoring saved position.
- Auto-detect dock side from saved position on first build, even when `startDocked` is `false`.

## 1.1.0

- Add `startDocked` parameter (default `true`) to respect `initialPosition` fully when set to `false`.
- Add `onPositionChanged` callback to notify when the handle position changes (useful for persisting position via SharedPreferences).
- Fix `initialPosition` being ignored on first build when `_isDocked` was always `true`.
- Fix `didUpdateWidget` to handle `initialPosition` changes during widget rebuilds.
- Update example app to demonstrate position persistence with `SharedPreferences` or `GetStorage`.

## 1.0.0

- Add `FloatingMenuAnchoredOverlay` to expand the panel from the handle.

## 0.1.1+1

- Fix README.

## 0.1.1

- Add `expandPanelFromHandle` to expand the panel from the handle.
- Add `handleOpenChild` to customize handle content while open.
- Update README previews.

## 0.1.0

- Initial public release.
- `FloatingMenuPanel` draggable panel with edge docking.
- Open modes: `side` and `vertical`.
- UI customization via `FloatingMenuPanelStyle`.
- `FloatingMenuPanelController` for open/close/toggle and side tracking.

## 0.0.1

- Project scaffold.
