USE TelemetricDb;
GO
SET NOCOUNT ON;
GO

DECLARE @DeviceId INT;
DECLARE @ClientId INT;
DECLARE @RuleTemplateId INT;
DECLARE @RuleTemplateVersionId INT;
DECLARE @RuleInstanceId INT;
DECLARE @PermissionId INT;

SELECT TOP 1
    @DeviceId = d.DeviceId,
    @ClientId = d.ClientId
FROM dbo.Device d
WHERE d.IsDeleted = 0
ORDER BY d.DeviceId DESC;

IF @DeviceId IS NULL
BEGIN
    RAISERROR('Seed abortado: no existe ningun Device activo (IsDeleted=0).', 16, 1);
    RETURN;
END

IF @ClientId IS NULL
BEGIN
    RAISERROR('Seed abortado: Device seleccionado no tiene ClientId.', 16, 1);
    RETURN;
END

PRINT 'Usando DeviceId=' + CAST(@DeviceId AS VARCHAR(20)) + ', ClientId=' + CAST(@ClientId AS VARCHAR(20));

SELECT @PermissionId = p.PermissionId
FROM dbo.Permission p
WHERE p.Code = 'Actions.ResolveManual' AND p.IsDeleted = 0;

IF @PermissionId IS NULL
BEGIN
    INSERT INTO dbo.Permission
    (
        Code, Module, Description, IsActive, IsDeleted, CreatedAt, CreatedBy, Scope
    )
    VALUES
    (
        'Actions.ResolveManual',
        'Actions',
        N'Allows manual resolve of latch rule instances.',
        1,
        0,
        GETUTCDATE(),
        NULL,
        0
    );

    SET @PermissionId = SCOPE_IDENTITY();
    PRINT 'Permission creada: Actions.ResolveManual (PermissionId=' + CAST(@PermissionId AS VARCHAR(20)) + ')';
END
ELSE
BEGIN
    PRINT 'Permission existente: Actions.ResolveManual (PermissionId=' + CAST(@PermissionId AS VARCHAR(20)) + ')';
END

IF NOT EXISTS
(
    SELECT 1
    FROM dbo.RolePermission rp
    WHERE rp.RoleId = 1
      AND rp.PermissionId = @PermissionId
)
BEGIN
    INSERT INTO dbo.RolePermission (RoleId, PermissionId)
    VALUES (1, @PermissionId);

    PRINT 'RolePermission agregado: RoleId=1 -> Actions.ResolveManual';
END
ELSE
BEGIN
    PRINT 'RolePermission ya existia: RoleId=1 -> Actions.ResolveManual';
END

SELECT @RuleTemplateId = rt.RuleTemplateId
FROM dbo.RuleTemplate rt
WHERE rt.ClientId = @ClientId
  AND rt.Name = 'SMOKE_ACT002_TEMPLATE'
  AND rt.IsDeleted = 0;

IF @RuleTemplateId IS NULL
BEGIN
    INSERT INTO dbo.RuleTemplate
    (
        ClientId, Name, Description, IsActive, IsDeleted, CreatedAt, CreatedBy
    )
    VALUES
    (
        @ClientId,
        'SMOKE_ACT002_TEMPLATE',
        N'Seed para smoke test de ACT-002 phase-03.',
        1,
        0,
        GETUTCDATE(),
        NULL
    );

    SET @RuleTemplateId = SCOPE_IDENTITY();
    PRINT 'RuleTemplate creado: ' + CAST(@RuleTemplateId AS VARCHAR(20));
END
ELSE
BEGIN
    PRINT 'RuleTemplate existente: ' + CAST(@RuleTemplateId AS VARCHAR(20));
END

SELECT @RuleTemplateVersionId = rtv.RuleTemplateVersionId
FROM dbo.RuleTemplateVersion rtv
WHERE rtv.RuleTemplateId = @RuleTemplateId
  AND rtv.VersionNumber = 1
  AND rtv.IsDeleted = 0;

IF @RuleTemplateVersionId IS NULL
BEGIN
    INSERT INTO dbo.RuleTemplateVersion
    (
        RuleTemplateId, VersionNumber, DefinitionJson, IsActive, IsDeleted, CreatedAt, CreatedBy
    )
    VALUES
    (
        @RuleTemplateId,
        1,
        N'{"name":"SMOKE_ACT002_TEMPLATE","type":"instant_threshold","metricCode":"tmp","operator":">","threshold":30}',
        1,
        0,
        GETUTCDATE(),
        NULL
    );

    SET @RuleTemplateVersionId = SCOPE_IDENTITY();
    PRINT 'RuleTemplateVersion creada: ' + CAST(@RuleTemplateVersionId AS VARCHAR(20));
END
ELSE
BEGIN
    PRINT 'RuleTemplateVersion existente: ' + CAST(@RuleTemplateVersionId AS VARCHAR(20));
END

SELECT @RuleInstanceId = ri.RuleInstanceId
FROM dbo.RuleInstance ri
WHERE ri.DeviceId = @DeviceId
  AND ri.RuleTemplateVersionId = @RuleTemplateVersionId;

IF @RuleInstanceId IS NULL
BEGIN
    INSERT INTO dbo.RuleInstance
    (
        DeviceId, RuleTemplateVersionId, IsPaused, IsLatchMode, CooldownSeconds, OverridesJson,
        IsActive, IsDeleted, CreatedAt, CreatedBy
    )
    VALUES
    (
        @DeviceId, @RuleTemplateVersionId, 0, 1, 30, NULL,
        1, 0, GETUTCDATE(), NULL
    );

    SET @RuleInstanceId = SCOPE_IDENTITY();
    PRINT 'RuleInstance creada: ' + CAST(@RuleInstanceId AS VARCHAR(20));
END
ELSE
BEGIN
    UPDATE dbo.RuleInstance
    SET IsPaused = 0,
        IsLatchMode = 1,
        CooldownSeconds = 30,
        IsActive = 1,
        IsDeleted = 0,
        UpdatedAt = GETUTCDATE(),
        UpdatedBy = NULL
    WHERE RuleInstanceId = @RuleInstanceId;

    PRINT 'RuleInstance existente actualizada a latch: ' + CAST(@RuleInstanceId AS VARCHAR(20));
END

SELECT
    @DeviceId AS DeviceId,
    @ClientId AS ClientId,
    @PermissionId AS PermissionId_ActionsResolveManual,
    @RuleTemplateId AS RuleTemplateId,
    @RuleTemplateVersionId AS RuleTemplateVersionId,
    @RuleInstanceId AS RuleInstanceId_ReadyForSmoke;
GO
