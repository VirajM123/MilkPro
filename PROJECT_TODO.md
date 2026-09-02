# Milk Distribution App - Project TODO

Audit date: 2026-09-02

## Current assessment

The project is a strong UI prototype with broad screen coverage, responsive widget tests, PDF/Excel export support, and an initial role/permission model. It is not production-ready yet: authentication, persistence, APIs, reporting data, and most cross-module workflows are still local demo implementations.

Work through the sections in priority order. P0 items are release blockers.

## P0 - Production blockers

- [ ] Implement real authentication and session management.
  - Locations: `lib/screens/auth/login_screen.dart`, `lib/screens/auth/registration_screen.dart`, `lib/providers/auth_provider.dart`, `lib/services/auth_service.dart`, `lib/services/storage_service.dart`.
  - The login currently accepts any validated identifier/password, waits 700 ms, and signs in as the selected role. Registration only displays a message. `auth_service.dart` and `storage_service.dart` are empty.
  - Add a backend login/registration flow, secure token storage, refresh/revocation, logout invalidation, session restoration, inactive-user handling, and explicit loading/error states.
  - Never decide authorization from a client-selected role. Obtain roles and permissions from the authenticated backend identity.

- [ ] Enforce authorization on the backend and consistently in the UI.
  - Locations: `lib/main.dart`, `lib/services/app_navigation.dart`, `lib/config/app_features.dart`, all feature screens.
  - Route guards are client-only, and many screens can be opened with direct `MaterialPageRoute` calls. Only `CustomerRatesScreen` also performs its own screen-level check.
  - Centralize navigation, add guards to every protected screen/action, and make the backend validate permissions for every read/write/export request.
  - Add explicit create/edit/delete permissions for modules that currently have only a view permission.

- [ ] Replace in-memory/demo data with a real data layer.
  - Locations: `lib/providers/customer_provider.dart`, `product_provider.dart`, `sales_provider.dart`, `salesman_ui_store.dart`, `customer_rate_provider.dart`, `report_demo_provider.dart`, and local lists inside `lib/screens/**`.
  - Data currently disappears on restart and is duplicated between screens. Dashboard metrics and report rows are mostly hard-coded and can disagree with sales, allocation, collection, stock, or payment state.
  - Implement repositories over a documented API/database, DTO-to-domain mapping, pagination, caching, retries, offline behavior (if required), and observable loading/error/empty states.
  - Decide whether the backend or device is the source of truth and document sync/conflict rules.

- [ ] Model and persist complete business transactions atomically.
  - Locations: `lib/screens/purchase/purchase_screen.dart`, `sales/sales_screen.dart`, `allocation/allocation_screen.dart`, `returns/return_settlement_screen.dart`, `collection/collection_screen.dart`, `payments/payments_screen.dart`, `expenses/expenses_screen.dart`, `ledger/ledger_screen.dart`.
  - Purchase, allocation, sales, returns, collection, payments, expenses, and ledger entries currently use separate local structures. A failure can leave stock, balances, allocation quantities, and ledger totals inconsistent once persistence is introduced.
  - Define transaction boundaries and backend rules for stock movements, sale line items, invoices, returns, settlement, payments, customer balance, supplier balance, and audit entries.
  - Make repeated submissions idempotent and prevent double-selling or returning more than the available/allotted quantity.

- [ ] Replace dynamic allocation/return maps with typed domain models.
  - Locations: `lib/screens/allocation/allocation_screen.dart`, `lib/screens/returns/return_settlement_screen.dart`, `lib/screens/sales/sales_screen.dart`, empty `lib/models/allocation_model.dart`.
  - Shared mutable `Map<String, dynamic>` records rely on string keys and runtime casts across three large screens.
  - Create immutable typed models for allocation batch, allocation line, sale/invoice, return line, and settlement, including IDs, timestamps, units, status enums, and serialization.

- [ ] Use safe numeric types and centralized business calculations.
  - Locations: all models/screens that store money as `double`; especially `sale_model.dart`, `product_model.dart`, purchase, rates, billing, collection, payments, ledger, reports, and returns.
  - Store money as integer minor units (paise) or a decimal type. Define quantity precision per unit rather than mixing `int`, `double`, and `num`.
  - Move subtotal, tax, discount, outstanding, settlement, and stock calculations out of widgets; define rounding rules and test boundary cases.

