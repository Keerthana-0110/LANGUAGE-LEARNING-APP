/*
  # Initial Schema Setup

  1. New Tables
    - `users_progress`
      - `id` (uuid, primary key)
      - `user_id` (uuid, references auth.users)
      - `flashcard_id` (integer)
      - `known` (boolean)
      - `created_at` (timestamp)
    
    - `flashcards`
      - `id` (integer, primary key)
      - `word` (text)
      - `translation` (text)
      - `category` (text)
      - `created_at` (timestamp)

  2. Security
    - Enable RLS on all tables
    - Add policies for authenticated users
*/

-- Create flashcards table
CREATE TABLE flashcards (
    id SERIAL PRIMARY KEY,
    word TEXT NOT NULL,
    translation TEXT NOT NULL,
    category TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create users_progress table
CREATE TABLE users_progress (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users NOT NULL,
    flashcard_id INTEGER REFERENCES flashcards NOT NULL,
    known BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, flashcard_id)
);

-- Enable RLS
ALTER TABLE flashcards ENABLE ROW LEVEL SECURITY;
ALTER TABLE users_progress ENABLE ROW LEVEL SECURITY;

-- Policies for flashcards
CREATE POLICY "Flashcards are viewable by authenticated users"
    ON flashcards
    FOR SELECT
    TO authenticated
    USING (true);

-- Policies for users_progress
CREATE POLICY "Users can view their own progress"
    ON users_progress
    FOR SELECT
    TO authenticated
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own progress"
    ON users_progress
    FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own progress"
    ON users_progress
    FOR UPDATE
    TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Insert initial flashcards
INSERT INTO flashcards (word, translation, category) VALUES
    ('Hello', 'Hola', 'Greetings'),
    ('Goodbye', 'Adiós', 'Greetings'),
    ('Thank you', 'Gracias', 'Common Phrases'),
    ('Please', 'Por favor', 'Common Phrases'),
    ('Good morning', 'Buenos días', 'Greetings');