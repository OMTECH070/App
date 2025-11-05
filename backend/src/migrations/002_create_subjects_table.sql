-- Create subjects table
CREATE TABLE IF NOT EXISTS subjects (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    color VARCHAR(7) DEFAULT '#007AFF', -- Hex color code
    difficulty INTEGER CHECK (difficulty BETWEEN 1 AND 4) DEFAULT 1,
    priority INTEGER CHECK (priority BETWEEN 1 AND 5) DEFAULT 1,
    is_active BOOLEAN DEFAULT TRUE,
    mastery_level DECIMAL(3,2) DEFAULT 0.00 CHECK (mastery_level BETWEEN 0.00 AND 1.00),
    total_study_time BIGINT DEFAULT 0, -- in seconds
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, name) -- Each user can have unique subject names
);

-- Create indexes
CREATE INDEX idx_subjects_user_id ON subjects(user_id);
CREATE INDEX idx_subjects_is_active ON subjects(is_active);
CREATE INDEX idx_subjects_priority ON subjects(priority);
CREATE INDEX idx_subjects_difficulty ON subjects(difficulty);
CREATE INDEX idx_subjects_mastery_level ON subjects(mastery_level);

-- Create trigger for updated_at
CREATE TRIGGER update_subjects_updated_at
    BEFORE UPDATE ON subjects
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Add RLS policies
ALTER TABLE subjects ENABLE ROW LEVEL SECURITY;

-- Users can only view their own subjects
CREATE POLICY "Users can view own subjects" ON subjects
    FOR SELECT USING (user_id = current_setting('app.current_user_id')::uuid);

-- Users can insert their own subjects
CREATE POLICY "Users can insert own subjects" ON subjects
    FOR INSERT WITH CHECK (user_id = current_setting('app.current_user_id')::uuid);

-- Users can update their own subjects
CREATE POLICY "Users can update own subjects" ON subjects
    FOR UPDATE USING (user_id = current_setting('app.current_user_id')::uuid);

-- Users can delete their own subjects
CREATE POLICY "Users can delete own subjects" ON subjects
    FOR DELETE USING (user_id = current_setting('app.current_user_id')::uuid);