/*
  # Create initial schema

  1. New Tables
    - `levels`
      - `id` (integer, primary key)
      - `name` (text)
      - `description` (text)
      - `order` (integer)
      - `required_score` (integer)
    
    - `quizzes`
      - `id` (uuid, primary key)
      - `level_id` (integer)
      - `question` (text)
      - `correct_answer` (text)
      - `options` (text[])
    
    - `user_levels`
      - `id` (uuid, primary key)
      - `user_id` (uuid)
      - `level_id` (integer)
      - `completed` (boolean)
      - `score` (integer)
      - `accuracy` (float)
    
    - `quiz_attempts`
      - `id` (uuid, primary key)
      - `user_id` (uuid)
      - `quiz_id` (uuid)
      - `answer` (text)
      - `is_correct` (boolean)
      - `created_at` (timestamp)

  2. Security
    - Enable RLS on all tables
    - Add policies for authenticated users
*/

-- Create levels table
CREATE TABLE IF NOT EXISTS levels (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  "order" INTEGER NOT NULL,
  required_score INTEGER NOT NULL DEFAULT 70
);

-- Create quizzes table
CREATE TABLE IF NOT EXISTS quizzes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  level_id INTEGER REFERENCES levels(id) NOT NULL,
  question TEXT NOT NULL,
  correct_answer TEXT NOT NULL,
  options TEXT[] NOT NULL
);

-- Create user_levels table
CREATE TABLE IF NOT EXISTS user_levels (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) NOT NULL,
  level_id INTEGER REFERENCES levels(id) NOT NULL,
  completed BOOLEAN DEFAULT false,
  score INTEGER DEFAULT 0,
  accuracy FLOAT DEFAULT 0,
  UNIQUE(user_id, level_id)
);

-- Create quiz_attempts table
CREATE TABLE IF NOT EXISTS quiz_attempts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) NOT NULL,
  quiz_id UUID REFERENCES quizzes(id) NOT NULL,
  answer TEXT NOT NULL,
  is_correct BOOLEAN NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Add level_id to flashcards if it doesn't exist
DO $$ 
BEGIN 
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'flashcards' AND column_name = 'level_id'
  ) THEN
    ALTER TABLE flashcards ADD COLUMN level_id INTEGER REFERENCES levels(id);
  END IF;
END $$;

-- Enable RLS
ALTER TABLE levels ENABLE ROW LEVEL SECURITY;
ALTER TABLE quizzes ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_levels ENABLE ROW LEVEL SECURITY;
ALTER TABLE quiz_attempts ENABLE ROW LEVEL SECURITY;

-- Create policies
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'levels' AND policyname = 'Levels are viewable by authenticated users'
  ) THEN
    CREATE POLICY "Levels are viewable by authenticated users" 
    ON levels FOR SELECT TO authenticated USING (true);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'quizzes' AND policyname = 'Quizzes are viewable by authenticated users'
  ) THEN
    CREATE POLICY "Quizzes are viewable by authenticated users" 
    ON quizzes FOR SELECT TO authenticated USING (true);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'user_levels' AND policyname = 'Users can view their own level progress'
  ) THEN
    CREATE POLICY "Users can view their own level progress" 
    ON user_levels FOR SELECT TO authenticated 
    USING (auth.uid() = user_id);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'user_levels' AND policyname = 'Users can update their own level progress'
  ) THEN
    CREATE POLICY "Users can update their own level progress" 
    ON user_levels FOR INSERT TO authenticated 
    WITH CHECK (auth.uid() = user_id);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'quiz_attempts' AND policyname = 'Users can insert their own quiz attempts'
  ) THEN
    CREATE POLICY "Users can insert their own quiz attempts" 
    ON quiz_attempts FOR INSERT TO authenticated 
    WITH CHECK (auth.uid() = user_id);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'quiz_attempts' AND policyname = 'Users can view their own quiz attempts'
  ) THEN
    CREATE POLICY "Users can view their own quiz attempts" 
    ON quiz_attempts FOR SELECT TO authenticated 
    USING (auth.uid() = user_id);
  END IF;
END $$;

-- Insert initial levels if they don't exist
INSERT INTO levels (name, description, "order", required_score)
SELECT 'Beginner', 'Basic vocabulary and simple phrases', 1, 70
WHERE NOT EXISTS (SELECT 1 FROM levels WHERE "order" = 1);

INSERT INTO levels (name, description, "order", required_score)
SELECT 'Elementary', 'Common expressions and basic grammar', 2, 75
WHERE NOT EXISTS (SELECT 1 FROM levels WHERE "order" = 2);

INSERT INTO levels (name, description, "order", required_score)
SELECT 'Intermediate', 'Complex sentences and conversations', 3, 80
WHERE NOT EXISTS (SELECT 1 FROM levels WHERE "order" = 3);

INSERT INTO levels (name, description, "order", required_score)
SELECT 'Advanced', 'Fluent conversations and idioms', 4, 85
WHERE NOT EXISTS (SELECT 1 FROM levels WHERE "order" = 4);

-- Insert sample quizzes for each level if they don't exist
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM quizzes LIMIT 1) THEN
    -- Beginner level quizzes
    INSERT INTO quizzes (level_id, question, correct_answer, options)
    SELECT 
      1,
      'What is "Hello" in Spanish?',
      'Hola',
      ARRAY['Hola', 'Adios', 'Gracias', 'Por favor'];

    -- Elementary level quizzes
    INSERT INTO quizzes (level_id, question, correct_answer, options)
    SELECT 
      2,
      'Which is the correct way to say "I am hungry" in Spanish?',
      'Tengo hambre',
      ARRAY['Estoy hambre', 'Tengo hambre', 'Soy hambre', 'Estar hambre'];

    -- Intermediate level quizzes
    INSERT INTO quizzes (level_id, question, correct_answer, options)
    SELECT 
      3,
      'What is the correct conjugation of "to be" in "I am happy"?',
      'Estoy feliz',
      ARRAY['Soy feliz', 'Estoy feliz', 'Estar feliz', 'Es feliz'];

    -- Advanced level quizzes
    INSERT INTO quizzes (level_id, question, correct_answer, options)
    SELECT 
      4,
      'Which is the correct subjunctive form in: "I hope that..."?',
      'Espero que',
      ARRAY['Espero que', 'Espero', 'Esperando que', 'Esperé que'];
  END IF;
END $$;