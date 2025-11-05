-- Create daily_progress table for analytics
CREATE TABLE IF NOT EXISTS daily_progress (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    total_study_time BIGINT DEFAULT 0, -- in seconds
    completed_sessions INTEGER DEFAULT 0,
    total_sessions INTEGER DEFAULT 0,
    subjects_studied TEXT[] DEFAULT '{}', -- Array of subject names
    average_session_quality DECIMAL(3,2), -- Average quality rating (1-5)
    streak_day INTEGER, -- Day in current streak
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, date)
);

-- Create weekly_analytics table
CREATE TABLE IF NOT EXISTS weekly_analytics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    week_start DATE NOT NULL,
    week_end DATE NOT NULL,
    total_study_time BIGINT DEFAULT 0, -- in seconds
    completed_sessions INTEGER DEFAULT 0,
    subject_breakdown JSONB DEFAULT '{}', -- Subject: {time, sessions, percentage}
    average_daily_time BIGINT DEFAULT 0, -- in seconds
    streak_days INTEGER DEFAULT 0,
    longest_continuous_streak INTEGER DEFAULT 0,
    most_productive_hour INTEGER, -- Hour (0-23) with most study time
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, week_start)
);

-- Create monthly_analytics table
CREATE TABLE IF NOT EXISTS monthly_analytics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    month DATE NOT NULL, -- First day of the month
    total_study_time BIGINT DEFAULT 0, -- in seconds
    completed_sessions INTEGER DEFAULT 0,
    subject_breakdown JSONB DEFAULT '{}',
    average_daily_time BIGINT DEFAULT 0, -- in seconds
    total_days_active INTEGER DEFAULT 0,
    most_productive_day_of_week INTEGER, -- Day of week (0-6, Sunday=0)
    improvement_percentage DECIMAL(5,2), -- Improvement from previous month
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, month)
);