- [ ] Configure real release identities and signing before distribution.
  - Locations: `android/app/build.gradle.kts`, `android/app/src/main/AndroidManifest.xml`, `ios/Runner.xcodeproj/project.pbxproj`, `macos/Runner/Configs/AppInfo.xcconfig`, `windows/runner/Runner.rc`, `web/manifest.json`, `web/index.html`.
  - Android still uses `com.example.milk_distribution_app` and debug signing. Desktop/web metadata is template content. Android's main manifest has no internet permission for a future production API.
  - Set final package/bundle IDs, app names, icons, company/copyright data, release signing, environment-specific endpoints, and store metadata. Add only the platform permissions actually required.

- [ ] Add environment and secret management.
  - Locations: empty `lib/config/api_config.dart`, empty `lib/services/api_service.dart`, build/release configuration.
  - Separate development, staging, and production endpoints. Keep secrets out of Dart assets/source; inject public configuration at build time and keep privileged credentials server-side.
  - Add request timeouts, TLS-only production traffic, structured API errors, token redaction, and certificate/network policy as appropriate.

## P1 - Architecture and correctness

- [ ] Break up oversized screen files by feature and responsibility.
  - Highest-priority files: `sales_screen.dart` (~3,265 lines), `purchase_screen.dart` (~3,170), `allocation_screen.dart` (~2,770), `return_settlement_screen.dart` (~1,691), `routes_screen.dart` (~1,192), and `dashboard_screen.dart` (~1,016).
  - Extract page sections/widgets, controllers/view-models, validators, formatters, and business services. Aim for small files with one clear reason to change.
  - Remove `LegacyAssignAllocationPage` from `allocation_screen.dart` after confirming the replacement is complete.

- [ ] Choose one predictable application state-management pattern.
  - Locations: `lib/providers/**`, `lib/screens/**`, `pubspec.yaml`.
  - The files named providers are mostly static mutable stores rather than an injected state-management layer. Screens directly mutate global lists/maps and local state.
  - Add dependency injection and repository interfaces so screens can be tested with fakes and data updates notify all consumers consistently.

- [ ] Complete or remove the 18 empty placeholder Dart files.
  - Locations: `lib/app.dart`; `lib/config/api_config.dart`, `app_routes.dart`; `lib/models/{allocation,collection,ledger,route,salesman,user}_model.dart`; `lib/providers/{allocation,collection,dashboard,route,salesman,settings}_provider.dart`; `lib/services/{api,auth,storage}_service.dart`.
  - Empty files imply architecture that is not actually present and make project navigation misleading. Implement them as part of the data-layer work or delete them once references/plans are reconciled.

- [ ] Consolidate routing and remove direct screen-to-screen dependencies.
  - Locations: `lib/main.dart`, `lib/services/app_navigation.dart`, dashboard, collection, customers, sales, salesmen, settings, and profile screens.
  - Use one route table/router with typed arguments, authentication redirects, permission redirects, and a not-found page. The current unknown-route fallback silently opens the dashboard and can hide broken links.
  - Avoid screens importing unrelated screens solely to construct routes.

- [ ] Redesign invoices as headers with multiple line items.
  - Locations: `lib/models/sale_model.dart`, `lib/screens/sales/sales_screen.dart`, `lib/services/bill_pdf_service.dart`.
  - `SaleModel` represents one product, while the sale UI supports a cart. Saving multiple products as separate sales makes invoice identity, totals, payment, printing, returns, and ledger posting ambiguous.
  - Add `Invoice`/`Sale` and `SaleLine` models; generate one stable backend ID per invoice; render all lines on the bill.

- [ ] Replace display names and timestamps used as record identity with stable IDs.
  - Locations: customer/product/rate stores, allocation batch generation, purchase/sale creation, bill customer lookup.
  - Customer rates and bill phone lookup depend on normalized names; allocation batches use local timestamps. Names can change/collide and client clocks are not authoritative.
  - Use backend-generated UUID/sequence IDs and foreign keys. Preserve a human-readable document number separately.

