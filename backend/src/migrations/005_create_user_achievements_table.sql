-- Create achievements table (template)
CREATE TABLE IF NOT EXISTS achievements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    icon VARCHAR(100) NOT NULL,
    category VARCHAR(50) NOT NULL CHECK (category IN ('streak', 'time', 'sessions', 'subjects', 'special')),
    requirement_type VARCHAR(50) NOT NULL CHECK (requirement_type IN ('total_hours', 'streak_days', 'sessions_completed', 'subject_mastery', 'special')),
    requirement_value INTEGER NOT NULL,
    subject_name VARCHAR(255), -- For subject-specific achievements
    points INTEGER DEFAULT 10,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create user_achievements table (user's unlocked achievements)
CREATE TABLE IF NOT EXISTS user_achievements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    achievement_id UUID NOT NULL REFERENCES achievements(id) ON DELETE CASCADE,
    unlocked_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    progress DECIMAL(5,2) DEFAULT 1.00 CHECK (progress BETWEEN 0.00 AND 1.00),
    UNIQUE(user_id, achievement_id)
);

-- Create indexes for achievements
CREATE INDEX idx_achievements_category ON achievements(category);
CREATE INDEX idx_achievements_is_active ON achievements(is_active);
CREATE INDEX idx_achievements_requirement_type ON achievements(requirement_type);

-- Create indexes for user_achievements
CREATE INDEX idx_user_achievements_user_id ON user_achievements(user_id);
CREATE INDEX idx_user_achievements_achievement_id ON user_achievements(achievement_id);
CREATE INDEX idx_user_achievements_unlocked_at ON user_achievements(unlocked_at);

-- Insert default achievements
INSERT INTO achievements (title, description, icon, category, requirement_type, requirement_value, points) VALUES
('First Study Session', 'Complete your first study session', 'star', 'sessions', 'sessions_completed', 1, 10),
('Study Enthusiast', 'Complete 10 study sessions', 'fire', 'sessions', 'sessions_completed', 10, 25),
('Study Master', 'Complete 100 study sessions', 'trophy', 'sessions', 'sessions_completed', 100, 100),
('7 Day Streak', 'Study for 7 consecutive days', 'calendar', 'streak', 'streak_days', 7, 50),
('30 Day Streak', 'Study for 30 consecutive days', 'calendar.check', 'streak', 'streak_days', 30, 200),
('100 Hours Studied', 'Accumulate 100 hours of study time', 'clock', 'time', 'total_hours', 100, 75),
('500 Hours Studied', 'Accumulate 500 hours of study time', 'clock.fill', 'time', 'total_hours', 500, 300),
('Mathematics Beginner', 'Study Mathematics for 10 hours', 'book.closed', 'subjects', 'subject_mastery', 10, 30),
('Mathematics Expert', 'Study Mathematics for 100 hours', 'book.fill', 'subjects', 'subject_mastery', 100, 150),
('Physics Beginner', 'Study Physics for 10 hours', 'book.closed', 'subjects', 'subject_mastery', 10, 30),
('Physics Expert', 'Study Physics for 100 hours', 'book.fill', 'subjects', 'subject_mastery', 100, 150),
('Chemistry Beginner', 'Study Chemistry for 10 hours', 'book.closed', 'subjects', 'subject_mastery', 10, 30),
('Chemistry Expert', 'Study Chemistry for 100 hours', 'book.fill', 'subjects', 'subject_mastery', 100, 150),
('Biology Beginner', 'Study Biology for 10 hours', 'book.closed', 'subjects', 'subject_mastery', 10, 30),
('Biology Expert', 'Study Biology for 100 hours', 'book.fill', 'subjects', 'subject_mastery', 100, 150),
('Early Bird', 'Complete 5 study sessions before 9 AM', 'sunrise', 'special', 'special', 5, 40),
('Night Owl', 'Complete 5 study sessions after 9 PM', 'moon', 'special', 'special', 5, 40),
('Perfect Week', 'Complete all scheduled sessions for a week', 'checkmark.circle', 'special', 'special', 7, 100),
('Subject Master', 'Master 5 different subjects', 'graduationcap', 'special', 'special', 5, 200)
ON CONFLICT DO NOTHING;

-- Add RLS policies for user_achievements
ALTER TABLE user_achievements ENABLE ROW LEVEL SECURITY;

-- Users can only view their own achievements
CREATE POLICY "Users can view own achievements" ON user_achievements
    FOR SELECT USING (user_id = current_setting('app.current_user_id')::uuid);

-- Users can insert their own achievements
CREATE POLICY "Users can insert own achievements" ON user_achievements
    FOR INSERT WITH CHECK (user_id = current_setting('app.current_user_id')::uuid);

-- Users can update their own achievements (progress)
CREATE POLICY "Users can update own achievements" ON user_achievements
    FOR UPDATE USING (user_id = current_setting('app.current_user_id')::uuid);