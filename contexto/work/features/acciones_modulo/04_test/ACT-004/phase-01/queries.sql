-- ACT-004 phase-01 manual verification helpers (read-only)

-- 1) Duplicates guard inspection (should be unique per pair)
SELECT
    ri.DeviceId,
    ri.RuleTemplateVersionId,
    COUNT(*) AS Cnt
FROM dbo.RuleInstance AS ri
WHERE ri.IsDeleted = 0
GROUP BY ri.DeviceId, ri.RuleTemplateVersionId
HAVING COUNT(*) > 1;

-- 2) Inspect assignments for a specific template version
-- Replace @RuleTemplateVersionId with real id.
DECLARE @RuleTemplateVersionId INT = 0;
SELECT
    ri.RuleInstanceId,
    ri.DeviceId,
    ri.RuleTemplateVersionId,
    ri.IsActive,
    ri.IsDeleted,
    ri.CreatedAt,
    ri.CreatedBy
FROM dbo.RuleInstance AS ri
WHERE ri.RuleTemplateVersionId = @RuleTemplateVersionId
ORDER BY ri.CreatedAt DESC;
