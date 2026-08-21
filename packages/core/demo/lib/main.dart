import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

void main() {
  runApp(const DemoApp());
}

final GoRouter _router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const DemoHomePage(),
    ),
  ],
);

/// Demo app showcasing the core package (theme, components).
class DemoApp extends StatelessWidget {
  /// Creates the demo app.
  const DemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return App(
      router: _router,
      appTitle: 'Core Demo',
    );
  }
}

/// One component variant on show in the gallery.
class ComponentDemo {
  /// Creates a demo of a single component variant.
  const ComponentDemo({required this.name, required this.builder});

  /// The variant's label, e.g. `'Disabled'`.
  final String name;

  /// Builds the component as it should appear in the gallery.
  final WidgetBuilder builder;
}

/// A group of demos covering one type of component (inputs, chips, ...).
class ComponentSection {
  /// Creates a section titled [title] holding [demos].
  const ComponentSection({required this.title, required this.demos});

  /// The component type this section covers, e.g. `'Inputs'`.
  final String title;

  /// The variants shown under this section, in display order.
  final List<ComponentDemo> demos;
}

/// The gallery's contents: every `core` component, grouped by component type.
///
/// When you add a component to `core`, add its demos to the section matching
/// its type — or add a new section when it's the first component of its type.
final List<ComponentSection> componentSections = [
  ComponentSection(
    title: 'Buttons',
    demos: [
      ComponentDemo(
        name: 'Primary',
        builder: (context) => PillButton(
          label: 'Continue',
          onPressed: () => _showTapped(context, 'Primary button'),
        ),
      ),
      ComponentDemo(
        name: 'Secondary',
        builder: (context) => PillButton(
          label: 'Maybe later',
          onPressed: () => _showTapped(context, 'Secondary button'),
          theme: PillButtonThemeData.fallback(
            context,
            variant: PillButtonVariant.secondary,
          ),
        ),
      ),
      ComponentDemo(
        name: 'Ghost',
        builder: (context) => PillButton(
          label: 'Skip for now',
          onPressed: () => _showTapped(context, 'Ghost button'),
          theme: PillButtonThemeData.fallback(
            context,
            variant: PillButtonVariant.ghost,
          ),
        ),
      ),
      ComponentDemo(
        // The state easiest to get wrong. Dimmed is *not* disabled: the tap
        // still lands, so a submit on an incomplete form answers with the
        // message naming what is missing instead of doing nothing silently.
        name: 'Dimmed — still reports taps',
        builder: (context) => PillButton(
          label: 'Continue',
          isDimmed: true,
          onPressed: () => _showTapped(context, 'Dimmed button'),
        ),
      ),
      ComponentDemo(
        // The spinner is leading and the label is unchanged, so the button
        // keeps its width. Compare against swapping label for spinner.
        name: 'Busy',
        builder: (context) => PillButton(
          label: 'Continue',
          isBusy: true,
          onPressed: () {},
        ),
      ),
      ComponentDemo(
        name: 'Disabled',
        builder: (context) => const PillButton(label: 'Continue'),
      ),
      ComponentDemo(
        name: 'Icon action',
        builder: (context) => Align(
          alignment: Alignment.centerLeft,
          child: IconActionButton(
            icon: AppIcons.chevronLeft,
            semanticLabel: 'Go back',
            onPressed: () => _showTapped(context, 'Back'),
          ),
        ),
      ),
      ComponentDemo(
        name: 'Icon action, disabled',
        builder: (context) => const Align(
          alignment: Alignment.centerLeft,
          child: IconActionButton(
            icon: AppIcons.chevronLeft,
            semanticLabel: 'Go back',
          ),
        ),
      ),
    ],
  ),
  ComponentSection(
    title: 'Inputs',
    demos: [
      ComponentDemo(
        name: 'Default',
        builder: (context) => const FormTextInput<String>(
          viewModel: FormTextInputViewModel<String>(
            labelText: 'Email',
            hintText: 'you@example.com',
          ),
        ),
      ),
      ComponentDemo(
        name: 'With prefix and suffix icons',
        builder: (context) => FormTextInput<String>(
          viewModel: const FormTextInputViewModel<String>(hintText: 'Search'),
          theme: FormTextInputThemeData.fallback(
            context,
            showPrefixIcon: true,
            showSuffixIcon: true,
          ),
          prefixIcon: const Icon(Icons.search),
          suffixIcon: const Icon(Icons.close),
          onSuffixIconPressed: () {},
        ),
      ),
      ComponentDemo(
        name: 'Obscured',
        builder: (context) => const FormTextInput<String>(
          viewModel: FormTextInputViewModel<String>(
            labelText: 'Password',
            inputValue: 'hunter2',
            isInputObscured: true,
          ),
        ),
      ),
      ComponentDemo(
        name: 'With error',
        builder: (context) => const FormTextInput<String>(
          viewModel: FormTextInputViewModel<String>(
            labelText: 'Email',
            inputValue: 'not-an-email',
            errorText: 'Enter a valid email address',
          ),
        ),
      ),
      ComponentDemo(
        name: 'Disabled',
        builder: (context) => FormTextInput<String>(
          viewModel: const FormTextInputViewModel<String>(
            labelText: 'Email',
            inputValue: 'you@example.com',
          ),
          theme: FormTextInputThemeData.fallback(context, isDisabled: true),
        ),
      ),
      ComponentDemo(
        // The sibling input: label above, always visible, outlined. Tap in and
        // out to see the focus ring drawn inside the border — the field's
        // height must not change.
        name: 'Labelled (label above, outlined)',
        builder: (context) => const LabeledTextField(
          labelText: 'Email',
          hintText: 'you@example.com',
          keyboardType: TextInputType.emailAddress,
        ),
      ),
      ComponentDemo(
        // Both slots at once — the arrangement PasswordField is built from.
        name: 'Labelled, with a trailing action and a footer',
        builder: (context) => LabeledTextField(
          labelText: 'Workspace',
          hintText: 'acme',
          trailing: IconActionButton(
            icon: AppIcons.check,
            semanticLabel: 'Check availability',
            theme: IconActionButtonThemeData.fallback(context, size: 42),
            onPressed: () => _showTapped(context, 'Check availability'),
          ),
          footer: Text(
            'Lowercase letters and dashes only.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ),
      ComponentDemo(
        // Log-in: no meter. Scoring a password someone already has is
        // pointless advice.
        name: 'Password (log in)',
        builder: (context) => const _PasswordFieldDemo(),
      ),
      ComponentDemo(
        // Sign-up: the meter tracks the controller, so it stays correct after
        // a paste or an autofill — neither of which fires onChanged.
        name: 'Password with strength (sign up)',
        builder: (context) => const _PasswordFieldDemo(showStrength: true),
      ),
    ],
  ),
  ComponentSection(
    title: 'Backdrops',
    demos: [
      ComponentDemo(
        // Bounded here only so it fits a gallery card. In a page this fills
        // the Scaffold body.
        name: 'Ambient wash — no artwork, all scheme',
        builder: (context) => ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 160,
            child: AmbientBackdrop(
              child: Center(
                child: Text(
                  'Content sits on top',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
          ),
        ),
      ),
      ComponentDemo(
        // Proof it restyles: one overridden wash and the whole mood changes,
        // with nothing to redraw and no asset to swap.
        name: 'Restyled by overriding the washes',
        builder: (context) => ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 160,
            child: AmbientBackdrop(
              theme: AmbientBackdropThemeData(
                groundColor: Theme.of(context).colorScheme.surface,
                washes: [
                  AmbientWash(
                    color: Theme.of(context).colorScheme.error,
                    center: Alignment.topLeft,
                    alpha: 0.28,
                  ),
                ],
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ),
    ],
  ),
  ComponentSection(
    title: 'Navigation',
    demos: [
      ComponentDemo(
        // Tap to switch. Watch the active icon's contrast against the filled
        // pill in both light and dark — that pairing is the easiest thing here
        // to get wrong.
        name: 'Nav bar — tap to switch',
        builder: (context) => const _NavBarDemo(),
      ),
      ComponentDemo(
        // Two destinations: the pill hugs its contents rather than stretching,
        // because it is placed by a wrapper and must not assume full width.
        name: 'Nav bar with two destinations',
        builder: (context) => const _NavBarDemo(itemCount: 2),
      ),
      ComponentDemo(
        // Tap anywhere on the line, not just the coloured words — that is the
        // whole point of the component.
        name: 'Prompt with an action',
        builder: (context) => PromptLink(
          prompt: 'Already have an account? ',
          action: 'Log in',
          onPressed: () => _showTapped(context, 'Log in'),
        ),
      ),
      ComponentDemo(
        name: 'The other direction',
        builder: (context) => PromptLink(
          prompt: "Don't have an account? ",
          action: 'Sign up',
          onPressed: () => _showTapped(context, 'Sign up'),
        ),
      ),
    ],
  ),
  ComponentSection(
    title: 'Password strength',
    demos: [
      ComponentDemo(
        name: 'Empty — no fill, no caption',
        builder: (context) => PasswordStrengthMeter(
          viewModel: PasswordStrengthMeterViewModel.evaluate(''),
        ),
      ),
      ComponentDemo(
        // The state easiest to get wrong. Four characters satisfy two of the
        // length-blind variety rules; without the minimum-length floor this
        // would read "Good", one rung below what the form will accept.
        name: r"Under the minimum — 'Ab1!' is Short, not Good",
        builder: (context) => PasswordStrengthMeter(
          viewModel: PasswordStrengthMeterViewModel.evaluate('Ab1!'),
        ),
      ),
      ComponentDemo(
        name: 'Okay',
        builder: (context) => PasswordStrengthMeter(
          viewModel: PasswordStrengthMeterViewModel.evaluate('correcthorse'),
        ),
      ),
      ComponentDemo(
        name: 'Strong',
        builder: (context) => PasswordStrengthMeter(
          viewModel: PasswordStrengthMeterViewModel.evaluate(r'Corr3ct-H0rse!'),
        ),
      ),
    ],
  ),
  ComponentSection(
    title: 'Form feedback',
    demos: [
      ComponentDemo(
        name: 'Error',
        builder: (context) => const FormMessage(
          message: "That email doesn't look quite right — mind checking it?",
        ),
      ),
      ComponentDemo(
        // Both tones carry a glyph. Squint at these in greyscale: the meaning
        // has to survive without the colour.
        name: 'Success',
        builder: (context) => const FormMessage(
          message: 'Saved. You can close this now.',
          tone: FormMessageTone.success,
        ),
      ),
    ],
  ),
  ComponentSection(
    title: 'Chips',
    demos: [
      ComponentDemo(
        name: 'Default',
        builder: (context) => LabelChip(
          label: 'Label',
          onTapped: () => _showTapped(context, 'Label chip'),
        ),
      ),
      ComponentDemo(
        name: 'Selected',
        builder: (context) => LabelChip(
          label: 'Selected',
          onTapped: () => _showTapped(context, 'Selected label chip'),
          theme: LabelChipThemeData.fallback(context, isSelected: true),
        ),
      ),
    ],
  ),
];

/// Owns the selected index a [NavBar] needs. The bar is the pill only, so the
/// gallery is what centres it — exactly as an app-level wrapper would place it
/// over a page.
class _NavBarDemo extends StatefulWidget {
  const _NavBarDemo({this.itemCount = 3});

  final int itemCount;

  @override
  State<_NavBarDemo> createState() => _NavBarDemoState();
}

class _NavBarDemoState extends State<_NavBarDemo> {
  static const List<NavBarItem> _allItems = [
    NavBarItem(icon: AppIcons.home, semanticLabel: 'Home'),
    NavBarItem(icon: AppIcons.check, semanticLabel: 'Tasks'),
    NavBarItem(icon: AppIcons.settings, semanticLabel: 'Settings'),
  ];

  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) => Align(
        child: NavBar(
          items: _allItems.take(widget.itemCount).toList(),
          selectedIndex: _selectedIndex,
          onSelected: (index) => setState(() => _selectedIndex = index),
        ),
      );
}

/// Owns the controller a [PasswordField] needs, so the gallery's stateless
/// demo builders do not have to leak one.
class _PasswordFieldDemo extends StatefulWidget {
  const _PasswordFieldDemo({this.showStrength = false});

  final bool showStrength;

  @override
  State<_PasswordFieldDemo> createState() => _PasswordFieldDemoState();
}

class _PasswordFieldDemoState extends State<_PasswordFieldDemo> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PasswordField(
        controller: _controller,
        labelText: 'Password',
        hintText: 'At least 8 characters',
        // In a real app these come from the app's l10n, which is exactly why
        // the component requires them rather than defaulting to English.
        showPasswordLabel: 'Show password',
        hidePasswordLabel: 'Hide password',
        showStrength: widget.showStrength,
      );
}

void _showTapped(BuildContext context, String what) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text('$what tapped')));
}

/// Home page listing the core components, grouped into sections by type.
class DemoHomePage extends StatelessWidget {
  /// Creates the demo home page.
  const DemoHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Core Demo')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: componentSections.length,
        itemBuilder: (context, index) =>
            _ComponentSectionView(section: componentSections[index]),
      ),
    );
  }
}

class _ComponentSectionView extends StatelessWidget {
  const _ComponentSectionView({required this.section});

  final ComponentSection section;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(section.title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final demo in section.demos)
                    _ComponentDemoView(demo: demo),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ComponentDemoView extends StatelessWidget {
  const _ComponentDemoView({required this.demo});

  final ComponentDemo demo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            demo.name,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Builder(builder: demo.builder),
        ],
      ),
    );
  }
}
