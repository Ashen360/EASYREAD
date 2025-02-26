// geminiService.js - Service for integrating with Google's Gemini API

import { GoogleGenerativeAI } from "@google/generative-ai";

// Initialize the Gemini API with your API key
// You'll need to get an API key from Google AI Studio: https://makersuite.google.com/
const API_KEY = "AIzaSyCdX0QcaU3AU2QkfEGM1Ctza2tIsgn4o7k"; // Replace with your actual API key
const genAI = new GoogleGenerativeAI(API_KEY);

// System instructions to provide context for the model
const SYSTEM_INSTRUCTIONS = `
You are an app that helps students with dyslexia by providing real-time support,
such as text-to-speech and word highlighting, to improve reading comprehension.

When responding to users:
1. Use clear, simple language with straightforward sentence structure
2. Break down complex information into manageable chunks
3. Avoid idioms, metaphors, or ambiguous language
4. Offer to simplify text when appropriate
5. Ask if the user would like you to read text aloud
6. Explain difficult words when they appear
7. Maintain a supportive, patient tone
8. Keep responses relatively concise (3-5 sentences when possible)
9. Use bullet points for lists rather than long paragraphs
10. Prefer active voice over passive voice
11. Use concrete examples when explaining abstract concepts
`;

// Function to process user input with Gemini
export const processWithGemini = async (userInput) => {
  try {
    // Get the Gemini Pro model
    const model = genAI.getGenerativeModel({ 
      model: "gemini-1.5-flash",
      safetySettings: [
        {
          category: "HARM_CATEGORY_HARASSMENT",
          threshold: "BLOCK_MEDIUM_AND_ABOVE"
        },
        {
          category: "HARM_CATEGORY_HATE_SPEECH",
          threshold: "BLOCK_MEDIUM_AND_ABOVE"
        },
        {
          category: "HARM_CATEGORY_SEXUALLY_EXPLICIT",
          threshold: "BLOCK_MEDIUM_AND_ABOVE"
        },
        {
          category: "HARM_CATEGORY_DANGEROUS_CONTENT",
          threshold: "BLOCK_MEDIUM_AND_ABOVE"
        }
      ]
    });
    
    // Create a chat session
    const chat = model.startChat({
      generationConfig: {
        temperature: 0.2,  // Lower temperature for more consistent, focused responses
        maxOutputTokens: 1000,
        topP: 0.8,
        topK: 40,
      },
      safetySettings: [
        {
          category: "HARM_CATEGORY_HARASSMENT",
          threshold: "BLOCK_MEDIUM_AND_ABOVE"
        },
        {
          category: "HARM_CATEGORY_HATE_SPEECH",
          threshold: "BLOCK_MEDIUM_AND_ABOVE"
        },
        {
          category: "HARM_CATEGORY_SEXUALLY_EXPLICIT",
          threshold: "BLOCK_MEDIUM_AND_ABOVE"
        },
        {
          category: "HARM_CATEGORY_DANGEROUS_CONTENT",
          threshold: "BLOCK_MEDIUM_AND_ABOVE"
        }
      ],
      history: [
        {
          role: "model",
          parts: [{ text: `Hi there! I'm EasyRead, your reading assistant. 
            I am an app designed to help students who have dyslexia. 
            I can read text aloud to you, highlight words as you read, 
            and explain any words you don't understand. 
            I can also make the text easier to read if needed. 
            Would you like me to help you with some reading today?` }],
        },
      ],
    });
    
    // Add system instructions as a prefix to the user's message
    const enhancedPrompt = `${SYSTEM_INSTRUCTIONS}\n\nUser message: ${userInput}`;
    
    // Send the user's message and get a response
    const result = await chat.sendMessage(enhancedPrompt);
    const response = result.response.text();
    
    return response;
  } catch (error) {
    console.error("Error processing with Gemini API:", error);
    throw new Error("Failed to process your request with the AI assistant");
  }
};

// Function to simplify text
export const simplifyText = async (text) => {
  try {
    const model = genAI.getGenerativeModel({ model: "gemini-1.5-flash" });
    
    const prompt = `
    You are an assistant for people with dyslexia. Your task is to simplify the following text:
    
    "${text}"
    
    When simplifying:
    1. Use shorter, more common words
    2. Break long sentences into shorter ones
    3. Remove unnecessary words and jargon
    4. Use active voice instead of passive voice
    5. Maintain the original meaning and key information
    6. Use clear paragraph breaks for different ideas
    7. Add bullet points for lists when appropriate
    
    Return ONLY the simplified text, with no additional comments or explanations.
    `;
    
    const result = await model.generateContent(prompt);
    return result.response.text();
  } catch (error) {
    console.error("Error simplifying text:", error);
    throw new Error("Failed to simplify text");
  }
};

// Function to analyze text complexity
export const analyzeTextComplexity = async (text) => {
  try {
    const model = genAI.getGenerativeModel({ model: "gemini-1.5-flash" });
    
    const prompt = `
    Analyze the following text for reading complexity, focusing on aspects that would be challenging for someone with dyslexia.
    Format your response as JSON with the following structure:
    {
      "complexityScore": 1-10 (where 10 is most complex),
      "difficultWords": [{word: "example", meaning: "simple explanation", suggestion: "simpler word"}],
      "longSentences": ["sentence that could be broken down"],
      "suggestions": ["specific suggestion for improvement"]
    }
    
    Text to analyze: "${text}"
    `;
    
    const result = await model.generateContent(prompt);
    const response = result.response.text();
    
    // Parse the JSON response
    try {
      return JSON.parse(response);
    } catch (parseError) {
      console.error("Error parsing JSON response:", parseError);
      // Fallback response
      return {
        complexityScore: 5,
        difficultWords: [],
        longSentences: [],
        suggestions: ["No specific suggestions available."]
      };
    }
  } catch (error) {
    console.error("Error analyzing text complexity:", error);
    throw new Error("Failed to analyze text complexity");
  }
};

// Function to get explanation for difficult words
export const explainDifficultWords = async (text) => {
  try {
    const model = genAI.getGenerativeModel({ model: "gemini-1.5-flash" });
    
    const prompt = `
    The following text will be read by someone with dyslexia. 
    Identify potentially difficult words and provide simple explanations for them.
    Format your response as JSON with the following structure:
    {
      "explanations": [{word: "difficult word", explanation: "simple explanation", alternatives: ["simpler word 1", "simpler word 2"]}]
    }
    
    Text: "${text}"
    `;
    
    const result = await model.generateContent(prompt);
    const response = result.response.text();
    
    // Parse the JSON response
    try {
      return JSON.parse(response);
    } catch (parseError) {
      console.error("Error parsing JSON response:", parseError);
      // Fallback empty response
      return {
        explanations: []
      };
    }
  } catch (error) {
    console.error("Error explaining difficult words:", error);
    throw new Error("Failed to explain difficult words");
  }
};

// Export functions
export default {
  processWithGemini,
  simplifyText,
  analyzeTextComplexity,
  explainDifficultWords
};