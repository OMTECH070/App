-- Create study_tasks table
CREATE TABLE IF NOT EXISTS study_tasks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    subject_id UUID REFERENCES subjects(id) ON DELETE SET NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    subject VARCHAR(255) NOT NULL, -- Denormalized for queries
    due_date TIMESTAMP WITH TIME ZONE,
    estimated_duration BIGINT, -- in seconds
    priority INTEGER CHECK (priority BETWEEN 1 AND 5) DEFAULT 1,
    is_completed BOOLEAN DEFAULT FALSE,
    completed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes
CREATE INDEX idx_study_tasks_user_id ON study_tasks(user_id);
CREATE INDEX idx_study_tasks_subject_id ON study_tasks(subject_id);
CREATE INDEX idx_study_tasks_is_completed ON study_tasks(is_completed);
CREATE INDEX idx_study_tasks_due_date ON study_tasks(due_date) WHERE due_date IS NOT NULL;
CREATE INDEX idx_study_tasks_priority ON study_tasks(priority);
CREATE INDEX idx_study_tasks_user_due ON study_tasks(user_id, due_date) WHERE due_date IS NOT NULL;
CREATE INDEX idx_study_tasks_user_pending ON study_tasks(user_id, is_completed) WHERE is_completed = FALSE;

-- Create trigger for updated_at
CREATE TRIGGER update_study_tasks_updated_at
    BEFORE UPDATE ON study_tasks
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Add check constraint for completion logic
ALTER TABLE study_tasks ADD CONSTRAINT check_task_completion_logic
    CHECK (
        (is_completed = FALSE AND completed_at IS NULL) OR
        (is_completed = TRUE AND completed_at IS NOT NULL)
    );

-- Add constraint to ensure due_date is in the future when set
ALTER TABLE study_tasks ADD CONSTRAINT check_due_date_future
    CHECK (due_date IS NULL OR due_date >= created_at);

-- Add constraint for estimated duration
ALTER TABLE study_tasks ADD CONSTRAINT check_task_duration_positive
    CHECK (estimated_duration IS NULL OR (estimated_duration > 0 AND estimated_duration <= 86400));

-- Add RLS policies
ALTER TABLE study_tasks ENABLE ROW LEVEL SECURITY;

-- Users can only view their own tasks
CREATE POLICY "Users can view own study tasks" ON study_tasks
    FOR SELECT USING (user_id = current_setting('app.current_user_id')::uuid);

-- Users can insert their own tasks
CREATE POLICY "Users can insert own study tasks" ON study_tasks
    FOR INSERT WITH CHECK (user_id = current_setting('app.current_user_id')::uuid);

-- Users can update their own tasks
CREATE POLICY "Users can update own study tasks" ON study_tasks
    FOR UPDATE USING (user_id = current_setting('app.current_user_id')::uuid);

-- Users can delete their own tasks
CREATE POLICY "Users can delete own study tasks" ON study_tasks
    FOR DELETE USING (user_id = current_setting('app.current_user_id')::uuid);