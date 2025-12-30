@echo off
echo Executing database migration...
echo.

cd /d "%~dp0"

echo Connecting to Cloud SQL...
type migrate-to-fincore-db.sql | gcloud sql connect fincore-npe-db --user=root --database=mysql --project=project-07a61357-b791-4255-a9e

echo.
echo Migration complete!
pause
