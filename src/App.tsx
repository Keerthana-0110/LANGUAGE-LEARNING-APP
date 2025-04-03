import React, { useState, useEffect } from 'react';
import { Book, CheckCircle, XCircle, RefreshCw, Languages, LogOut } from 'lucide-react';
import { supabase } from './lib/supabase';
import { AuthForm } from './components/AuthForm';

interface Flashcard {
  id: number;
  word: string;
  translation: string;
  category: string;
}

interface UserProgress {
  flashcard_id: number;
  known: boolean;
}

function App() {
  const [session, setSession] = useState(null);
  const [flashcards, setFlashcards] = useState<Flashcard[]>([]);
  const [currentCardIndex, setCurrentCardIndex] = useState(0);
  const [isFlipped, setIsFlipped] = useState(false);
  const [knownWords, setKnownWords] = useState<number[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // Check active session
    supabase.auth.getSession().then(({ data: { session } }) => {
      setSession(session);
      if (session) {
        fetchFlashcards();
        fetchUserProgress();
      }
    });

    // Listen for auth changes
    const {
      data: { subscription },
    } = supabase.auth.onAuthStateChange((_event, session) => {
      setSession(session);
    });

    return () => subscription.unsubscribe();
  }, []);

  const fetchFlashcards = async () => {
    const { data, error } = await supabase
      .from('flashcards')
      .select('*')
      .order('id');
    
    if (error) {
      console.error('Error fetching flashcards:', error);
    } else {
      setFlashcards(data);
    }
  };

  const fetchUserProgress = async () => {
    const { data, error } = await supabase
      .from('users_progress')
      .select('flashcard_id')
      .eq('known', true);
    
    if (error) {
      console.error('Error fetching progress:', error);
    } else {
      setKnownWords(data.map(p => p.flashcard_id));
    }
    setLoading(false);
  };

  const handleNextCard = () => {
    setCurrentCardIndex((prev) => (prev + 1) % flashcards.length);
    setIsFlipped(false);
  };

  const handleKnowCard = async () => {
    const flashcardId = flashcards[currentCardIndex].id;
    
    if (!knownWords.includes(flashcardId)) {
      const { error } = await supabase
        .from('users_progress')
        .upsert({
          user_id: session?.user?.id,
          flashcard_id: flashcardId,
          known: true
        });

      if (!error) {
        setKnownWords([...knownWords, flashcardId]);
      }
    }
    handleNextCard();
  };

  const handleLogout = async () => {
    await supabase.auth.signOut();
    setSession(null);
    setKnownWords([]);
    setCurrentCardIndex(0);
  };

  if (!session) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 p-8 flex items-center justify-center">
        <AuthForm onSuccess={() => fetchFlashcards()} />
      </div>
    );
  }

  if (loading || flashcards.length === 0) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 flex items-center justify-center">
        <div className="text-2xl text-gray-600">Loading...</div>
      </div>
    );
  }

  const progress = (knownWords.length / flashcards.length) * 100;

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 p-8">
      <div className="max-w-4xl mx-auto">
        <header className="text-center mb-12 relative">
          <button
            onClick={handleLogout}
            className="absolute right-0 top-0 flex items-center gap-2 px-4 py-2 bg-gray-200 hover:bg-gray-300 rounded-lg text-gray-700 transition-colors"
          >
            <LogOut className="w-4 h-4" />
            Logout
          </button>
          <div className="flex items-center justify-center gap-3 mb-4">
            <Languages className="w-10 h-10 text-indigo-600" />
            <h1 className="text-4xl font-bold text-gray-800">LinguaLearn</h1>
          </div>
          <p className="text-gray-600">Master languages one word at a time</p>
        </header>

        <div className="grid md:grid-cols-3 gap-8">
          {/* Stats Panel */}
          <div className="bg-white rounded-xl shadow-lg p-6">
            <h2 className="text-xl font-semibold mb-4 flex items-center gap-2">
              <Book className="w-5 h-5 text-indigo-600" />
              Progress
            </h2>
            <div className="space-y-4">
              <div className="w-full bg-gray-200 rounded-full h-2">
                <div
                  className="bg-indigo-600 h-2 rounded-full transition-all duration-500"
                  style={{ width: `${progress}%` }}
                ></div>
              </div>
              <p className="text-gray-600">
                {knownWords.length} of {flashcards.length} words mastered
              </p>
            </div>
          </div>

          {/* Flashcard */}
          <div className="md:col-span-2">
            <div
              className="bg-white rounded-xl shadow-lg p-8 h-64 cursor-pointer transform transition-transform duration-500 hover:scale-102"
              onClick={() => setIsFlipped(!isFlipped)}
            >
              <div className="h-full flex flex-col items-center justify-center">
                <p className="text-sm text-indigo-600 mb-4">
                  {flashcards[currentCardIndex].category}
                </p>
                <p className="text-3xl font-bold text-gray-800 mb-4">
                  {isFlipped
                    ? flashcards[currentCardIndex].translation
                    : flashcards[currentCardIndex].word}
                </p>
                <p className="text-gray-500 text-sm">Click to flip</p>
              </div>
            </div>

            {/* Controls */}
            <div className="flex justify-center gap-4 mt-6">
              <button
                onClick={() => handleNextCard()}
                className="flex items-center gap-2 px-6 py-3 bg-gray-200 hover:bg-gray-300 rounded-lg text-gray-700 transition-colors"
              >
                <XCircle className="w-5 h-5" />
                Skip
              </button>
              <button
                onClick={() => handleKnowCard()}
                className="flex items-center gap-2 px-6 py-3 bg-indigo-600 hover:bg-indigo-700 rounded-lg text-white transition-colors"
              >
                <CheckCircle className="w-5 h-5" />
                I Know This
              </button>
              <button
                onClick={() => setCurrentCardIndex(0)}
                className="flex items-center gap-2 px-6 py-3 bg-gray-200 hover:bg-gray-300 rounded-lg text-gray-700 transition-colors"
              >
                <RefreshCw className="w-5 h-5" />
                Reset
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

export default App;