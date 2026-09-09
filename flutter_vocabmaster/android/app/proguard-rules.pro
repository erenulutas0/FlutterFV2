# R8 rules for the release build.
#
# Flutter's Gradle plugin turns minification on for `release` and adds this file
# when it exists (FlutterPlugin.kt, "Optionally adds custom Proguard rules"), so
# app/build.gradle does not need to mention it.

# ---------------------------------------------------------------------------
# Gson, and flutter_local_notifications on top of it
# ---------------------------------------------------------------------------
# The shipped build throws this on every reminder call:
#
#   FlutterLocalNotificationsPlugin.loadScheduledNotifications
#   -> IllegalStateException: TypeToken must be created with a type argument;
#      When using code shrinkers (ProGuard, R8, ...) make sure that generic
#      signatures are preserved.
#
# The plugin stores its scheduled notifications as JSON and reads them back
# through `new TypeToken<ArrayList<NotificationDetails>>() {}`. Gson recovers
# the element type by asking that anonymous subclass for its generic
# superclass, which is its Signature attribute and nothing else.
#
# What goes wrong is narrower than it looks, and worth writing down because
# three plausible guesses about it were wrong. The anonymous subclass is not
# removed -- R8's usage report always listed it as present. Its signature is not
# removed either. The signature is TRUNCATED: dexdump on the shipped build reads
#
#   FlutterLocalNotificationsPlugin$1  extends Lk4/a;
#     class Signature: "Lk4/a;"
#
# where k4.a is the renamed TypeToken. The raw type survived and the type
# argument was dropped, so getGenericSuperclass() hands Gson a plain Class
# rather than a ParameterizedType -- which is the sentence in the message,
# exactly. `-keepattributes Signature` does not prevent that and was already in
# force; nor does keeping the subclass. R8 drops the parameterization because
# nothing told it to hold the raw type still. Keeping TypeToken itself does, and
# Gson ships that rule for this reason: its own comment on it reads "keep class
# TypeToken (respectively its generic signature)". With the rule, the same dump
# reads
#
#   FlutterLocalNotificationsPlugin$1  extends Lcom/google/gson/reflect/TypeToken;
#     class Signature: "Lcom/google/gson/reflect/TypeToken<Ljava/util/ArrayList<
#                       Lcom/dexterous/.../NotificationDetails;>;>;"
#
# R8 full mode is not the culprit and does not need turning off. That was tried:
# it fixes this too, and pays for it across the whole app to buy nothing.
#
# Both zonedSchedule and cancel read that cache, so on every release build --
# and no debug one, which is why the test suite and every hour of local running
# had nothing to say about it -- the local reminders were neither set nor
# cleared. The reminder is the app's only way of asking someone to come back,
# and the one build it fails in is the only one real learners have.
-keepattributes Signature
-keepattributes *Annotation*
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken
-keepclassmembers,allowobfuscation class * {
  @com.google.gson.annotations.SerializedName <fields>;
}

# The plugin's own classes: its notification models are deserialised field by
# field, and its receivers are reached from the manifest, neither of which R8
# can see through.
-keep class com.dexterous.** { *; }
