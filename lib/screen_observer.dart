library screen_observer;

import 'package:flutter/material.dart';

abstract class ScreenTransitionAware {
  /// Called when the top screen has been popped off, and the current screen
  /// shows up.
  void didPopNextScreen() {}

  /// Called when a new screen has been pushed, and the current screen is no
  /// longer visible.
  void didPushNextScreen() {}
}

typedef ScreenPredicate = bool Function(Route<dynamic> route);

class ScreenObserver<R extends Route<dynamic>> extends NavigatorObserver {

  final ScreenPredicate screenPredicate;

  final Map<R, Set<ScreenTransitionAware>> _listeners =
  <R, Set<ScreenTransitionAware>>{};

  /// Verify if [route] is a Screen.
  /// The incoming [route] is a Screen if the following condition is met:
  /// - [route] is a PageRoute
  static ScreenPredicate kDefaultScreenPredicate = (Route<dynamic> route) {
    return route is PageRoute;
  };

  ScreenObserver({ScreenPredicate screenPredicate})
      : this.screenPredicate = screenPredicate ?? kDefaultScreenPredicate;

  /// Subscribe [screenAware] to be informed about changes to [screen].
  ///
  /// Going forward, [screenAware] will be informed about qualifying changes
  /// to screens, e.g. when a screen is covered by another screen or when a screen
  /// is popped off the [Navigator] stack.
  void subscribe(ScreenTransitionAware screenAware, R route) {
    assert(screenAware != null);
    assert(route != null);
    final Set<ScreenTransitionAware> subscribers =
    _listeners.putIfAbsent(route, () => <ScreenTransitionAware>{});
    subscribers.add(screenAware);
  }

  /// Unsubscribe [screenAware].
  ///
  /// [screenAware] is no longer informed about changes to its screen. If the given argument was
  /// subscribed to multiple types, this will unregister it (once) from each type.
  void unsubscribe(ScreenTransitionAware screenAware) {
    assert(screenAware != null);
    for (final R route in _listeners.keys) {
      final Set<ScreenTransitionAware> subscribers = _listeners[route];
      subscribers?.remove(screenAware);
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic> previousRoute) {
    if (route is R && previousRoute is R) {
      final List<ScreenTransitionAware> previousSubscribers =
      _listeners[previousRoute]?.toList();

      if (previousSubscribers != null) {
        for (final ScreenTransitionAware screenAware in previousSubscribers) {
          if (screenPredicate(route)) {
            screenAware.didPopNextScreen();
          }
        }
      }
    }
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic> previousRoute) {
    if (route is R && previousRoute is R) {
      final Set<ScreenTransitionAware> previousSubscribers =
      _listeners[previousRoute];

      if (previousSubscribers != null) {
        for (final ScreenTransitionAware screenAware in previousSubscribers) {
          if (screenPredicate(route)) {
            screenAware.didPushNextScreen();
          }
        }
      }
    }
  }

}

