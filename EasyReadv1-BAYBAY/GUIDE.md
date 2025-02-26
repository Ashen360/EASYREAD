# Google Gemini API Integration for EasyRead

This guide walks through setting up and integrating the Google Gemini API with your EasyRead application.

## 1. Set Up Google AI Studio

1. Visit [Google AI Studio](https://makersuite.google.com/) and sign in with your Google account
2. Create a new API key by navigating to the API Keys section
3. Store your API key securely - never commit it directly to your code repository

## 2. Install Required Package

In your React project directory, install the Google Generative AI package:

```bash
npm install @google/generative-ai
```

## 3. Configure Environment Variables

Create a `.env` file in your project root to store your API key:

```
REACT_APP_GEMINI_API_KEY=your_api_key_here
```

Then update your `geminiService.js` file to use this environment variable:

```javascript
const API_KEY = process.env.REACT_APP_GEMINI_API_KEY;
```

## 4. Test API Connection

Before implementing the full application, test your API connection with a simple script:

```javascript
import { GoogleGenerativeAI } from "@google/generative-ai";

const API_KEY = process.env.REACT_APP_GEMINI_API_KEY;
const genAI = new GoogleGenerativeAI(API_KEY);

async function testConnection() {
  const model = genAI.getGenerativeModel({ model: "gemini-pro" });
  
  try {
    const result = await model.generateContent("Hello, can you help me with reading?");
    console.log("API Response:", result.response.text());
    console.log("API connection successful!");
  } catch (error) {
    console.error("API connection failed:", error);
  }
}

testConnection();
```

## 5. Implement API Rate Limiting

Gemini API has rate limits. Implement a simple rate limiting mechanism:

```javascript
// Simple rate limiting utility
const rateLimiter = {
  timestamps: [],
  maxRequests: 10, // Adjust based on your API tier
  timeWindow: 60000, // 1 minute in milliseconds
  
  canMakeRequest() {
    const now = Date.now();
    // Remove timestamps outside the time window
    this.timestamps = this.timestamps.filter(time => now - time < this.timeWindow);
    
    if (this.timestamps.length < this.maxRequests) {
      this.timestamps.push(now);
      return true;
    }
    
    return false;
  },
  
  getTimeUntilNextAvailable() {
    if (this.timestamps.length === 0) return 0;
    const oldestTimestamp = Math.min(...this.timestamps);
    return Math.max(0, this.timeWindow - (Date.now() - oldestTimestamp));
  }
};

// Usage in your API calls
export const processWithGemini = async (userInput) => {
  if (!rateLimiter.canMakeRequest()) {
    const waitTime = rateLimiter.getTimeUntilNextAvailable();
    throw new Error(`Rate limit reached. Please try again in ${Math.ceil(waitTime/1000)} seconds.`);
  }
  
  // Proceed with API call
  // ...
};
```

## 6. Implement Error Handling

Add comprehensive error handling for various API failure scenarios:

```javascript
export const processWithGemini = async (userInput) => {
  try {
    // API call logic here
    // ...
  } catch (error) {
    // Handle different error types
    if (error.message.includes('API key')) {
      console.error('API Key error:', error);
      throw new Error('Authentication failed. Please check your API configuration.');
    } else if (error.message.includes('Rate limit')) {
      console.error('Rate limit error:', error);
      throw error; // Pass through rate limit errors
    } else if (error.response && error.response.status === 400) {
      console.error('Invalid request error:', error);
      throw new Error('Your request could not be processed. Please try different input.');
    } else {
      console.error('Unexpected error:', error);
      throw new Error('An unexpected error occurred. Please try again later.');
    }
  }
};
```

## 7. Implement Fallback Mechanisms

Add fallbacks in case the API is unavailable:

```javascript
const FALLBACK_RESPONSES = [
  "I can help break down this text into simpler parts.",
  "Would you like me to explain any difficult words in this text?",
  "I can read this text aloud for you. Would that help?",
  "Let me know if you need me to simplify this further."
];

// In your API function
if (apiFailure) {
  return FALLBACK_RESPONSES[Math.floor(Math.random() * FALLBACK_RESPONSES.length)];
}
```

## 8. Testing and Monitoring

After integration, monitor your API usage with simple logging:

```javascript
// Add logging to your API calls
const logApiUsage = (functionName, inputLength, responseLength) => {
  console.log(`API Call: ${functionName}, Input length: ${inputLength}, Response length: ${responseLength}, Time: ${new Date().toISOString()}`);
  
  // You could send this data to a monitoring service in a production app
};

// Use in your API functions
export const processWithGemini = async (userInput) => {
  // ...API call logic
  
  // Log after successful call