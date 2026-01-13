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

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Stack(
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
                            color: scheme.outlineVariant.withValues(
                              alpha: 0.60,
                            ),
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
                                      ?.copyWith(
                                        color: scheme.onSurfaceVariant,
                                      ),
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
