from pathlib import Path

p = Path("android/app/build.gradle.kts")

if not p.exists():
    raise SystemExit("ERREUR: android/app/build.gradle.kts introuvable")

s = p.read_text()

# Imports nécessaires
imports = """import java.util.Properties
import java.io.FileInputStream

"""

if "import java.util.Properties" not in s:
    marker = "plugins {"
    if marker not in s:
        raise SystemExit("ERREUR: bloc plugins introuvable")
    s = s.replace(marker, imports + marker, 1)

# Lecture de key.properties
if "val keystoreProperties = Properties()" not in s:
    marker = "android {"

    block = """val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

"""

    if marker not in s:
        raise SystemExit("ERREUR: bloc android introuvable")

    s = s.replace(marker, block + marker, 1)

# Configuration release
if 'create("release")' not in s:
    marker = "    buildTypes {"

    block = """    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }

"""

    if marker not in s:
        raise SystemExit("ERREUR: buildTypes introuvable")

    s = s.replace(marker, block + marker, 1)

old = 'signingConfig = signingConfigs.getByName("debug")'
new = 'signingConfig = signingConfigs.getByName("release")'

if old in s:
    s = s.replace(old, new, 1)
elif new not in s:
    raise SystemExit("ERREUR: signingConfig release introuvable")

p.write_text(s)

print("ANDROID SIGNING CONFIG OK")
