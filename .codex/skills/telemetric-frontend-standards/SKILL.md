---
name: telemetric-frontend-standards
description: Estandar canonico de desarrollo frontend Telemetric (Vue 3) para implementar/refactorizar features con paridad visual y tecnica respecto a `features/admin/devices`. Incluye rutas/permisos/menu, servicios tipados, contratos list/paged, estados UX (loading/empty/error), encoding y gates de no-regresion de typecheck.
---

# Telemetric Frontend Standards (Vue 3) — Canon

## Purpose
Enforce the Telemetric frontend coding + UX standard for new features and refactors, using the current project canon as baseline:
- Vue 3 + Composition API
- Feature-first structure under `src/features/*`
- Route permissions (`requiresAuth`, `requiresPermission`) aligned with backend claims
- Menu parity (sidebar visibility permission-driven)
- Typed services and stable contracts (`ListResponse` / `PagedList`)
- Reusable UI primitives (`UiDynamicFilter`, `UiCard`, `UiServerTable`, notifications)
- Consistent admin list/detail UX (parity with `admin/devices`)
- Encoding hygiene (UTF-8, no mojibake)
- Typecheck no-regression gate (project-wide baseline must not increase)

Reference canon (must inspect before coding):
- `telemetric-front/src/features/admin/devices/views/DeviceListView.vue`
- `telemetric-front/src/features/admin/devices/device.routes.ts`
- `telemetric-front/src/layouts/menuItems.ts`
- `telemetric-front/src/layouts/Sidebar.vue`

If module is Actions, also review:
- `telemetric-front/src/features/actions/actions.routes.ts` (if exists)

---

## Scope
Applies to:
- New frontend feature modules
- New list/detail views
- Routes and menu integration
- Feature services and types
- UX consistency and encoding hygiene
- Targeted refactors inside the touched feature or shared primitives required by the story

Non-goals:
- Do not redesign the design system.
- Do not introduce new UI frameworks or new table/filter systems.
- Do not perform broad refactors outside the requested scope/story.

---

## Mandatory Project Structure (Feature-first)
Feature folder layout (canonical):
- `telemetric-front/src/features/<module>/`
  - `<module>.routes.ts`
  - `<module>.service.ts`
  - `types.ts`
  - `views/*.vue`
  - `components/*` (only if reused within the feature)

When the story affects navigation:
- Register route in the router aggregation file used by the project (discover actual file; do not invent).
- Register menu item in `telemetric-front/src/layouts/menuItems.ts` with permission gate.

---

## Route + Permission Standard (MANDATORY)
Every feature route must:
1) Set `meta.requiresAuth: true` unless explicitly public.
2) Set `meta.requiresPermission: '<Module>.<Action>'` aligned with backend claims naming.
3) Use lazy-loaded components (`() => import(...)`).
4) Keep route names and paths stable and explicit.

Do NOT:
- Create routes without permission checks.
- Hardcode bypasses in router guards.
- Use ad-hoc permission strings without verifying claim existence.

Discovery requirement:
- Before implementing a new permission, search backend constants/claims to confirm it exists.
- If it doesn’t exist, raise `DECISION PENDIENTE` (do not invent).

---

## Menu Parity Standard (MANDATORY)
If the feature is user-facing, menu integration must:
1) Add entry in `telemetric-front/src/layouts/menuItems.ts`.
2) Use the same permission string as the route.
3) Preserve grouping style already used in sidebar.

Sidebar visibility is permission-driven:
- `telemetric-front/src/layouts/Sidebar.vue` filters items by `requiresPermission`.
- If a menu item is missing at runtime, verify user permissions and route meta alignment first.

---

## Frontend UX Parity (MANDATORY)
### List views (general style)
All list pages MUST follow the canonical structure (reference: `admin/devices`):
1) Header: `BaseBreadcrumb` (title + breadcrumbs).
2) Filters: `UiDynamicFilter` (schema-driven) with `@search` and `@reset`.
3) Content: `UiCard` wrapping `UiServerTable`.
4) Slot-based table cell customization for status/actions.
5) Row actions (edit/view/delete) MUST use icon actions with tooltip labels (no text-only action buttons inside table rows).
6) Empty state and error state visible and non-breaking.
7) Edit/create flows SHOULD prefer modal pattern used by canon. If navigation to detail page is used instead, the story/spec must explicitly require it.

### Detail views (general style)
Detail pages should:
1) Use clear header/title hierarchy.
2) Reuse existing card/tab patterns from the module or the closest canon.
3) Avoid isolated styling that diverges from project conventions.
4) Provide stable action placement (top-right or section header) consistent with canonical modules.

---

## Modal Canon (MANDATORY)
All create/edit/detail modals MUST follow a single visual canon across the project.

Primary visual reference (must inspect before coding):
- `telemetric-front/src/features/customer/devices/views/DeviceCustomerModal.vue`

Secondary component reference (actions/footer/loading parity):
- `telemetric-front/src/features/admin/devices/views/DeviceForm.vue`

Required modal structure:
1) Header with strong visual hierarchy (title + close action) and stable spacing.
2) Content grouped into explicit sections (section label + block container), not a flat stack of inputs.
3) Consistent body spacing (`pa-*`, row/col gaps) so controls are never visually cramped.
4) Footer parity:
   - `Cancelar`: text button, neutral gray tone.
   - `Guardar`: primary flat button with save icon (`mdi-content-save`).