- [ ] Add full validation and invariants to every form.
  - Locations: registration, customers, products, customer rates, allocation, sales, purchase, returns, collection, payments, expenses, routes, and salesman management.
  - Validate normalized phone numbers, required IDs, unique records, positive/allowed precision, price/rate bounds, stock/allocation availability, date ranges, tax/discount limits, and payment totals.
  - Disable repeated submission while saving and surface field-level server validation errors.

- [ ] Centralize date, time, number, currency, and unit formatting.
  - Locations: repeated helpers throughout screens plus `excel_service.dart`, `report_pdf_service.dart`, and `bill_pdf_service.dart`.
  - The UI mixes `₹` and `Rs.`, manual Indian-number grouping, multiple date formats, hard-coded month names, and `Pcs`/`Ltr` text.
  - Use locale-aware formatters, a single clock/time-zone policy, and domain units. Keep raw numeric/date values in report data until export formatting.

- [ ] Make reporting use live, filterable domain data.
  - Locations: `lib/providers/report_demo_provider.dart`, `lib/screens/reports/**`.
  - The 752-line report provider contains fixed August/September 2026 rows and already-formatted metric strings. Date filters cannot reliably filter strings or reconcile reports with operational data.
  - Generate reports server-side or from repositories, define column types, apply real date/route/customer/salesman filters, and handle large exports asynchronously.

- [ ] Add audit history and record lifecycle rules.
  - Track creator/updater, UTC timestamps, device/session, status transitions, approvals, reversals, and reasons for sensitive changes.
  - Prefer reversals/voids over destructive edits for sales, collections, payments, returns, and ledger-affecting records.

- [ ] Define failure, offline, and concurrency behavior.
  - Add retry/cancel flows, optimistic-lock/version conflicts, connectivity state, queued-write rules, and duplicate prevention.
  - Do not silently swallow errors; `bill_pdf_service.dart` currently ignores logo-loading failures, and most local mutations cannot fail or roll back.

## P1 - Testing and delivery safety

- [ ] Make tests isolated and deterministic.
  - Locations: `test/**`, static stores under `lib/providers/**`, `ReturnAllocationStore`.
  - Several widget tests mutate global customers/products/sales/permissions without resetting all stores. Test results can depend on execution order.
  - Inject fresh repositories/stores per test, use fixed clocks/ID generators, and reset all global state in teardown until globals are removed.

- [ ] Add domain unit tests.
  - Cover money rounding, quantity/unit conversions, stock movement, allocation availability, multi-line invoices, returns, settlement differences, customer/supplier balances, rate precedence, permissions, and report filters.

- [ ] Add repository/API contract tests and failure-path widget tests.
  - Cover unauthorized/forbidden, validation errors, timeouts, offline/retry, empty data, pagination, token expiry, duplicate submission, and malformed responses.

- [ ] Add integration tests for critical workflows.
  - Admin login -> purchase -> allocation -> sale -> return/settlement -> collection/payment -> ledger/report.
  - Salesman login -> permitted route/customers only -> sale/collection -> denied admin modules.
  - Include compact phone, tablet/desktop, web (if supported), keyboard navigation, and process restart/session restoration.

- [ ] Add CI quality gates.
  - Run formatting check, `flutter analyze`, unit/widget/integration tests, coverage reporting, dependency/security checks, and release builds for supported platforms.
  - Fail CI for analyzer warnings, failing tests, accidental generated artifacts, or missing production signing/configuration.

## P2 - UX, accessibility, and maintainability

- [ ] Perform a full accessibility pass.
  - Locations: all screens and `lib/widgets/app_widgets.dart`.
  - Only a couple of explicit `Semantics`/`Tooltip` usages were found across the UI.
  - Add semantic labels/hints for icon-only controls and charts/cards, logical focus order, keyboard shortcuts/navigation, minimum touch targets, screen-reader announcements for validation/status, and contrast checks.
  - Test text scaling at 200%, high contrast, narrow screens, landscape, and reduced motion.

- [ ] Add localization and consistent product terminology.
  - Move all user-facing strings out of widgets and support the required locales (likely English plus relevant regional language(s)).
  - Remove hard-coded company, branch, state, currency, phone prefix, and country assumptions from PDFs and UI.

