# telemetric-sqlserver-standards

## Purpose
Enforce **Telemetric SQL Server conventions** for new tables/columns/constraints, aligned to the existing schema style.

---

## Naming (mandatory)
- Tables: **Singular, PascalCase** (e.g., `Device`, `Metric`, `RuleTemplate`)
- Primary Key: `<TableName>Id` as `INT IDENTITY(1,1)` unless the existing table uses another pattern
- Foreign Keys: `<ReferencedTableName>Id` (e.g., `ClientId`, `DeviceId`)

---

## Audit Columns (mandatory if the existing domain uses them)
When creating new tables, include the common audit fields if they exist broadly in the schema:
- `IsActive` (bit) default 1
- `IsDeleted` (bit) default 0
- `CreatedAt` (datetime) default GETUTCDATE()
- `CreatedBy` (nvarchar / int) consistent with existing schema
- `UpdatedAt` (datetime nullable)
- `UpdatedBy` (nvarchar / int nullable)

Do NOT invent different audit fields naming.

If the current schema has a specific audit set/type you cannot confirm in repo:
- raise **DECISIÓN PENDIENTE** and STOP.

---

## Constraints & Indexes (mandatory)
- Always declare FK constraints explicitly
- Create unique constraints when spec requires (example: RuleInstance duplicate block)
  - `UNIQUE (DeviceId, RuleTemplateVersionId)` for RuleInstance-like table
- Use bridge tables with composite PK when relationship is many-to-many and schema already does it

---

## Soft Delete (mandatory if used)
If `IsDeleted` exists in the schema broadly:
- Prefer soft delete usage for logical deletes (depends on existing practices)
Do NOT change existing delete behavior unless story demands.

---

## Migration Approach (guardrail)
Do not assume EF migrations vs raw SQL scripts.
- If the repo has a migrations approach, follow it.
- If not inferable, output **DECISIÓN PENDIENTE**:
  - Ask where migration scripts live and naming format.

---

## DECISIÓN PENDIENTE (mandatory when blocked)
### DECISIÓN PENDIENTE: <Title>
- Contexto: 1–2 líneas
- Opción A: ...
- Opción B: ...
- Preguntas mínimas (max 5):
  1) ...

Then STOP.
