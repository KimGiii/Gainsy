ALTER TABLE progress_photos
    ADD COLUMN upload_completed_at TIMESTAMPTZ;

CREATE INDEX idx_progress_photos_upload_completed
    ON progress_photos (user_id, upload_completed_at DESC)
    WHERE upload_completed_at IS NOT NULL AND deleted_at IS NULL;
