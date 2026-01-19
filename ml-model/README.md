#  Organization Butler – Room Image Analysis (ML)

## 📌 Overview
Organization Butler is a computer vision–based system that analyzes a room image, detects clutter-related objects, computes a **messiness score**, and classifies the room condition to generate intelligent organization recommendations.

This repository contains the **Machine Learning module** responsible for object detection, clutter scoring, and structured ML output.

---

## 🎯 Objective
Given a single room image:
1. Detect clutter-related objects  
2. Quantify clutter into a messiness score (0–100)  
3. Classify room condition (Clean → Very Messy)  
4. Provide structured output for backend integration  

---

```🏗️ ML Pipeline
Room Image -> Preprocessing -> Object Detection (YOLO) -> Detected Objects -> Clutter Scoring Logic -> Messiness Score + Room State -> JSON Output
```

## 🧾 Dataset

### Room Types
- Bedroom
- Study Room
- Living Room

### Object Classes
- door
- openedDoor
- chair
- table
- cabinet
- sofa
- window
- refrigeratorDoor

### Annotation Tools
- Roboflow
- LabelImg

### Split
- Train: 80%
- Validation: 20%

---

## 🤖 Model

- **Architecture**: YOLOv8 (Object Detection)
- **Why YOLO**:
  - Real-time inference
  - High accuracy for indoor scenes
  - Lightweight & deployable

### Metrics
- Precision
- Recall
- mAP@0.5

---

## 🧮 Clutter / Messiness Scoring

### Factors
- Number of detected objects
- Object-specific weights
- Object distribution (optional)

### Example Weights
```python
weights = {
  "clothes": 5,
  "books": 3,
  "cables": 4,
  "chair": 2,
  "table": 1,
  "cabinet": 1
}

Room State Mapping
Score	State
0–20	Clean
21–40	Slightly Messy
41–70	Messy
71–100	Very Messy

📤 Output Format
{
  "objects": [
    { "class": "chair", "count": 2 },
    { "class": "cabinet", "count": 3 },
    { "class": "door", "count": 1 }
  ],
  "messiness_score": 65,
  "room_state": "Messy"
}
```
### ⚙️ Inference Flow

- Input image
- Preprocessing
- YOLO inference
- Object extraction 
- Scoring logic
- JSON response

### 📦 Deliverables

- Trained YOLO model
- Clutter scoring module
- Inference script
- JSON output
- Integration documentation
- 
### 🔗 Backend Integration

- Image sent from backend to ML service
- ML returns structured JSON
- Backend converts output to organization plan

### 🚀 Future Scope

- Add more clutter classes
- Improve spatial analysis
- Fine-tune with user data
- Room-type classification
- FastAPI deployment
### 👥 ML Team
- Mahek
- Hirdesh

### 📜 License

Educational and prototype use.
