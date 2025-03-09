import os
import io
import re
import warnings
from flask import Flask, request, jsonify
from google.cloud import documentai_v1 as documentai
from fuzzywuzzy import process

warnings.filterwarnings("ignore", category=UserWarning)  # Suppress fuzzywuzzy warnings

# Modify the uploads folder path to be absolute
UPLOAD_FOLDER = "/app/uploads"  # Changed from relative path

app = Flask(__name__)

# 🔹 Google Cloud Configurations
PROJECT_ID = "prescription-451914"
PROCESSOR_ID = "4bd246b055005fa5"
LOCATION = "us"
UPLOAD_FOLDER = "uploads"
os.makedirs(UPLOAD_FOLDER, exist_ok=True)

# ✅ Predefined list of recognized drug names & medical instructions
DRUG_LIST = [
    "Lipitor", "Ibuprofen", "Aspirin", "Amoxicillin", "Metformin",
    "Losartan", "Omeprazole", "Atorvastatin", "Simvastatin",
    "Hydrochlorothiazide", "Allergy", "Paracetamol", "AstraZeneca", 
    "Cancer", "1 tab a day", "Take 1 tablet daily", "Twice a day",
    "Every 8 hours", "Before meals", "After meals", "With water"
]

def extract_text_from_image(image_path, mime_type):
    """Extract text from an image using Google Document AI."""
    client = documentai.DocumentProcessorServiceClient()
    name = f"projects/{PROJECT_ID}/locations/{LOCATION}/processors/{PROCESSOR_ID}"
    
    with io.open(image_path, "rb") as image_file:
        image_content = image_file.read()
    
    raw_document = documentai.RawDocument(content=image_content, mime_type=mime_type)
    request = documentai.ProcessRequest(name=name, raw_document=raw_document)
    response = client.process_document(request=request)
    document = response.document
    return document.text.strip()

def clean_text(text):
    """Remove unwanted symbols while keeping relevant medical data."""
    text = re.sub(r"[^a-zA-Z0-9\s\-\/]+", "", text)  # Remove special characters except - and /
    text = re.sub(r"\s+", " ", text).strip()  # Remove extra spaces
    return text

def correct_drug_names(text, drug_list):
    """Correct drug names while keeping unrelated words unchanged."""
    words = text.split()
    corrected_words = []

    for word in words:
        if word in drug_list:
            corrected_words.append(word)
        else:
            best_match, score = process.extractOne(word, drug_list) if word.isalpha() else (word, 0)
            corrected_words.append(best_match if score >= 85 else word)
    
    return " ".join(corrected_words)

@app.route('/upload', methods=['POST'])
def upload_file():
    """Handle image upload and process text extraction."""
    if 'image' not in request.files:
        return jsonify({"error": "No image file found"}), 400

    image = request.files['image']
    file_extension = os.path.splitext(image.filename)[1].lower()
    
    if file_extension not in ['.png', '.jpg', '.jpeg']:
        return jsonify({"error": "Unsupported file format. Please upload PNG or JPG."}), 400

    mime_type = "image/png" if file_extension == ".png" else "image/jpeg"
    image_path = os.path.join(UPLOAD_FOLDER, image.filename)
    image.save(image_path)

    try:
        extracted_text = extract_text_from_image(image_path, mime_type)
        cleaned_text = clean_text(extracted_text)
        final_text = correct_drug_names(cleaned_text, DRUG_LIST)
        
        return jsonify({
            "recognized_text": extracted_text,
            "corrected_text": final_text
        })
    except Exception as e:
        return jsonify({"error": f"Processing failed: {str(e)}"}), 500

if __name__ == '__main__':
    port = int(os.environ.get("PORT", 8080))
    app.run(host='0.0.0.0', port=port, debug=True)