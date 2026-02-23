-- QA queries opcionales ACT-004 phase-02 (manual)
-- Requiere: sqlcmd -v DeviceId=<id> RuleTemplateVersionId=<id>

SET NOCOUNT ON;

SELECT TOP 20
    ri.RuleInstanceId,
    ri.DeviceId,
    ri.RuleTemplateVersionId,
    ri.OverridesJson,
    ri.CreatedAt,
    ri.IsDeleted
FROM dbo.RuleInstance ri
WHERE ri.DeviceId = $(DeviceId)
   OR ri.RuleTemplateVersionId = $(RuleTemplateVersionId)
ORDER BY ri.RuleInstanceId DESC;

SELECT TOP 20
    rtv.RuleTemplateVersionId,
    rtv.RuleTemplateId,
    rtv.VersionNumber,
    rtv.CreatedAt,
    rt.Name AS RuleTemplateName
FROM dbo.RuleTemplateVersion rtv
INNER JOIN dbo.RuleTemplate rt ON rt.RuleTemplateId = rtv.RuleTemplateId
ORDER BY rtv.RuleTemplateVersionId DESC;
