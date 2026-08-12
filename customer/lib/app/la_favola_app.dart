import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:la_favola/design_system/la_favola_theme.dart';
import 'package:la_favola/features/builder/pizza_builder_screen.dart';
import 'package:la_favola/features/menu/home_menu_screen.dart';
import 'package:la_favola/prototype/prototype_components.dart';
import 'package:la_favola/prototype/prototype_state.dart';

class LaFavolaApp extends StatelessWidget {
  const LaFavolaApp({
    super.key,
    this.initialScreen = PrototypeScreen.homeMenu,
    this.initialMenuState = MenuPrototypeState.ready,
    this.initialBuilderState = BuilderPrototypeState.ready,
  });

  final PrototypeScreen initialScreen;
  final MenuPrototypeState initialMenuState;
  final BuilderPrototypeState initialBuilderState;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'La Favola • Prototipo locale',
      debugShowCheckedModeBanner: false,
      theme: buildLaFavolaTheme(),
      home:
          kDebugMode
              ? PrototypeShell(
                initialScreen: initialScreen,
                initialMenuState: initialMenuState,
                initialBuilderState: initialBuilderState,
              )
              : const _PrototypeUnavailableScreen(),
    );
  }
}

class PrototypeShell extends StatefulWidget {
  const PrototypeShell({
    super.key,
    this.initialScreen = PrototypeScreen.homeMenu,
    this.initialMenuState = MenuPrototypeState.ready,
    this.initialBuilderState = BuilderPrototypeState.ready,
  });

  final PrototypeScreen initialScreen;
  final MenuPrototypeState initialMenuState;
  final BuilderPrototypeState initialBuilderState;

  @override
  State<PrototypeShell> createState() => _PrototypeShellState();
}

class _PrototypeShellState extends State<PrototypeShell> {
  late PrototypeScreen _screen;
  late MenuPrototypeState _menuState;
  late BuilderPrototypeState _builderState;

  @override
  void initState() {
    super.initState();
    _screen = widget.initialScreen;
    _menuState = widget.initialMenuState;
    _builderState = widget.initialBuilderState;
  }

  void _showScreen(PrototypeScreen screen) {
    setState(() => _screen = screen);
  }

  @override
  Widget build(BuildContext context) {
    final title = switch (_screen) {
      PrototypeScreen.homeMenu => 'Menu',
      PrototypeScreen.pizzaBuilder => 'Configura',
    };

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final chromeMaxHeight = constraints.maxHeight * 0.45;
            return Column(
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: constraints.maxWidth,
                    maxWidth: constraints.maxWidth,
                    maxHeight: chromeMaxHeight,
                  ),
                  child: SingleChildScrollView(
                    key: const Key('prototype-chrome-scroll'),
                    child: Column(
                      children: [
                        const PrototypeNotice(),
                        PrototypeHeader(
                          title: title,
                          onBack:
                              _screen == PrototypeScreen.pizzaBuilder
                                  ? () => _showScreen(PrototypeScreen.homeMenu)
                                  : null,
                          backKey: const Key('header-back-menu'),
                        ),
                        PrototypeStateSelector(
                          screen: _screen,
                          menuState: _menuState,
                          builderState: _builderState,
                          onScreenChanged: _showScreen,
                          onMenuStateChanged: (state) {
                            setState(() {
                              _screen = PrototypeScreen.homeMenu;
                              _menuState = state;
                            });
                          },
                          onBuilderStateChanged: (state) {
                            setState(() {
                              _screen = PrototypeScreen.pizzaBuilder;
                              _builderState = state;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: switch (_screen) {
                    PrototypeScreen.homeMenu => HomeMenuScreen(
                      state: _menuState,
                      onStateChanged:
                          (state) => setState(() => _menuState = state),
                      onOpenBuilder:
                          () => _showScreen(PrototypeScreen.pizzaBuilder),
                    ),
                    PrototypeScreen.pizzaBuilder => PizzaBuilderScreen(
                      state: _builderState,
                      onStateChanged:
                          (state) => setState(() => _builderState = state),
                      onBack: () => _showScreen(PrototypeScreen.homeMenu),
                    ),
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PrototypeUnavailableScreen extends StatelessWidget {
  const _PrototypeUnavailableScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Questo artefatto è un prototipo locale disponibile soltanto '
              'nelle build di debug.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