- [ ] Optimize image assets and startup/memory usage.
  - Location: `assets/img/` (42 files, about 34.7 MiB total; many individual PNGs are 1-2 MiB).
  - Resize to actual display dimensions, compress/convert suitable artwork, remove unused duplicates, and provide resolution-aware variants.
  - Add asset-size budgets to CI and verify quality on target displays.

- [ ] Consolidate design tokens and shared UI components.
  - Locations: `lib/theme/app_colors.dart`, re-exporting `lib/config/app_colors.dart`, `lib/config/app_theme.dart`, repeated card/header/navigation code in screens.
  - Keep one canonical theme/token location; move repeated spacing, typography, input, status, responsive breakpoint, and navigation patterns into reusable components.

- [ ] Improve loading, empty, error, and unsaved-change experiences.
  - Add skeleton/retry states backed by real async data, confirmation for abandoning dirty forms, undo where safe, and clear success messages tied to committed server results.
  - Preserve filters/drafts across navigation where business users expect it.

- [ ] Add structured logging and crash/diagnostic reporting with privacy controls.
  - Log request/operation IDs and non-sensitive failure context. Redact passwords, tokens, phone numbers, customer data, invoice details, and financial values as required.
  - Define retention, consent, and access policies before enabling production telemetry.

- [ ] Review privacy, security, backup, and compliance requirements.
  - Document what personal/financial data is collected, why it is needed, retention/deletion, export, backups/restores, encryption, account deletion, and access reviews.
  - Threat-model authentication, IDOR/broken access control, data export, insecure local storage, rooted devices, replay/double-submit, and lost devices.

## P2 - Project hygiene

- [ ] Replace the template `README.md` with project documentation.
  - Include purpose, supported platforms, Flutter/Dart versions, setup, environment configuration, architecture, commands, test strategy, release process, demo credentials (development only), and troubleshooting.

- [ ] Confirm source control is configured and create a clean baseline.
  - This audit directory did not expose a usable Git repository (`git status` reported that it is not a repository).
  - Initialize/restore the intended repository, use protected branches/reviews, and commit `pubspec.lock` for this application.

- [ ] Ignore/remove generated sample output from the source tree unless it is an intentional test fixture.
  - Locations: `output/pdf/sample_sales_bill.pdf`, `outputs/report-preview/current_stock_report.xlsx`.
  - Add narrowly scoped ignore rules for runtime exports; keep intentional golden fixtures under `test/fixtures/` with documentation.

- [ ] Strengthen static-analysis rules and remove dead/duplicate code.
  - Extend `analysis_options.yaml` with agreed strict lints, unawaited-future checks, and stricter type inference/casts.
  - Remove empty aliases/placeholders and legacy widgets only after confirming they have no intended consumers.

- [ ] Review dependency versions, licenses, and platform support before each release.
  - Locations: `pubspec.yaml`, `pubspec.lock`.
  - Document why each dependency is used, verify web/desktop/mobile behavior for exporting/printing/URL launch, and automate safe update checks.

## Suggested implementation sequence

1. Write domain rules and API contracts; choose backend, database, environment strategy, and supported platforms.
2. Introduce typed domain models, repositories, dependency injection, money/unit/date utilities, and isolated tests.
3. Implement backend authentication, server-side authorization, secure session storage, and centralized guarded routing.
4. Implement master data (products, customers, routes, salesmen, custom rates) and then transactional flows in business order.
5. Replace dashboard/report demo data with repository-backed aggregates and exports.
6. Split the oversized screens while connecting them to the new state layer.
7. Complete accessibility/localization, platform branding/signing, privacy/security review, CI, integration tests, and release hardening.

## Audit verification note

- Reviewed the Dart source inventory under `lib/`, all tests under `test/`, dependency/lint configuration, assets, and Android/iOS/web/macOS/Windows release metadata.
- No existing application source or configuration file was edited by this audit.
- `flutter analyze` and `flutter test` were attempted, but the Flutter CLI produced no output and did not complete after extended waits in this environment. Run both commands locally/CI before treating the current baseline as green.