-- Create ai_insights table
CREATE TABLE IF NOT EXISTS ai_insights (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type VARCHAR(50) NOT NULL CHECK (type IN ('productivity', 'pattern', 'recommendation', 'warning')),
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    actionable_tip TEXT,
    priority VARCHAR(20) DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high')),
    is_read BOOLEAN DEFAULT FALSE,
    metadata JSONB DEFAULT '{}', -- Additional insight data
    expires_at TIMESTAMP WITH TIME ZONE, -- When insight becomes irrelevant
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create study_patterns table for ML analysis
CREATE TABLE IF NOT EXISTS study_patterns (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    pattern_type VARCHAR(50) NOT NULL CHECK (pattern_type IN ('daily_rhythm', 'weekly_pattern', 'subject_preference', 'session_optimal_length', 'break_effectiveness')),
    pattern_data JSONB NOT NULL,
    confidence_score DECIMAL(3,2) CHECK (confidence_score BETWEEN 0.00 AND 1.00),
    detected_at DATE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for daily_progress
CREATE INDEX idx_daily_progress_user_id ON daily_progress(user_id);
CREATE INDEX idx_daily_progress_date ON daily_progress(date);
CREATE INDEX idx_daily_progress_user_date ON daily_progress(user_id, date);
CREATE INDEX idx_daily_progress_streak_day ON daily_progress(streak_day);

-- Create indexes for weekly_analytics
CREATE INDEX idx_weekly_analytics_user_id ON weekly_analytics(user_id);
CREATE INDEX idx_weekly_analytics_week_start ON weekly_analytics(week_start);
CREATE INDEX idx_weekly_analytics_user_week ON weekly_analytics(user_id, week_start);

-- Create indexes for monthly_analytics
CREATE INDEX idx_monthly_analytics_user_id ON monthly_analytics(user_id);
CREATE INDEX idx_monthly_analytics_month ON monthly_analytics(month);
CREATE INDEX idx_monthly_analytics_user_month ON monthly_analytics(user_id, month);

-- Create indexes for ai_insights
CREATE INDEX idx_ai_insights_user_id ON ai_insights(user_id);
CREATE INDEX idx_ai_insights_type ON ai_insights(type);
CREATE INDEX idx_ai_insights_priority ON ai_insights(priority);
CREATE INDEX idx_ai_insights_is_read ON ai_insights(is_read);
CREATE INDEX idx_ai_insights_expires_at ON ai_insights(expires_at) WHERE expires_at IS NOT NULL;

-- Create indexes for study_patterns
CREATE INDEX idx_study_patterns_user_id ON study_patterns(user_id);
CREATE INDEX idx_study_patterns_pattern_type ON study_patterns(pattern_type);
CREATE INDEX idx_study_patterns_detected_at ON study_patterns(detected_at);
CREATE INDEX idx_study_patterns_confidence ON study_patterns(confidence_score);

-- Create triggers for updated_at
CREATE TRIGGER update_daily_progress_updated_at
    BEFORE UPDATE ON daily_progress
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_weekly_analytics_updated_at
    BEFORE UPDATE ON weekly_analytics
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_monthly_analytics_updated_at
    BEFORE UPDATE ON monthly_analytics
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_study_patterns_updated_at
    BEFORE UPDATE ON study_patterns
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Add constraints
ALTER TABLE daily_progress ADD CONSTRAINT check_daily_progress_sessions
    CHECK (completed_sessions <= total_sessions);

ALTER TABLE daily_progress ADD CONSTRAINT check_daily_progress_quality
    CHECK (average_session_quality IS NULL OR (average_session_quality >= 1.00 AND average_session_quality <= 5.00));

ALTER TABLE daily_progress ADD CONSTRAINT check_streak_day_positive
    CHECK (streak_day IS NULL OR streak_day > 0);

ALTER TABLE weekly_analytics ADD CONSTRAINT check_week_period_dates
    CHECK (week_end > week_start);

ALTER TABLE monthly_analytics ADD CONSTRAINT check_improvement_percentage
    CHECK (improvement_percentage IS NULL OR improvement_percentage >= -100.00);

-- Add RLS policies for analytics tables
ALTER TABLE daily_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE weekly_analytics ENABLE ROW LEVEL SECURITY;
ALTER TABLE monthly_analytics ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_insights ENABLE ROW LEVEL SECURITY;
ALTER TABLE study_patterns ENABLE ROW LEVEL SECURITY;

-- Users can only view their own analytics data
CREATE POLICY "Users can view own daily progress" ON daily_progress
    FOR SELECT USING (user_id = current_setting('app.current_user_id')::uuid);

CREATE POLICY "Users can view own weekly analytics" ON weekly_analytics
    FOR SELECT USING (user_id = current_setting('app.current_user_id')::uuid);

CREATE POLICY "Users can view own monthly analytics" ON monthly_analytics
    FOR SELECT USING (user_id = current_setting('app.current_user_id')::uuid);

CREATE POLICY "Users can view own AI insights" ON ai_insights
    FOR SELECT USING (user_id = current_setting('app.current_user_id')::uuid);

CREATE POLICY "Users can view own study patterns" ON study_patterns
    FOR SELECT USING (user_id = current_setting('app.current_user_id')::uuid);

-- Users can insert their own analytics data
CREATE POLICY "Users can insert own daily progress" ON daily_progress
    FOR INSERT WITH CHECK (user_id = current_setting('app.current_user_id')::uuid);

CREATE POLICY "Users can insert own AI insights" ON ai_insights
    FOR INSERT WITH CHECK (user_id = current_setting('app.current_user_id')::uuid);

-- Users can update their own analytics data
CREATE POLICY "Users can update own daily progress" ON daily_progress
    FOR UPDATE USING (user_id = current_setting('app.current_user_id')::uuid);

CREATE POLICY "Users can update own AI insights" ON ai_insights
    FOR UPDATE USING (user_id = current_setting('app.current_user_id')::uuid);