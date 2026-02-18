import 'package:flutter/material.dart';
import 'package:opti_job_app/core/shell/core_shell_breakpoints.dart';

enum CoreShellVariant { public, candidate, company, immersive }

enum CoreShellSidebarAlignment { start, end }

class CoreShell extends StatelessWidget {
  const CoreShell({
    super.key,
    required this.body,
    this.variant = CoreShellVariant.public,
    this.title = 'OPTIJOB',
    this.leading,
    this.actions,
    this.appBar,
    this.showAppBar,
    this.backgroundColor,
    this.bodyPadding,
    this.safeArea = false,
    this.drawer,
    this.endDrawer,
    this.sidebar,
    this.sidebarAlignment = CoreShellSidebarAlignment.start,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.floatingActionButtonAnimator,
    this.navigationBreakpoint = coreShellNavigationBreakpoint,
    this.extendBody = false,
    this.extendBodyBehindAppBar = false,
    this.resizeToAvoidBottomInset,
  });

  final Widget body;
  final CoreShellVariant variant;
  final String title;
  final Widget? leading;
  final List<Widget>? actions;
  final PreferredSizeWidget? appBar;
  final bool? showAppBar;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? bodyPadding;
  final bool safeArea;
  final Widget? drawer;
  final Widget? endDrawer;
  final Widget? sidebar;
  final CoreShellSidebarAlignment sidebarAlignment;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final FloatingActionButtonAnimator? floatingActionButtonAnimator;
  final double navigationBreakpoint;
  final bool extendBody;
  final bool extendBodyBehindAppBar;
  final bool? resizeToAvoidBottomInset;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final usesExpandedNavigation = width >= navigationBreakpoint;
    final showResolvedAppBar =
        showAppBar ?? variant != CoreShellVariant.immersive;

    Widget content = body;
    if (bodyPadding != null) {
      content = Padding(padding: bodyPadding!, child: content);
    }
    if (safeArea) {
      content = SafeArea(child: content);
    }

    if (usesExpandedNavigation && sidebar != null) {
      final placesSidebarAtStart =
          sidebarAlignment == CoreShellSidebarAlignment.start;
      content = Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (placesSidebarAtStart) sidebar!,
          Expanded(child: content),
          if (!placesSidebarAtStart) sidebar!,
        ],
      );
    }

    return Scaffold(
      backgroundColor:
          backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
      appBar: showResolvedAppBar
          ? appBar ??
                CoreShellAppBar(
                  variant: variant,
                  title: title,
                  leading: leading,
                  actions: actions,
                )
          : null,
      drawer: usesExpandedNavigation ? null : drawer,
      endDrawer: usesExpandedNavigation ? null : endDrawer,
      bottomNavigationBar: usesExpandedNavigation ? null : bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      floatingActionButtonAnimator: floatingActionButtonAnimator,
      extendBody: extendBody,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      body: content,
    );
  }
}

class CoreShellAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CoreShellAppBar({
    super.key,
    this.variant = CoreShellVariant.public,
    this.title = 'OPTIJOB',
    this.leading,
    this.actions,
    this.centerTitle,
    this.automaticallyImplyLeading,
  });

  final CoreShellVariant variant;
  final String title;
  final Widget? leading;
  final List<Widget>? actions;
  final bool? centerTitle;
  final bool? automaticallyImplyLeading;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final config = _CoreShellVariantConfig.from(variant);

    return AppBar(
      title: Text(title, style: _titleStyle(theme, colorScheme, variant)),
      centerTitle: centerTitle ?? config.centerTitle,
      leading: leading,
      actions: actions,
      automaticallyImplyLeading:
          automaticallyImplyLeading ?? config.automaticallyImplyLeading,
      backgroundColor: config.backgroundColor(theme, colorScheme),
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      shape: config.hasBottomBorder
          ? Border(
              bottom: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.55),
              ),
            )
          : null,
    );
  }

  TextStyle? _titleStyle(
    ThemeData theme,
    ColorScheme colorScheme,
    CoreShellVariant variant,
  ) {
    final baseStyle = theme.textTheme.titleLarge;
    switch (variant) {
      case CoreShellVariant.public:
      case CoreShellVariant.candidate:
      case CoreShellVariant.company:
        return baseStyle?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: 1.6,
          color: colorScheme.primary,
        );
      case CoreShellVariant.immersive:
        return baseStyle?.copyWith(
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
        );
    }
  }
}

class _CoreShellVariantConfig {
  const _CoreShellVariantConfig({
    required this.centerTitle,
    required this.automaticallyImplyLeading,
    required this.hasBottomBorder,
    required this.isImmersive,
  });

  final bool centerTitle;
  final bool automaticallyImplyLeading;
  final bool hasBottomBorder;
  final bool isImmersive;

  static _CoreShellVariantConfig from(CoreShellVariant variant) {
    return switch (variant) {
      CoreShellVariant.public => const _CoreShellVariantConfig(
        centerTitle: true,
        automaticallyImplyLeading: true,
        hasBottomBorder: false,
        isImmersive: false,
      ),
      CoreShellVariant.candidate => const _CoreShellVariantConfig(
        centerTitle: true,
        automaticallyImplyLeading: true,
        hasBottomBorder: true,
        isImmersive: false,
      ),
      CoreShellVariant.company => const _CoreShellVariantConfig(
        centerTitle: true,
        automaticallyImplyLeading: true,
        hasBottomBorder: true,
        isImmersive: false,
      ),
      CoreShellVariant.immersive => const _CoreShellVariantConfig(
        centerTitle: false,
        automaticallyImplyLeading: true,
        hasBottomBorder: false,
        isImmersive: true,
      ),
    };
  }

  Color? backgroundColor(ThemeData theme, ColorScheme colorScheme) {
    if (isImmersive) return colorScheme.surface.withValues(alpha: 0.92);
    return theme.appBarTheme.backgroundColor;
  }
}
