# EasyRead - Dyslexia Support App

EasyRead is a Flutter-based mobile application designed to assist students with dyslexia by providing real-time text simplification, explanations, and summaries. It also includes text-to-speech functionality and word highlighting for better reading comprehension.

## Features
- Text-to-Speech with adjustable speed
- Text Simplification
- Text Explanation
- Text Summarization
- Chat History with Tags
- Accessibility Settings (Font, Size, Line Spacing, etc.)
- Light and Dark Mode Support

## Prerequisites
Ensure you have the following installed:
- Flutter SDK: [Download Flutter](https://docs.flutter.dev/get-started/install)
- Android Studio or Visual Studio Code
- Google Cloud API Access with Gemini API enabled

## Setup Instructions

1. **Clone the Repository:**
```bash
git clone https://github.com/your-username/easyread.git
cd easyread
```
Install Dependencies:
bash

2. **Install Dependencies:**
```
flutter pub get
```
3. **Configure API KEY:**
```
- Create a .env file in the root directory.
- Add your API key:
```
API_KEY.env
```
API_KEY=your_google_api_key
```
- Ensure the API is enabled in your Google Cloud Console.
4. **Run the Application:**
```
flutter run
```

## Usage
- Ask: Provide simple answers to general questions.
- Simplify: Converts complex text into easier-to-read content.
- Explain: Explains the meaning of a given text.
- Summarize: Summarizes text to extract key points.

##Troubleshooting
- If you encounter a `404` or `API error`, ensure the API key is correct and the API is enabled.
Run `flutter doctor` to check if your environment is set up correctly.

# Enjoy using EasyRead and support inclusive learning!
