#!/usr/bin/env bash
set -e

MANIFEST="android/app/src/main/AndroidManifest.xml"
GRADLE="android/app/build.gradle.kts"

echo "Configuration des notifications Android..."

# --------------------------------------------------
# AndroidManifest.xml
# --------------------------------------------------

if ! grep -q "android.permission.RECEIVE_BOOT_COMPLETED" "$MANIFEST"; then
  awk '
    /<manifest / {
      print
      print "    <uses-permission android:name=\"android.permission.RECEIVE_BOOT_COMPLETED\" />"
      next
    }
    { print }
  ' "$MANIFEST" > manifest.tmp

  mv manifest.tmp "$MANIFEST"
fi

if ! grep -q "ScheduledNotificationReceiver" "$MANIFEST"; then
  awk '
    /<\/application>/ {
      print "        <receiver"
      print "            android:name=\"com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver\""
      print "            android:exported=\"false\" />"
      print ""
      print "        <receiver"
      print "            android:name=\"com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver\""
      print "            android:exported=\"false\">"
      print "            <intent-filter>"
      print "                <action android:name=\"android.intent.action.BOOT_COMPLETED\" />"
      print "                <action android:name=\"android.intent.action.MY_PACKAGE_REPLACED\" />"
      print "                <action android:name=\"android.intent.action.QUICKBOOT_POWERON\" />"
      print "                <action android:name=\"com.htc.intent.action.QUICKBOOT_POWERON\" />"
      print "            </intent-filter>"
      print "        </receiver>"
      print ""
    }
    { print }
  ' "$MANIFEST" > manifest.tmp

  mv manifest.tmp "$MANIFEST"
fi

# --------------------------------------------------
# Core library desugaring
# --------------------------------------------------

if ! grep -q "isCoreLibraryDesugaringEnabled" "$GRADLE"; then
  awk '
    /compileOptions[[:space:]]*\{/ {
      print
      print "        isCoreLibraryDesugaringEnabled = true"
      next
    }
    { print }
  ' "$GRADLE" > gradle.tmp

  mv gradle.tmp "$GRADLE"
fi

if ! grep -q "desugar_jdk_libs" "$GRADLE"; then
  cat >> "$GRADLE" <<'GRADLEEOF'

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}
GRADLEEOF
fi

echo "Configuration Android notifications terminée."
