#!/bin/bash

# Resume PDF Generator using Chrome Headless with Local Server
# This script starts a local server, generates a clean PDF, then stops the server

echo "🚀 Starting PDF generation with Chrome..."

# Check if Chrome is installed
CHROME_PATH="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
if [ ! -f "$CHROME_PATH" ]; then
    echo "❌ Google Chrome not found at: $CHROME_PATH"
    echo "Please install Google Chrome or update the CHROME_PATH in this script"
    exit 1
fi

# Get the current directory
CURRENT_DIR=$(pwd)
HTML_FILE="$CURRENT_DIR/index.html"
JSON_FILE="$CURRENT_DIR/experience.json"

# Check if required files exist
if [ ! -f "$HTML_FILE" ]; then
    echo "❌ HTML file not found: $HTML_FILE"
    echo "Please run this script from the directory containing index.html"
    exit 1
fi

if [ ! -f "$JSON_FILE" ]; then
    echo "❌ JSON file not found: $JSON_FILE"
    echo "Please ensure experience.json exists in the current directory"
    exit 1
fi

echo "📄 Using HTML file: $HTML_FILE"
echo "📄 Using JSON file: $JSON_FILE"
echo "🌐 Chrome path: $CHROME_PATH"

# Check if port 8000 is available
if lsof -Pi :8000 -sTCP:LISTEN -t >/dev/null ; then
    echo "⚠️  Port 8000 is already in use. Trying to use existing server..."
    SERVER_STARTED=false
else
    echo "🌐 Starting local HTTP server on port 8000..."
    # Start Python HTTP server in background
    python3 -m http.server 8000 > /dev/null 2>&1 &
    SERVER_PID=$!
    SERVER_STARTED=true

    # Wait for server to start
    echo "⏳ Waiting for server to start..."
    sleep 2

    # Check if server started successfully
    if ! lsof -Pi :8000 -sTCP:LISTEN -t >/dev/null ; then
        echo "❌ Failed to start HTTP server on port 8000"
        exit 1
    fi
    echo "✅ Server started successfully (PID: $SERVER_PID)"
fi

# Generate PDF with Chrome headless using localhost
echo "📄 Generating PDF from http://localhost:8000..."
"$CHROME_PATH" \
    --headless \
    --disable-gpu \
    --run-all-compositor-stages-before-draw \
    --disable-background-timer-throttling \
    --disable-renderer-backgrounding \
    --disable-features=TranslateUI \
    --disable-ipc-flooding-protection \
    --print-to-pdf=resume.pdf \
    --print-to-pdf-no-header \
    --no-pdf-header-footer \
    --disable-pdf-tagging \
    --virtual-time-budget=8000 \
    "http://localhost:8000/index.html"

# Stop the server if we started it
if [ "$SERVER_STARTED" = true ]; then
    echo "🛑 Stopping HTTP server..."
    kill $SERVER_PID 2>/dev/null
    wait $SERVER_PID 2>/dev/null
    echo "✅ Server stopped"
fi

# Check if PDF was generated successfully
if [ -f "resume.pdf" ]; then
    PDF_SIZE=$(stat -f%z "resume.pdf" 2>/dev/null || stat -c%s "resume.pdf" 2>/dev/null)
    echo "✅ PDF generated successfully!"
    echo "📁 File: resume.pdf"
    echo "📊 Size: $PDF_SIZE bytes"
    
    # Optional: Open the PDF (uncomment the line below if you want to auto-open)
    # open resume.pdf
else
    echo "❌ PDF generation failed!"
    echo "Please check the console output above for errors"
    exit 1
fi

echo "🎉 Done! Your resume PDF is ready."
