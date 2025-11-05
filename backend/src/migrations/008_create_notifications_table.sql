-- Create notification_templates table
CREATE TABLE IF NOT EXISTS notification_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    type VARCHAR(50) NOT NULL CHECK (type IN ('study_reminder', 'break_reminder', 'achievement', 'insight', 'deadline', 'motivation')),
    title_template TEXT NOT NULL, -- Template with placeholders like {subject}, {time}
    body_template TEXT NOT NULL,
    default_icon VARCHAR(100),
    priority VARCHAR(20) DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high', 'critical')),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create notifications table
CREATE TABLE IF NOT EXISTS notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type VARCHAR(50) NOT NULL CHECK (type IN ('study_reminder', 'break_reminder', 'achievement', 'insight', 'deadline', 'motivation')),
    title VARCHAR(255) NOT NULL,
    body TEXT NOT NULL,
    icon VARCHAR(100),
    priority VARCHAR(20) DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high', 'critical')),
    data JSONB DEFAULT '{}', -- Additional notification data
    scheduled_for TIMESTAMP WITH TIME ZONE,
    sent_at TIMESTAMP WITH TIME ZONE,
    read_at TIMESTAMP WITH TIME ZONE,
    delivery_status VARCHAR(50) DEFAULT 'pending' CHECK (delivery_status IN ('pending', 'sent', 'delivered', 'failed', 'cancelled')),
    error_message TEXT,
    retry_count INTEGER DEFAULT 0,
    max_retries INTEGER DEFAULT 3,
    expires_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create user_notification_preferences table
CREATE TABLE IF NOT EXISTS user_notification_preferences (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    notification_type VARCHAR(50) NOT NULL CHECK (notification_type IN ('study_reminder', 'break_reminder', 'achievement', 'insight', 'deadline', 'motivation')),
    is_enabled BOOLEAN DEFAULT TRUE,
    reminder_minutes INTEGER[] DEFAULT '{15, 5}', -- Minutes before session to remind
    time_window_start TIME DEFAULT '06:00:00', -- Start of quiet hours
    time_window_end TIME DEFAULT '22:00:00', -- End of quiet hours
    days_of_week INTEGER[] DEFAULT '{1,2,3,4,5}', -- Days to send (1=Monday, 7=Sunday)
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, notification_type)
);

-- Create notification_logs table for audit trail
CREATE TABLE IF NOT EXISTS notification_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    notification_id UUID REFERENCES notifications(id) ON DELETE SET NULL,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    action VARCHAR(50) NOT NULL CHECK (action IN ('created', 'scheduled', 'sent', 'delivered', 'failed', 'read', 'cancelled')),
    details JSONB DEFAULT '{}',
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for notification_templates
CREATE INDEX idx_notification_templates_type ON notification_templates(type);
CREATE INDEX idx_notification_templates_is_active ON notification_templates(is_active);

-- Create indexes for notifications
CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_type ON notifications(type);
CREATE INDEX idx_notifications_priority ON notifications(priority);
CREATE INDEX idx_notifications_scheduled_for ON notifications(scheduled_for) WHERE delivery_status = 'pending';
CREATE INDEX idx_notifications_sent_at ON notifications(sent_at);
CREATE INDEX idx_notifications_read_at ON notifications(read_at);
CREATE INDEX idx_notifications_delivery_status ON notifications(delivery_status);
CREATE INDEX idx_notifications_expires_at ON notifications(expires_at) WHERE expires_at IS NOT NULL;
CREATE INDEX idx_notifications_user_pending ON notifications(user_id, delivery_status) WHERE delivery_status = 'pending';

-- Create indexes for user_notification_preferences
CREATE INDEX idx_user_notification_preferences_user_id ON user_notification_preferences(user_id);
CREATE INDEX idx_user_notification_preferences_type ON user_notification_preferences(notification_type);
CREATE INDEX idx_user_notification_preferences_enabled ON user_notification_preferences(is_enabled);

