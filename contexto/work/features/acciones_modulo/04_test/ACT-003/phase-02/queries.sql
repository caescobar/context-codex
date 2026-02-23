USE TelemetricDb;
GO

DECLARE @RuleTemplateId INT = $(RuleTemplateId);

SELECT
    rtv.RuleTemplateId,
    COUNT(*) AS VersionsCount,
    MIN(rtv.VersionNumber) AS MinVersion,
    MAX(rtv.VersionNumber) AS MaxVersion
FROM dbo.RuleTemplateVersion rtv
WHERE rtv.RuleTemplateId = @RuleTemplateId
  AND rtv.IsDeleted = 0
GROUP BY rtv.RuleTemplateId;
GO

SELECT
    rtv.RuleTemplateId,
    rtv.VersionNumber,
    COUNT(*) AS VersionRows
FROM dbo.RuleTemplateVersion rtv
WHERE rtv.RuleTemplateId = @RuleTemplateId
GROUP BY rtv.RuleTemplateId, rtv.VersionNumber
HAVING COUNT(*) > 1;
GO

SELECT TOP 20
    rtv.RuleTemplateVersionId,
    rtv.RuleTemplateId,
    rtv.VersionNumber,
    rtv.IsActive,
    rtv.IsDeleted,
    rtv.CreatedAt
FROM dbo.RuleTemplateVersion rtv
WHERE rtv.RuleTemplateId = @RuleTemplateId
ORDER BY rtv.VersionNumber DESC;
GO
