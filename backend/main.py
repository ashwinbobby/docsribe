from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import List, Optional
import ollama
import json

# 1. Define the Data Models
class Medicine(BaseModel):
    medicine_name: str
    duration: str
    frequency: str
    timing: str
    food_relation: str

class PrescriptionResponse(BaseModel):
    medicines: List[Medicine]

class STTRequest(BaseModel):
    transcript: str

# 2. Initialize FastAPI
app = FastAPI(title="DocScribe LLM Engine")

# 3. The Extraction Endpoint
@app.post("/extract-medicines", response_model=PrescriptionResponse)
async def extract_medicines(request: STTRequest):
    if not request.transcript.strip():
        raise HTTPException(status_code=400, detail="Transcript is empty")

    # System prompt specifically asking for a JSON object with a 'medicines' key
    system_prompt = """You are a medical prescription extraction engine.

Your only job is to read a doctor's transcribed speech and extract every medicine mentioned.

## Output format
Return ONLY a raw JSON object. No explanation. No markdown. No code fences. No extra text.
The object must have exactly one key: "medicines", which is an array.

Each item in the array must have EXACTLY these keys:
- "medicine_name"  : name of the medicine, properly capitalized
- "duration"       : how many days/weeks to take it (e.g. "5 days", "1 month", "3 weeks")
- "frequency"      : how many times per day (e.g. "once a day", "twice a day", "thrice a day", "as needed")
- "timing"         : when to take it (e.g. "morning", "night", "morning and night", "morning, afternoon and night")
- "food_relation"  : "before food", "after food", or "with food"

## Inference rules (IMPORTANT)
If any field is NOT explicitly stated in the transcript, infer it using standard medical knowledge:

ANTACIDS / PPI:
- Pantoprazole, Omeprazole, Rabeprazole, Esomeprazole → before food, morning, once a day, 1 month
- Ranitidine, Famotidine → before food, twice a day

ANTIBIOTICS:
- Amoxicillin, Augmentin, Azithromycin, Doxycycline, Cefix, Cefpodoxime → after food
- Azithromycin → once a day, 3-5 days
- Amoxicillin, Augmentin → twice a day or thrice a day, 5-7 days

PAIN / FEVER:
- Paracetamol, Dolo, Calpol → after food, as needed or thrice a day
- Ibuprofen, Combiflam → after food, thrice a day, not more than 3 days

DIABETES:
- Metformin → after food, twice a day
- Glimepiride → before food, once a day (morning)

ALLERGY / COLD:
- Cetirizine, Levocetirizine → after food, once a day, night
- Chlorpheniramine → after food, thrice a day

VITAMINS / SUPPLEMENTS:
- Vitamin D3, Calcium, Vitamin B12 → after food, once a day or once a week

STEROIDS:
- Prednisolone, Methylprednisolone → after food, morning

THYROID:
- Levothyroxine, Thyronorm, Eltroxin → before food, morning, once a day

HEART / BP:
- Amlodipine → after food, once a day
- Atorvastatin, Rosuvastatin → after food, night, once a day
- Aspirin (low dose) → after food, once a day

If the medicine is not in this list, use your best clinical knowledge to infer.
Never leave a field blank or say "not specified" — always infer a reasonable value.

## Noise handling
The input is transcribed speech from a doctor. It may contain:
- Filler words ("uhh", "okay", "so", "like")
- Repeated words or phrases
- Mispronounced or misspelled medicine names — correct them to the standard name
- Dosage mentioned separately (e.g. "40mg") — include it in medicine_name

## Edge cases
- If no medicines are found: return {"medicines": []}
- Do NOT invent medicine names that were not mentioned
- Do NOT add any field other than the five specified
- Do NOT repeat the same medicine twice

## Example output
{
  "medicines": [
    {
      "medicine_name": "Pantoprazole 40mg",
      "duration": "1 month",
      "frequency": "once a day",
      "timing": "morning",
      "food_relation": "before food"
    },
    {
      "medicine_name": "Metformin 500mg",
      "duration": "1 month",
      "frequency": "twice a day",
      "timing": "morning and night",
      "food_relation": "after food"
    }
  ]
}"""

    try:
        # Ping your local Ollama instance
        response = ollama.chat(
            model='qwen2.5-coder:7b',
            messages=[
                {'role': 'system', 'content': system_prompt},
                {'role': 'user', 'content': request.transcript}
            ],
            format='json', # This forces Ollama to output valid JSON
            options={'temperature': 0.1} # Keeps the model focused and factual
        )
        
        # Parse the JSON string returned by Ollama
        parsed_data = json.loads(response['message']['content'])
        
        # Return it (FastAPI and Pydantic will validate it matches PrescriptionResponse)
        return parsed_data
        
    except json.JSONDecodeError:
        raise HTTPException(status_code=500, detail="Failed to parse JSON from the model.")
    except Exception as e:
        # Catches errors if Ollama isn't running
        raise HTTPException(status_code=500, detail=f"Ollama Error: {str(e)}. Make sure Ollama is running in the background!")