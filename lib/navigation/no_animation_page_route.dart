import 'package:flutter/material.dart';

class NoAnimationPageRoute<T> extends PageRoute<T> {
  final WidgetBuilder builder;

  NoAnimationPageRoute({
    required this.builder,
    RouteSettings? settings,
  }) : super(
          settings: settings,
          fullscreenDialog: false,
        );

  @override
  bool get opaque => true; // Keep this true for better performance

  @override
  bool get barrierDismissible => false;

  @override
  Color? get barrierColor => Colors.transparent; // Transparent barrier instead of null

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => Duration.zero;
  
  @override
  Duration get reverseTransitionDuration => Duration.zero;
  
  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    final Widget result = builder(context);
    return Semantics(
      scopesRoute: true,
      explicitChildNodes: true,
      child: result,
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: Tween<double>(begin: 1.0, end: 1.0).animate(animation),
      child: child,
    );
  }
}