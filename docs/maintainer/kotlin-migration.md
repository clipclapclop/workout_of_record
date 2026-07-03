# Kotlin build migration

The current signed Android build succeeds, but Flutter reports that applying the Kotlin Gradle Plugin directly will become unsupported in a future Flutter version. Several Flutter plugins currently apply it as well.

This does not block the first automated release. Before upgrading to a Flutter version that removes compatibility:

1. Review Flutter's built-in Kotlin migration guide.
2. Upgrade plugins to versions that support built-in Kotlin.
3. Remove the temporary compatibility flags only after the application and all plugins are compatible.
4. Run the full release dry run and verify the signed APK on the Pixel.

Do not combine this migration with an unrelated application release; it changes the Android build system and deserves an isolated, recoverable commit.
