-- 3.4 smoke
SELECT count()
FROM TelemetryLog;

-- 5.4 / 5.6 DeviceId=0
SELECT count() AS cnt
FROM TelemetryLog
WHERE DeviceId = 0
  AND Timestamp >= now() - INTERVAL 15 MINUTE;
