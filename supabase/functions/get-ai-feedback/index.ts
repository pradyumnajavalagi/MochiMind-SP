import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { corsHeaders } from '../_shared/cors.ts';

// The endpoint for the Gemini API
const GEMINI_API_URL = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';

// Your secret API key, retrieved from Supabase secrets
const GEMINI_API_KEY = Deno.env.get('GEMINI_API_KEY');

// Helper function to get the name of a Kanji from its flashcard ID.
// In a real app, you might fetch this from your 'flashcards' table.
// For now, we'll pass it from the client.
async function getKanjiCharacter(flashcardId: string, client: any) {
  // This is a placeholder. In a more advanced version, you could query your DB here.
  // For now, we rely on the data sent from the Flutter app.
  return '...';
}

serve(async (req) => {
  // This is needed to handle OPTIONS requests from the browser
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    // 1. Get the test results from the request body
    const { testResults } = await req.json();

    if (!testResults || !Array.isArray(testResults)) {
      throw new Error('Missing or invalid "testResults" in the request body.');
    }

    // 2. Process the results to identify strengths and weaknesses
    const forgotten = testResults.filter(r => r.rating === 'forgot').map(r => r.kanjiChar);
    const hard = testResults.filter(r => r.rating === 'hard').map(r => r.kanjiChar);
    const good = testResults.filter(r => r.rating === 'good').map(r => r.kanjiChar);
    const easy = testResults.filter(r => r.rating === 'easy').map(r => r.kanjiChar);

    // Remove duplicates
    const forgottenSet = [...new Set(forgotten)];
    const hardSet = [...new Set(hard)];

    // 3. Construct a specific prompt for the Gemini API
    let prompt = `A Japanese language learner just finished a flashcard test.
- They completely forgot these kanji: ${forgottenSet.join(', ') || 'None'}.
- They found these kanji hard: ${hardSet.join(', ') || 'None'}.
- They were good with: ${[...new Set(good)].join(', ') || 'None'}.
- They found these easy: ${[...new Set(easy)].join(', ') || 'None'}.

Based on this, provide a short (2-3 sentences), encouraging, and helpful analysis.
Focus on the most difficult kanji (${[...forgottenSet, ...hardSet].join(', ')}).
Give one specific, actionable tip to help them improve.
Format the response as a single JSON object with one key: "feedback". The value should be a single string.`;


    // 4. Make the secure, server-to-server API call to Gemini
    const geminiResponse = await fetch(`${GEMINI_API_URL}?key=${GEMINI_API_KEY}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        contents: [{ parts: [{ text: prompt }] }],
        // Add safety settings to reduce the chance of the API refusing to answer
        safetySettings: [
            { "category": "HARM_CATEGORY_HARASSMENT", "threshold": "BLOCK_NONE" },
            { "category": "HARM_CATEGORY_HATE_SPEECH", "threshold": "BLOCK_NONE" },
            { "category": "HARM_CATEGORY_SEXUALLY_EXPLICIT", "threshold": "BLOCK_NONE" },
            { "category": "HARM_CATEGORY_DANGEROUS_CONTENT", "threshold": "BLOCK_NONE" }
        ]
      }),
    });

    if (!geminiResponse.ok) {
      const errorBody = await geminiResponse.text();
      throw new Error(`Gemini API request failed: ${errorBody}`);
    }

    const geminiData = await geminiResponse.json();
    
    // 5. Extract the generated text from the response
    const generatedText = geminiData.candidates[0].content.parts[0].text;
    
    // Clean up potential markdown formatting from the response
    const cleanedJsonString = generatedText.replace(/```json\n/g, '').replace(/\n```/g, '');
    const feedbackJson = JSON.parse(cleanedJsonString);

    // 6. Send the extracted feedback back to the Flutter app
    return new Response(
      JSON.stringify(feedbackJson),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );

  } catch (error) {
    console.error(error);
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});