5) Modal sizing and behavior aligned with canon:
   - use explicit max-width appropriate to form density;
   - use `persistent`/`scrollable` when the flow requires long editable content.

Do NOT:
- Build ad-hoc modal shells with different spacing, header behavior, or footer actions.
- Mix competing visual patterns for modals in different features.

If a story explicitly demands a different modal visual language:
- raise `DECISION PENDIENTE` and stop before implementation.

---

## UX State Standard (MANDATORY)
Every view that fetches data MUST implement these states:
- `loading`: show loader/skeleton consistent with project
- `error`: show a user-friendly error via the core notification pattern
- `empty`: show a consistent empty message (Spanish UI copy)
- `success`: render data

Do NOT:
- Leave the page blank on error.
- Swallow errors silently.
- Mix English UI copy for user-facing messages.

---

## Service + Types Standard (MANDATORY)
1) Service calls must use the centralized HTTP client used by the project (`@/core/utils/axios` or the active wrapper discovered in repo).
2) No direct `fetch` inside features.
3) No new `any` or `unknown` in feature contracts.
4) Define feature contracts in `types.ts` and export them.
5) Keep technical type names in English; UI copy in Spanish.

Error handling:
- Reuse the core error mapping + notification approach.
- Do not invent ad-hoc error payload shapes in views.

---

## List/Paged Contracts Standard (MANDATORY)
Goal: eliminate drift between services and table hooks.

Rules:
1) Lists in admin modules MUST use the same response contract used by `admin/devices` (discover and reuse).
2) If the project uses `ListResponse<T>` or `PagedList<T>`, do not create a new shape.
3) `UiServerTable` + the table fetch hook must receive a consistent typed shape (`items`, pagination metadata, etc.) as used by canon.
4) When using `useUiServerTable`, the fetch callback MUST return `PagedList<T>` (or `T[]` only if the canon in that module already allows client-side list mode).
5) If backend returns legacy paged payload (`items`, `pageNumber`, `totalPages`, `totalCount`), frontend MUST map it to `PagedList<T>` before binding to `UiServerTable`.
6) Do not bypass this by replacing `UiServerTable` with ad-hoc `v-table`/manual pagination on admin list views.

If the current project has inconsistencies:
- Prefer a minimal adapter in the service layer (map server payload -> canon shape)
- Do NOT change multiple features at once unless the story explicitly requests it.

---

## Table + Filter Standard (MANDATORY)
1) Headers defined explicitly with stable keys (`title`, `key`, `align`) matching canon.
2) Use the server-side table hook/pattern already present (discover exact hook path; do not invent).
3) Filters support search/reset and map cleanly to service params.
4) Date/status rendering uses existing helper/component patterns.

---

## Encoding + Copy Standard (MANDATORY)
1) UI text must render correctly in Spanish (no mojibake).
2) If corrupted sequences are detected, normalize strings and save file as UTF-8.
3) Avoid mixed-language UI labels.
4) Keep route/identifier/code symbols unchanged when fixing copy.

---

## Typecheck Gate (MANDATORY)
No-regression rule:
- The total number of TypeScript errors (excluding `src/_demo/**`) MUST NOT increase.

When a phase touches FE:
- Capture baseline count (before) and after count (after).
- Store evidence (commands + outputs) in the phase QA pack.

---

## Definition of Done (MANDATORY)
A change is DONE only if:
1) Route access works with permission gate (auth + permission).
2) Menu visibility matches the same permission.
3) View renders with correct UX states (loading/error/empty/success).
4) No mojibake / encoding issues in touched files.
5) Typecheck no-demo does not regress (count does not increase).
6) Services + contracts are typed (no new `any/unknown`).
7) Every touched modal complies with Modal Canon (header/body sections/footer parity).

---

## Implementation Protocol (MANDATORY)
Before coding:
1) Identify 2 analogous frontend files (route/service + view) from canon.
2) Confirm permission claim exists in backend.
3) Confirm menu + route alignment rules.

During coding:
1) Keep changes minimal and scoped.
2) Reuse existing project primitives.
3) Avoid broad refactors unless required.

After coding:
1) Verify route access + menu parity.
2) Verify UI text encoding.
3) Run frontend validation command used by project (typecheck at minimum).
4) Capture evidence in QA pack if the story requires it.

---

## Hard Rules
1) Do not invent a new visual language when an existing one fits.
2) Do not ship a feature route without permission and menu parity.
3) Do not close work with visible encoding issues.
4) Do not bypass admin/devices parity without explicit approval.
5) Do not worsen the project typecheck baseline (no-demo scope).
6) All list views MUST use `BaseBreadcrumb` + `UiDynamicFilter` + `UiCard` + `UiServerTable` unless a documented exception is approved.
7) Any view using `UiServerTable` MUST satisfy the typed paged contract expected by `useUiServerTable` (`PagedList` compatible shape).
8) Table row actions MUST be icon-based with tooltip label; text-only action buttons in row actions are not allowed.
9) Edit/create interactions SHOULD use modal by default. If not modal, the reason and UX decision must be explicit in story/spec.
