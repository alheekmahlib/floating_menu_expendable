import 'package:floating_menu_expendable/floating_menu_expendable.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3B82F6)),
      ),
      home: const ExampleHome(),
    );
  }
}

class ExampleHome extends StatefulWidget {
  const ExampleHome({super.key});

  @override
  State<ExampleHome> createState() => _ExampleHomeState();
}

class _ExampleHomeState extends State<ExampleHome> {
  final FloatingMenuExpendableController controller =
      FloatingMenuExpendableController();

  static const int _gridItemCount = 20;
  late final List<FloatingMenuAnchoredOverlayController> _gridControllers =
      List.generate(
        _gridItemCount,
        (_) => FloatingMenuAnchoredOverlayController(),
      );

  @override
  void dispose() {
    controller.dispose();
    for (final c in _gridControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('floating_menu_expendable'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Floating'),
              Tab(text: 'Anchored'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _FloatingDemo(scheme: scheme, controller: controller),
            _AnchoredDemo(scheme: scheme, controllers: _gridControllers),
          ],
        ),
      ),
    );
  }
}

class _FloatingDemo extends StatelessWidget {
  final ColorScheme scheme;
  final FloatingMenuExpendableController controller;

  const _FloatingDemo({required this.scheme, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Simple, pleasant background.
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                scheme.primary.withValues(alpha: 0.16),
                scheme.surface,
                scheme.secondary.withValues(alpha: 0.10),
              ],
            ),
          ),
          child: const SizedBox.expand(),
        ),
        SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Floating Menu',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Drag the handle to any edge, then tap to open.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Card(
                      elevation: 0,
                      color: scheme.surface.withValues(alpha: 0.75),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: scheme.outlineVariant.withValues(alpha: 0.60),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(Icons.touch_app, color: scheme.primary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Tip: Tap outside the panel to close.',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: scheme.onSurfaceVariant),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // The actual package widget.
        FloatingMenuExpendable(
          controller: controller,
          panelWidth: 340,
          panelHeight: 280,
          handleWidth: 46,
          handleHeight: 46,
          initialPosition: const Offset(16, 120),
          openMode: FloatingMenuExpendableOpenMode.vertical,
          expandPanelFromHandle: true,
          style: FloatingMenuExpendableStyle(
            barrierColor: scheme.scrim.withValues(alpha: 0.35),
            barrierBlurSigmaX: 10,
            barrierBlurSigmaY: 10,
            panelBorderRadius: const BorderRadius.all(Radius.circular(8)),
            panelDecoration: BoxDecoration(
              color: scheme.surface.withValues(alpha: 0.85),
              borderRadius: const BorderRadius.all(Radius.circular(8)),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.60),
              ),
            ),
            handleInkBorderRadius: BorderRadius.circular(8),
          ),
          handleChild: Container(
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [scheme.primary, scheme.primaryContainer],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(Icons.menu_rounded, color: scheme.onPrimary),
          ),
          panelChild: _MenuPanel(controller: controller),
        ),
      ],
    );
  }
}

class _AnchoredDemo extends StatelessWidget {
  final ColorScheme scheme;
  final List<FloatingMenuAnchoredOverlayController> controllers;

  const _AnchoredDemo({required this.scheme, required this.controllers});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primary.withValues(alpha: 0.10),
            scheme.surface,
            scheme.secondary.withValues(alpha: 0.08),
          ],
        ),
      ),
      child: SafeArea(
        child: GridView.builder(
          key: const Key('anchored_grid'),
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.35,
          ),
          itemCount: controllers.length,
          itemBuilder: (context, index) {
            final c = controllers[index];
            return FloatingMenuAnchoredOverlay(
              controller: c,
              closeOnScroll: true,
              expandFromAnchor: true,
              panelWidth: 280,
              panelHeight: 210,
              style: FloatingMenuAnchoredOverlayStyle(
                barrierColor: scheme.scrim.withValues(alpha: 0.40),
                barrierBlurSigmaX: 10,
                barrierBlurSigmaY: 10,
                panelBorderRadius: const BorderRadius.all(Radius.circular(16)),
                panelDecoration: BoxDecoration(
                  color: scheme.surface.withValues(alpha: 0.92),
                  borderRadius: const BorderRadius.all(Radius.circular(16)),
                  border: Border.all(
                    color: scheme.outlineVariant.withValues(alpha: 0.65),
                  ),
                ),
              ),
              panelChild: _AnchoredPanel(
                title: 'Item ${index + 1}',
                onClose: c.close,
              ),
              anchorBuilder: (context, toggle) {
                return InkWell(
                  key: Key('grid_item_$index'),
                  borderRadius: BorderRadius.circular(18),
                  onTap: () {
                    // Example behavior: close others (left to the user).
                    for (final other in controllers) {
                      if (other != c) other.close();
                    }
                    toggle();
                  },
                  child: _GridCard(index: index),
                );
              },
              child: _GridCard(index: index),
            );
          },
        ),
      ),
    );
  }
}

class _GridCard extends StatelessWidget {
  final int index;

  const _GridCard({required this.index});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: scheme.surface.withValues(alpha: 0.70),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.60)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.apps_rounded, color: scheme.primary),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text('Tap', style: TextStyle(color: scheme.primary)),
                ),
              ],
            ),
            const Spacer(),
            Text(
              'Card ${index + 1}',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'Opens an anchored overlay without moving the grid.',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnchoredPanel extends StatelessWidget {
  final String title;
  final VoidCallback onClose;

  const _AnchoredPanel({required this.title, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      type: MaterialType.transparency,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close_rounded),
                  color: scheme.onSurfaceVariant,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Expanded(
              child: SingleChildScrollView(
                primary: false,
                child: Text(
                  'This panel is rendered in an overlay anchored to the card.\n'
                  'Background is blurred/dimmed and grid items stay fixed.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: onClose,
              icon: const Icon(Icons.done_rounded),
              label: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuPanel extends StatelessWidget {
  final FloatingMenuExpendableController controller;

  const _MenuPanel({required this.controller});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      type: MaterialType.transparency,
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16.0, 8, 8.0, 0),
              child: Text(
                'Menu',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          Expanded(
            flex: 6,
            child: ListView(
              padding: const EdgeInsets.all(12),
              primary: false,
              children: [
                const SizedBox(height: 4),
                Divider(height: 1, color: scheme.outlineVariant),
                const SizedBox(height: 8),
                _MenuTile(
                  icon: Icons.person_outline_rounded,
                  title: 'Profile',
                  onTap: controller.close,
                ),
                _MenuTile(
                  icon: Icons.settings_outlined,
                  title: 'Settings',
                  onTap: controller.close,
                ),
                _MenuTile(
                  icon: Icons.logout_rounded,
                  title: 'Logout',
                  onTap: controller.close,
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: controller.close,
                  icon: const Icon(Icons.done_rounded),
                  label: const Text('Done'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: scheme.primary),
      title: Text(title),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10),
      dense: true,
    );
  }
}
