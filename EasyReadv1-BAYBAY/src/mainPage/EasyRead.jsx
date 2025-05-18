// EasyRead.jsx - Updated with real Gemini API integration - BAYBAY

import React, { useState, useRef, useEffect } from 'react';
import { processWithGemini, simplifyText } from '../APiService/GeminiService';
import './EasyRead.css';

const EasyRead = () => {
  const [input, setInput] = useState('');
  const [messages, setMessages] = useState([]);
  const [isProcessing, setIsProcessing] = useState(false);
  const [isSpeaking, setIsSpeaking] = useState(false);
  const [fontSize, setFontSize] = useState(18);
  const [lineSpacing, setLineSpacing] = useState(1.5);
  const [fontFamily, setFontFamily] = useState('OpenDyslexic');
  const messagesEndRef = useRef(null);
  const speechSynthesisRef = useRef(null);

  // Scroll to bottom of messages
  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages]);

  // Cancel speech synthesis when component unmounts
  useEffect(() => {
    return () => {
      if (speechSynthesisRef.current) {
        window.speechSynthesis.cancel();
      }
    };
  }, []);

  const handleInputChange = (e) => {
    setInput(e.target.value);
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!input.trim()) return;

    // Add user message to chat
    const userMessage = { role: 'user', content: input };
    setMessages([...messages, userMessage]);
    setInput('');
    setIsProcessing(true);

    try {
      // Process with Gemini API
      const assistantResponse = await processWithGemini(input);
      
      // Add assistant response to chat
      setMessages(prev => [...prev, { 
        role: 'assistant', 
        content: assistantResponse,
        highlighted: false
      }]);
    } catch (error) {
      console.error('Error processing request:', error);
      setMessages(prev => [...prev, { 
        role: 'assistant', 
        content: 'I had trouble processing that. Could you try again?',
        highlighted: false
      }]);
    } finally {
      setIsProcessing(false);
    }
  };

  const speakText = (text, messageIndex) => {
    // Stop any ongoing speech
    window.speechSynthesis.cancel();
    
    // Create speech synthesis
    const speech = new SpeechSynthesisUtterance(text);
    speech.rate = 0.9; // Slightly slower rate for better comprehension
    speech.pitch = 1;
    speech.volume = 1;
    
    // Set up word highlighting
    const words = text.split(' ');
    let wordIndex = 0;
    
    speech.onboundary = (event) => {
      if (event.name === 'word' && wordIndex < words.length) {
        // Create a new messages array with the current word highlighted
        const newMessages = [...messages];
        const highlightedText = words.map((word, idx) => 
          idx === wordIndex ? `<span class="highlighted">${word}</span>` : word
        ).join(' ');
        
        newMessages[messageIndex] = {
          ...newMessages[messageIndex],
          content: text,
          highlightedContent: highlightedText,
          highlighted: true
        };
        
        setMessages(newMessages);
        wordIndex++;
      }
    };
    
    speech.onend = () => {
      setIsSpeaking(false);
      
      // Reset highlighting
      const newMessages = [...messages];
      newMessages[messageIndex] = {
        ...newMessages[messageIndex],
        highlighted: false
      };
      setMessages(newMessages);
    };
    
    // Start speaking
    speechSynthesisRef.current = speech;
    window.speechSynthesis.speak(speech);
    setIsSpeaking(true);
  };

  const stopSpeaking = () => {
    window.speechSynthesis.cancel();
    setIsSpeaking(false);
    
    // Reset all highlighting
    const newMessages = messages.map(msg => ({
      ...msg,
      highlighted: false
    }));
    setMessages(newMessages);
  };

  const handleSimplify = async (text, messageIndex) => {
    try {
      setIsProcessing(true);
      
      // Add a loading message
      setMessages(prev => {
        const newMessages = [...prev];
        newMessages[messageIndex] = {
          ...newMessages[messageIndex],
          simplifying: true
        };
        return newMessages;
      });
      
      // Get simplified text from Gemini API
      const simplifiedText = await simplifyText(text);
      
      // Add simplified version as a new message
      setMessages(prev => {
        const newMessages = [...prev];
        // Remove simplifying indicator
        newMessages[messageIndex] = {
          ...newMessages[messageIndex],
          simplifying: false
        };
        
        // Add the simplified message
        return [...newMessages, {
          role: 'assistant',
          content: simplifiedText,
          isSimplified: true,
          originalIndex: messageIndex
        }];
      });
    } catch (error) {
      console.error('Error simplifying text:', error);
      
      // Add error message
      setMessages(prev => [...prev, {
        role: 'assistant',
        content: 'I had trouble simplifying that text. Could you try again?'
      }]);
    } finally {
      setIsProcessing(false);
    }
  };

  return (
    <div className="easyread-container">
      <header className="easyread-header">
        <h1>EasyRead</h1>
        <p>AI Assisted Language & Communication for the Dyslexic Community</p>
        <p className='disclaimer'>This is an inital prototype of this Ai assisted application, this is highly subject to change, it would depend on the professor's or the group's decision</p>
      </header>
      
      <div className="accessibility-controls">
        <div className="control-group">
          <label>Font Size</label>
          <div className="button-controls">
            <button onClick={() => setFontSize(prev => Math.max(12, prev - 2))}>A-</button>
            <span>{fontSize}px</span>
            <button onClick={() => setFontSize(prev => Math.min(32, prev + 2))}>A+</button>
          </div>
        </div>
        
        <div className="control-group">
          <label>Line Spacing</label>
          <div className="button-controls">
            <button onClick={() => setLineSpacing(prev => Math.max(1, prev - 0.25))}>-</button>
            <span>{lineSpacing}x</span>
            <button onClick={() => setLineSpacing(prev => Math.min(3, prev + 0.25))}>+</button>
          </div>
        </div>
        
        <div className="control-group">
          <label>Font</label>
          <select 
            value={fontFamily} 
            onChange={(e) => setFontFamily(e.target.value)}
          >
            <option value="OpenDyslexic">OpenDyslexic</option>
            <option value="Arial">Arial</option>
            <option value="Comic Sans MS">Comic Sans MS</option>
            <option value="Verdana">Verdana</option>
          </select>
        </div>
      </div>
      
      <div 
        className="messages-container"
        style={{ 
          fontSize: `${fontSize}px`, 
          lineHeight: `${lineSpacing}`, 
          fontFamily: fontFamily 
        }}
      >
        {messages.length === 0 ? (
          <div className="welcome-message">
            <h2>Welcome to EasyRead!</h2>
            <p>Hello! I'm EasyRead, an app to help with reading. I can read text aloud, highlight words, and explain tricky words. I can also make the text simpler. Would you like me to read something for you?</p>
            <p>How can I help you today?</p>
          </div>
        ) : (
          messages.map((message, index) => (
            <div 
              key={index} 
              className={`message ${message.role === 'user' ? 'user-message' : 'assistant-message'} ${message.isSimplified ? 'simplified-message' : ''}`}
            >
              <div className="message-content">
                {message.isSimplified && <div className="simplified-tag">Simplified</div>}
                
                {message.role === 'assistant' && message.highlighted && message.highlightedContent ? (
                  <div dangerouslySetInnerHTML={{ __html: message.highlightedContent }} />
                ) : (
                  <p>{message.content}</p>
                )}
                
                {message.simplifying && (
                  <div className="simplifying-indicator">
                    Simplifying text...
                  </div>
                )}
              </div>
              
              {message.role === 'assistant' && !message.simplifying && (
                <div className="message-actions">
                  {isSpeaking ? (
                    <button 
                      className="action-button stop-button" 
                      onClick={stopSpeaking}
                      disabled={isProcessing}
                    >
                      Stop Reading
                    </button>
                  ) : (
                    <button 
                      className="action-button read-button" 
                      onClick={() => speakText(message.content, index)}
                      disabled={isProcessing}
                    >
                      Read Aloud
                    </button>
                  )}
                  
                  {!message.isSimplified && (
                    <button 
                      className="action-button simplify-button"
                      onClick={() => handleSimplify(message.content, index)}
                      disabled={isProcessing}
                    >
                      Simplify
                    </button>
                  )}
                </div>
              )}
            </div>
          ))
        )}
        <div ref={messagesEndRef} />
      </div>
      
      <form className="input-form" onSubmit={handleSubmit}>
        <textarea
          value={input}
          onChange={handleInputChange}
          placeholder="Ask for help or paste text here..."
          rows="3"
          style={{ 
            fontSize: `${fontSize}px`, 
            lineHeight: `${lineSpacing}`, 
            fontFamily: fontFamily 
          }}
        />
        <button 
          type="submit" 
          disabled={isProcessing || !input.trim()}
        >
          {isProcessing ? 'Processing...' : 'Send'}
        </button>
      </form>
    </div>
  );
};

export default EasyRead;