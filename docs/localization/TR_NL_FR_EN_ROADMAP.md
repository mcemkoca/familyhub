# FamilyHub TR / NL / FR / EN Localization Roadmap

## Objective

FamilyHub must render every user-facing system string, article, suggestion, activity, notification and AI response in the selected application language:

- Turkish (`tr`)
- Dutch (`nl`)
- French (`fr`)
- English (`en`)

User-authored content such as family chat messages and private notes remains in the language entered by the user unless the user explicitly requests a translation.

## Initial audit findings

The first repository inspection identified several structural causes for language changes not propagating through the application:

1. `MaterialApp.router` currently declares only Turkish and English as supported locales.
2. The Riverpod locale provider includes Dutch and German legacy values, but French is absent.
3. The generated `AppLocalizations` output is stale and currently reports only Turkish support.
4. `app_en.arb` contains a large number of Turkish fallback values, so selecting English can still show Turkish text.
5. Dutch and French ARB resources are not present.
6. Several providers and domain/UI models store Turkish display text directly, preventing reactive locale changes.
7. Static JSON content and suggestion assets are primarily Turkish and are not locale-aware.
8. Dynamic content, caches, notifications and AI prompts do not yet share one locale context.

## Localization contract

### Single source of truth

The active locale must be stored as a language code (`tr`, `nl`, `fr`, `en`) rather than a translated display name. Legacy values such as `Türkçe`, `English`, `Nederlands` and `Français` must be migrated when read.

### Locale-aware system data

System-owned records must use one of these patterns:

- `titleKey` / `descriptionKey` for short UI and catalog strings.
- A `translations` object for articles, guides, suggestions and long-form content.

Example:

```json
{
  "id": "child_sleep_0_3",
  "translations": {
    "tr": {"title": "Uyku rutini", "body": "..."},
    "nl": {"title": "Slaaproutine", "body": "..."},
    "fr": {"title": "Routine de sommeil", "body": "..."},
    "en": {"title": "Sleep routine", "body": "..."}
  }
}
```

### Fallback policy

1. Selected locale
2. English
3. Turkish template only during migration
4. Translation key in development builds

A production screen must never silently show an empty string.

### Cache contract

Every locale-dependent cache key must include locale and jurisdiction where relevant:

```text
content:<country>:<region>:<locale>:<category>
suggestions:<familyId>:<locale>:<date>
ai:<country>:<region>:<locale>:<intent>
```

Changing language must invalidate or reload locale-dependent providers without deleting locale-independent family data.

## Delivery phases

### Phase 1 — Foundation and audit

- Add automated ARB audit tooling.
- Establish TR/NL/FR/EN as the only initial target locales.
- Replace display-name persistence with language codes.
- Regenerate Flutter localization output.
- Add placeholder and key-parity validation.

### Phase 2 — Core UI

Localize:

- Authentication
- Main navigation
- Hub
- Settings
- Dialogs, snackbars and validation errors
- Empty, loading and failure states
- Accessibility labels

### Phase 3 — Feature modules

Localize all system text in:

- Shopping
- Kitchen
- Child
- Development
- Health
- Location
- Emergency
- Budget
- Home expenses
- Gallery
- Education
- Calendar
- Tasks
- Family profiles
- Family Intelligence
- FamilyHub AI
- Advantages and legal rights

### Phase 4 — Static content and suggestions

Convert all assets under `assets/data/` to locale-aware canonical records. This includes recipes, education content, family activities, household content and every suggestion pool.

Each canonical content item must have translation coverage for all four locales before being marked `published`.

### Phase 5 — Dynamic and remote content

- Send `locale`, `countryCode` and `regionCode` with remote requests.
- Separate caches by locale.
- Reload data providers after language changes.
- Localize notifications and scheduled reminders.
- Store source language and translation status for internet-derived content.

### Phase 6 — FamilyHub AI

Every AI request must include:

- Active locale
- Language name
- Country and region
- User role
- Relevant family context with data minimization

AI responses, suggested prompts, action cards and cited summaries must be returned in the selected language. Sources may remain in their original language, but source titles and explanations should be localized where safe.

### Phase 7 — CI enforcement

The localization audit must run in CI. A pull request fails when it introduces:

- Missing locale files
- Missing required keys
- Empty translations
- Placeholder mismatches
- Invalid ARB JSON

Turkish leakage and unchanged template values should initially be warnings and become blocking after migration is complete.

## Translation quality rules

- Translate meaning and product intent, not isolated words.
- Preserve official institution and program names; provide a localized explanation when needed.
- Never translate IDs, route names, analytics events, database columns or API fields.
- Use ICU plural/select syntax for counts and gender/role-sensitive text.
- Do not concatenate sentences from fragments.
- Keep placeholders identical across locales.
- Use Belgian Dutch and Belgian French terminology for Belgium-specific content.
- Health, legal and financial content requires terminology review and source validation.

## Definition of done

Localization is complete only when:

- Switching language updates the visible screen without restarting the app.
- Navigation, dialogs, forms and notifications change language.
- Static content, recommendations and activities change language.
- Dynamic content is reloaded using the selected locale.
- FamilyHub AI replies in the selected language.
- ARB key parity is 100% across TR/NL/FR/EN.
- Turkish leakage in NL/FR/EN is zero except approved names and terms.
- Placeholder and pluralization tests pass.
- The selected locale survives application restart.