-- Create indexes for notification_logs
CREATE INDEX idx_notification_logs_notification_id ON notification_logs(notification_id);
CREATE INDEX idx_notification_logs_user_id ON notification_logs(user_id);
CREATE INDEX idx_notification_logs_action ON notification_logs(action);
CREATE INDEX idx_notification_logs_created_at ON notification_logs(created_at);

-- Create triggers for updated_at
CREATE TRIGGER update_notification_templates_updated_at
    BEFORE UPDATE ON notification_templates
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_notifications_updated_at
    BEFORE UPDATE ON notifications
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_notification_preferences_updated_at
    BEFORE UPDATE ON user_notification_preferences
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Insert default notification templates
INSERT INTO notification_templates (type, title_template, body_template, priority) VALUES
('study_reminder', 'Study Reminder: {subject}', 'Time to study {subject}. Topics: {topics}', 'high'),
('break_reminder', 'Break Time!', 'You have been studying for {duration} minutes. Time for a {break_length} minute break.', 'normal'),
('achievement', 'Achievement Unlocked!', 'Congratulations! You have unlocked: {achievement_title}', 'high'),
('insight', 'AI Insight: {insight_type}', '{insight_description}. {actionable_tip}', 'normal'),
('deadline', 'Task Due Soon', 'Your task "{task_title}" is due {due_time}', 'high'),
('motivation', 'Daily Motivation', '{motivational_quote}', 'low')
ON CONFLICT DO NOTHING;

-- Add default user notification preferences for new users
CREATE OR REPLACE FUNCTION set_default_notification_preferences()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO user_notification_preferences (user_id, notification_type)
    SELECT
        NEW.id,
        unnest(ARRAY['study_reminder', 'break_reminder', 'achievement', 'insight', 'deadline', 'motivation'])
    ON CONFLICT (user_id, notification_type) DO NOTHING;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_default_notification_preferences_trigger
    AFTER INSERT ON users
    FOR EACH ROW
    EXECUTE FUNCTION set_default_notification_preferences();

-- Add constraints
ALTER TABLE notifications ADD CONSTRAINT check_notification_times
    CHECK (
        (scheduled_for IS NULL) OR
        (sent_at IS NULL OR scheduled_for <= sent_at)
    );

ALTER TABLE notifications ADD CONSTRAINT check_notification_read_time
    CHECK (
        (read_at IS NULL) OR
        (sent_at IS NULL OR read_at >= sent_at)
    );

ALTER TABLE notifications ADD CONSTRAINT check_retry_count
    CHECK (retry_count >= 0 AND retry_count <= max_retries);

ALTER TABLE user_notification_preferences ADD CONSTRAINT check_reminder_minutes
    CHECK (array_length(reminder_minutes, 1) IS NULL OR cardinality(reminder_minutes) > 0);

ALTER TABLE user_notification_preferences ADD CONSTRAINT check_days_of_week
    CHECK (array_length(days_of_week, 1) IS NULL OR (
        cardinality(days_of_week) > 0 AND
        days_of_week <@ ARRAY[1,2,3,4,5,6,7]
    ));

-- Add RLS policies
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_notification_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification_logs ENABLE ROW LEVEL SECURITY;

-- Users can only view their own notifications
CREATE POLICY "Users can view own notifications" ON notifications
    FOR SELECT USING (user_id = current_setting('app.current_user_id')::uuid);

-- Users can only view their own notification preferences
CREATE POLICY "Users can view own notification preferences" ON user_notification_preferences
    FOR SELECT USING (user_id = current_setting('app.current_user_id')::uuid);

-- Users can only view their own notification logs
CREATE POLICY "Users can view own notification logs" ON notification_logs
    FOR SELECT USING (user_id = current_setting('app.current_user_id')::uuid);

-- Users can update their own notification preferences
CREATE POLICY "Users can update own notification preferences" ON user_notification_preferences
    FOR UPDATE USING (user_id = current_setting('app.current_user_id')::uuid);

-- Users can update their own notifications (mark as read)
CREATE POLICY "Users can update own notifications" ON notifications
    FOR UPDATE USING (user_id = current_setting('app.current_user_id')::uuid);