# R8 rules for the release build.
#
# Flutter's Gradle plugin turns minification on for `release` and adds this file
# when it exists (FlutterPlugin.kt, "Optionally adds custom Proguard rules"), so
# app/build.gradle does not need to mention it.

# ---------------------------------------------------------------------------
# flutter_local_notifications, and the Gson it reads its cache with
# ---------------------------------------------------------------------------
# The shipped build threw this on the device, on every reminder call:
#
#   FlutterLocalNotificationsPlugin.cancel
#     -> removeNotificationFromCache -> loadScheduledNotifications
#     -> IllegalStateException: TypeToken must be created with a type argument;
#        When using code shrinkers (ProGuard, R8, ...) make sure that generic
#        signatures are preserved.
#
# The plugin stores its scheduled notifications as JSON and reads them back
# through `new TypeToken<ArrayList<NotificationDetails>>() {}`. Gson recovers
# the element type from that anonymous subclass's generic superclass, and R8
# merges the subclass away -- the type it existed to carry goes with it.
#
# `-keepattributes Signature` is already on, from proguard-android-optimize, and
# is not enough by itself: the attribute survives, the class holding it does
# not. It is repeated here anyway so that this rule does not quietly depend on
# which default file a future AGP picks.
#
# Both zonedSchedule and cancel go through that cache, so on every release build
# -- and no debug one, which is why the test suite and every hour of local
# running had nothing to say about it -- the local reminders were neither set
# nor cleared. The reminder is the app's only way of asking someone to come
# back, and the one place it fails is the only build real learners have.
-keepattributes Signature
-keep class * extends com.google.gson.reflect.TypeToken
-keep public class * implements java.lang.reflect.Type
-keep class com.dexterous.** { *; }
