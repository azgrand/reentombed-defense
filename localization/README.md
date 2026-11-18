# Localization

Godot loads the native `.po` catalogues registered in `project.godot`. Stable semantic keys are used through `tr()` and named `{value}` placeholders via `String.format(Dictionary)`. Preferences select the saved locale, Spanish for Spanish systems, otherwise English; unsupported saved locales fall back to English.

To add a language, copy en.po, translate each msgstr without altering placeholders, set the Language header and register the new file in project.godot. Add its language selector entry and supported locale validation in settings_store.gd. Run `python3 tools/check_localization.py`, extend the validator for the third catalogue, then import with Godot and check all visible text in the target viewport.
