/*
  # Add levels and quizzes support

  1. New Tables
    - `levels`
      - `id` (integer, primary key)
      - `name` (text)
      - `description` (text)
      - `order` (integer) - for level sequence
      - `required_score` (integer) - minimum score to unlock next level
    
    - `quizzes`
      - `id` (uuid, primary key)
      - `level_id` (integer) - references levels
      - `question` (text)
      - `correct_answer` (text)
      - `options` (text[]) - multiple choice options
    
    - `user_levels`
      - `id` (uuid, primary key)
      - `user_id` (uuid) - references auth.users
      - `level_id` (integer) - references levels
      - `completed` (boolean)
      - `score` (integer)
      - `accuracy` (float)
    
    - `quiz_attempts`
      - `id` (uuid, primary key)
      - `user_id` (uuid) - references auth.users
      - `quiz_id` (uuid) - references quizzes
      - `answer` (text)
      - `is_correct` (boolean)
      - `created_at` (timestamp)

  2. Modify existing tables
    - Add `level_id` to flashcards table

  3. Security
    - Enable RLS on all new tables
    - Add policies for authenticated users
*/

-- Create levels table
CREATE TABLE levels (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  "order" INTEGER NOT NULL,
  required_score INTEGER NOT NULL DEFAULT 70
);

-- Create quizzes table
CREATE TABLE quizzes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  level_id INTEGER REFERENCES levels(id) NOT NULL,
  question TEXT NOT NULL,
  correct_answer TEXT NOT NULL,
  options TEXT[] NOT NULL
);

-- Create user_levels table
CREATE TABLE user_levels (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) NOT NULL,
  level_id INTEGER REFERENCES levels(id) NOT NULL,
  completed BOOLEAN DEFAULT false,
  score INTEGER DEFAULT 0,
  accuracy FLOAT DEFAULT 0,
  UNIQUE(user_id, level_id)
);

-- Create quiz_attempts table
CREATE TABLE quiz_attempts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) NOT NULL,
  quiz_id UUID REFERENCES quizzes(id) NOT NULL,
  answer TEXT NOT NULL,
  is_correct BOOLEAN NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Add level_id to flashcards
ALTER TABLE flashcards 
ADD COLUMN level_id INTEGER REFERENCES levels(id);

-- Enable RLS
ALTER TABLE levels ENABLE ROW LEVEL SECURITY;
ALTER TABLE quizzes ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_levels ENABLE ROW LEVEL SECURITY;
ALTER TABLE quiz_attempts ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Levels are viewable by authenticated users" 
ON levels FOR SELECT TO authenticated USING (true);

CREATE POLICY "Quizzes are viewable by authenticated users" 
ON quizzes FOR SELECT TO authenticated USING (true);

CREATE POLICY "Users can view their own level progress" 
ON user_levels FOR SELECT TO authenticated 
USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own level progress" 
ON user_levels FOR INSERT TO authenticated 
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can insert their own quiz attempts" 
ON quiz_attempts FOR INSERT TO authenticated 
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view their own quiz attempts" 
ON quiz_attempts FOR SELECT TO authenticated 
USING (auth.uid() = user_id);

-- Insert initial levels
INSERT INTO levels (name, description, "order", required_score) VALUES
('Beginner', 'Basic vocabulary and simple phrases', 1, 70),
('Elementary', 'Common expressions and basic grammar', 2, 75),
('Intermediate', 'Complex sentences and conversations', 3, 80),
('Advanced', 'Fluent conversations and idioms', 4, 85);