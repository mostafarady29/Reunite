import { query } from '../core/database/pool.js';

export async function runMigration() {
  console.log('Running notifications and device tokens migration...');
  
  await query(`
    CREATE TABLE IF NOT EXISTS "user_device_token" (
      "id" SERIAL PRIMARY KEY,
      "user_id" INT REFERENCES "User"("user_id") ON DELETE CASCADE,
      "token" TEXT NOT NULL UNIQUE,
      "platform" VARCHAR(50) DEFAULT 'android',
      "created_at" TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
      "updated_at" TIMESTAMP WITH TIME ZONE DEFAULT NOW()
    );
  `);

  await query(`
    CREATE INDEX IF NOT EXISTS "idx_user_device_token_user" ON "user_device_token"("user_id");
  `);

  await query(`
    CREATE TABLE IF NOT EXISTS "notification" (
      "notification_id" SERIAL PRIMARY KEY,
      "user_id" INT REFERENCES "User"("user_id") ON DELETE CASCADE,
      "type" VARCHAR(50) NOT NULL,
      "title" VARCHAR(255) NOT NULL,
      "body" TEXT NOT NULL,
      "case_id" INT REFERENCES "report"("report_id") ON DELETE SET NULL,
      "metadata" JSONB DEFAULT '{}',
      "is_read" BOOLEAN DEFAULT FALSE,
      "created_at" TIMESTAMP WITH TIME ZONE DEFAULT NOW()
    );
  `);

  await query(`
    CREATE INDEX IF NOT EXISTS "idx_notification_user" ON "notification"("user_id");
  `);

  console.log('Migration completed successfully.');
}

if (process.argv[1]?.endsWith('migrate_notifications.ts') || process.argv[1]?.endsWith('migrate_notifications.js')) {
  runMigration()
    .then(() => process.exit(0))
    .catch((err) => {
      console.error('Migration failed:', err);
      process.exit(1);
    });
}
