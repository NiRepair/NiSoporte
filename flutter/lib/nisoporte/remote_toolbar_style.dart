import 'package:flutter/material.dart';
import 'package:flutter_hbb/nisoporte/theme.dart';

/// Look of the remote-session toolbar, presentation only.
///
/// Members mirror `_ToolbarTheme` in `desktop/widgets/remote_toolbar.dart`
/// (same names, same const-ness), so hooking it in means pointing each of
/// those members at the one here; no toolbar logic changes. The toolbar's
/// background comes from the ambient `menuBarTheme`, so [wrap] supplies it.
class NiToolbarStyle {
  NiToolbarStyle._();

  static const Color blueColor = NiTheme.accentStrong;
  static const Color hoverBlueColor = NiTheme.accent;
  static const Color inactiveColor = NiTheme.surface2;
  static const Color hoverInactiveColor = NiTheme.border;

  static const Color redColor = NiTheme.error;
  static const Color hoverRedColor = Color(0xFFD94B57);

  static const double height = 20.0;
  static const double dividerHeight = 12.0;

  static const double buttonSize = 30;
  static const double buttonHMargin = 2;
  static const double buttonVMargin = 5;
  static const double iconRadius = 10;
  static const double elevation = 0;

  static const double dividerSpaceToAction = 8;

  static const double menuBorderRadius = 14;
  static const EdgeInsets menuPadding = EdgeInsets.fromLTRB(6, 10, 6, 10);
  static const double menuButtonBorderRadius = 8;

  static const double toolbarRadius = 14;

  static Color borderColor(BuildContext context) => NiTheme.border;

  static Color? dividerColor(BuildContext context) => NiTheme.border;

  static MenuStyle defaultMenuStyle(BuildContext context) => MenuStyle(
        backgroundColor: const MaterialStatePropertyAll(NiTheme.surface),
        surfaceTintColor: const MaterialStatePropertyAll(Colors.transparent),
        elevation: const MaterialStatePropertyAll(4),
        side: const MaterialStatePropertyAll(
            BorderSide(width: 1, color: NiTheme.border)),
        shape: MaterialStatePropertyAll(RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(menuBorderRadius))),
        padding: const MaterialStatePropertyAll(menuPadding),
      );

  static final defaultMenuButtonStyle = ButtonStyle(
    backgroundColor: MaterialStatePropertyAll(Colors.transparent),
    padding: MaterialStatePropertyAll(EdgeInsets.zero),
    overlayColor: MaterialStatePropertyAll(Colors.transparent),
  );

  static Widget borderWrapper(
      BuildContext context, Widget child, BorderRadius borderRadius) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: NiTheme.border, width: 1),
        borderRadius: borderRadius,
      ),
      child: child,
    );
  }

  static final ButtonStyle _menuItemStyle = ButtonStyle(
    foregroundColor: const MaterialStatePropertyAll(NiTheme.text),
    iconColor: const MaterialStatePropertyAll(NiTheme.text2),
    overlayColor: MaterialStateProperty.resolveWith((states) =>
        states.contains(MaterialState.hovered) ||
                states.contains(MaterialState.focused)
            ? NiTheme.surface2
            : null),
    shape: MaterialStatePropertyAll(RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(menuButtonBorderRadius))),
  );

  /// Theme for the session window subtree: toolbar background, dropdown
  /// menus, dividers, checkboxes/radios and tooltips in NiRepair colors.
  static ThemeData themeData(BuildContext context) {
    final base = Theme.of(context);
    return base.copyWith(
      menuBarTheme: MenuBarThemeData(
        style: MenuStyle(
          backgroundColor: const MaterialStatePropertyAll(NiTheme.surface),
          surfaceTintColor: const MaterialStatePropertyAll(Colors.transparent),
          shape: MaterialStatePropertyAll(RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(toolbarRadius))),
        ),
      ),
      menuTheme: MenuThemeData(style: defaultMenuStyle(context)),
      menuButtonTheme: MenuButtonThemeData(style: _menuItemStyle),
      dividerTheme: const DividerThemeData(
          color: NiTheme.border, space: dividerSpaceToAction, thickness: 1),
      checkboxTheme: base.checkboxTheme.copyWith(
        fillColor: MaterialStateProperty.resolveWith((states) =>
            states.contains(MaterialState.selected) ? NiTheme.accent : null),
      ),
      radioTheme: base.radioTheme.copyWith(
        fillColor: MaterialStateProperty.resolveWith((states) =>
            states.contains(MaterialState.selected)
                ? NiTheme.accent
                : NiTheme.muted),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: NiTheme.surface2,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: NiTheme.border),
        ),
        textStyle: const TextStyle(color: NiTheme.text, fontSize: 12),
      ),
      iconTheme: const IconThemeData(color: NiTheme.text2),
    );
  }

  /// Wraps the session toolbar so the ambient theme it reads gets NiRepair
  /// colors. Use as `NiToolbarStyle.wrap(context, RemoteToolbar(...))`.
  static Widget wrap(BuildContext context, Widget toolbar) =>
      Theme(data: themeData(context), child: toolbar);
}
