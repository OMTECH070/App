-- Create subscription_plans table
CREATE TABLE IF NOT EXISTS subscription_plans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL UNIQUE,
    tier VARCHAR(50) NOT NULL CHECK (tier IN ('premium', 'student_plus')),
    price_cents INTEGER NOT NULL,
    currency VARCHAR(3) DEFAULT 'USD',
    interval VARCHAR(20) NOT NULL CHECK (interval IN ('month', 'year')),
    features JSONB NOT NULL DEFAULT '[]',
    stripe_price_id VARCHAR(100),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create subscriptions table
CREATE TABLE IF NOT EXISTS subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    plan_id UUID REFERENCES subscription_plans(id) ON DELETE SET NULL,
    tier VARCHAR(50) NOT NULL CHECK (tier IN ('free', 'premium', 'student_plus')),
    status VARCHAR(50) NOT NULL CHECK (status IN ('active', 'cancelled', 'expired', 'past_due')),
    current_period_start TIMESTAMP WITH TIME ZONE NOT NULL,
    current_period_end TIMESTAMP WITH TIME ZONE NOT NULL,
    cancel_at_period_end BOOLEAN DEFAULT FALSE,
    stripe_subscription_id VARCHAR(100),
    stripe_customer_id VARCHAR(100),
    trial_start TIMESTAMP WITH TIME ZONE,
    trial_end TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id) -- One subscription per user
);

-- Create subscription_events table for webhooks
CREATE TABLE IF NOT EXISTS subscription_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    stripe_event_id VARCHAR(100) UNIQUE NOT NULL,
    subscription_id UUID REFERENCES subscriptions(id) ON DELETE SET NULL,
    event_type VARCHAR(100) NOT NULL,
    event_data JSONB NOT NULL,
    processed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for subscription_plans
CREATE INDEX idx_subscription_plans_tier ON subscription_plans(tier);
CREATE INDEX idx_subscription_plans_is_active ON subscription_plans(is_active);

-- Create indexes for subscriptions
CREATE INDEX idx_subscriptions_user_id ON subscriptions(user_id);
CREATE INDEX idx_subscriptions_tier ON subscriptions(tier);
CREATE INDEX idx_subscriptions_status ON subscriptions(status);
CREATE INDEX idx_subscriptions_current_period_end ON subscriptions(current_period_end);
CREATE INDEX idx_subscriptions_stripe_customer_id ON subscriptions(stripe_customer_id);

-- Create indexes for subscription_events
CREATE INDEX idx_subscription_events_stripe_event_id ON subscription_events(stripe_event_id);
CREATE INDEX idx_subscription_events_subscription_id ON subscription_events(subscription_id);
CREATE INDEX idx_subscription_events_event_type ON subscription_events(event_type);

-- Create trigger for updated_at
CREATE TRIGGER update_subscription_plans_updated_at
    BEFORE UPDATE ON subscription_plans
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_subscriptions_updated_at
    BEFORE UPDATE ON subscriptions
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Insert default subscription plans
INSERT INTO subscription_plans (name, tier, price_cents, interval, features) VALUES
('Premium Monthly', 'premium', 999, 'month', '[
  "AI-powered study scheduling",
  "Advanced analytics & insights",
  "Unlimited subjects & tasks",
  "Custom notifications",
  "Export reports (PDF, CSV)",
  "Priority support"
]'),
('Premium Yearly', 'premium', 5999, 'year', '[
  "AI-powered study scheduling",
  "Advanced analytics & insights",
  "Unlimited subjects & tasks",
  "Custom notifications",
  "Export reports (PDF, CSV)",
  "Priority support",
  "Save 17% vs monthly"
]'),
('Student Plus Monthly', 'student_plus', 1499, 'month', '[
  "All Premium features",
  "Multi-device sync",
  "Parent/mentor dashboard",
  "Advanced spaced repetition",
  "AI learning style adaptation",
  "Extended cloud storage (10GB)",
  "Early access to new features"
]'),
('Student Plus Yearly', 'student_plus', 8999, 'year', '[
  "All Premium features",
  "Multi-device sync",
  "Parent/mentor dashboard",
  "Advanced spaced repetition",
  "AI learning style adaptation",
  "Extended cloud storage (10GB)",
  "Early access to new features",
  "Save 50% vs monthly"
]')
ON CONFLICT (name) DO NOTHING;

-- Add RLS policies for subscriptions
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;

-- Users can only view their own subscriptions
CREATE POLICY "Users can view own subscription" ON subscriptions
    FOR SELECT USING (user_id = current_setting('app.current_user_id')::uuid);

-- Users can insert their own subscriptions
CREATE POLICY "Users can insert own subscription" ON subscriptions
    FOR INSERT WITH CHECK (user_id = current_setting('app.current_user_id')::uuid);

-- Users can update their own subscriptions
CREATE POLICY "Users can update own subscription" ON subscriptions
    FOR UPDATE USING (user_id = current_setting('app.current_user_id')::uuid);

-- Add constraint to ensure period dates are logical
ALTER TABLE subscriptions ADD CONSTRAINT check_subscription_period_dates
    CHECK (current_period_end > current_period_start);

-- Add constraint to ensure trial dates are logical
ALTER TABLE subscriptions ADD CONSTRAINT check_subscription_trial_dates
    CHECK (
        (trial_start IS NULL AND trial_end IS NULL) OR
        (trial_start IS NOT NULL AND trial_end IS NOT NULL AND trial_end > trial_start)
    );