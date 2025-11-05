-- Create study_sessions table
CREATE TABLE IF NOT EXISTS study_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    subject_id UUID REFERENCES subjects(id) ON DELETE SET NULL,
    subject VARCHAR(255) NOT NULL, -- Denormalized for queries and when subject is deleted
    topics TEXT,
    scheduled_for TIMESTAMP WITH TIME ZONE NOT NULL,
    duration BIGINT NOT NULL, -- in seconds
    is_completed BOOLEAN DEFAULT FALSE,
    completed_at TIMESTAMP WITH TIME ZONE,
    quality_rating INTEGER CHECK (quality_rating BETWEEN 1 AND 5),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes
CREATE INDEX idx_study_sessions_user_id ON study_sessions(user_id);
CREATE INDEX idx_study_sessions_subject_id ON study_sessions(subject_id);
CREATE INDEX idx_study_sessions_scheduled_for ON study_sessions(scheduled_for);
CREATE INDEX idx_study_sessions_is_completed ON study_sessions(is_completed);
CREATE INDEX idx_study_sessions_completed_at ON study_sessions(completed_at);
CREATE INDEX idx_study_sessions_user_scheduled ON study_sessions(user_id, scheduled_for);
CREATE INDEX idx_study_sessions_user_completed ON study_sessions(user_id, completed_at) WHERE is_completed = TRUE;

-- Create trigger for updated_at
CREATE TRIGGER update_study_sessions_updated_at
    BEFORE UPDATE ON study_sessions
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Add check constraint for completion logic
ALTER TABLE study_sessions ADD CONSTRAINT check_completion_logic
    CHECK (
        (is_completed = FALSE AND completed_at IS NULL) OR
        (is_completed = TRUE AND completed_at IS NOT NULL)
    );

-- Add constraint to ensure duration is reasonable
ALTER TABLE study_sessions ADD CONSTRAINT check_duration_positive
    CHECK (duration > 0 AND duration <= 86400); -- Max 24 hours

-- Add RLS policies
ALTER TABLE study_sessions ENABLE ROW LEVEL SECURITY;

-- Users can only view their own sessions
CREATE POLICY "Users can view own study sessions" ON study_sessions
    FOR SELECT USING (user_id = current_setting('app.current_user_id')::uuid);

-- Users can insert their own sessions
CREATE POLICY "Users can insert own study sessions" ON study_sessions
    FOR INSERT WITH CHECK (user_id = current_setting('app.current_user_id')::uuid);

-- Users can update their own sessions
CREATE POLICY "Users can update own study sessions" ON study_sessions
    FOR UPDATE USING (user_id = current_setting('app.current_user_id')::uuid);

-- Users can delete their own sessions
CREATE POLICY "Users can delete own study sessions" ON study_sessions
    FOR DELETE USING (user_id = current_setting('app.current_user_id')::uuid);