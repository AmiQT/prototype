## 5.3 Backend & Intelligent Architecture

This section documents the implementation of the backend infrastructure, built using FastAPI (Python). It serves as the central intelligence engine, handling data processing, machine learning inference, and seamless integration with the Supabase database.

---

### 5.3.1 FastAPI Architecture & Entry Point

**Purpose:** The backend core is designed for high performance and scalability. It utilizes FastAPI's asynchronous capabilities to handle concurrent requests efficiently. The architecture includes comprehensive middleware for CORS protection, logging, and health monitoring, ensuring robust operation in production environments.

**Code Snippet:**

```python
# Initialize FastAPI app with cloud-friendly configuration
app = FastAPI(
    title="Student Talent Analytics API",
    description="Hybrid backend for student talent profiling system",
    version="1.0.0"
)

# CORS middleware - Dynamic Origin Handling
raw_origins = os.getenv("ALLOWED_ORIGINS", "").split(",")
allowed_origins = [origin.strip() for origin in raw_origins if origin.strip()]

app.add_middleware(
    CORSMiddleware,
    allow_origins=allowed_origins,
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
    allow_headers=["*"],
    max_age=3600,
)

# Health check endpoint for system monitoring
@app.get("/health")
async def health_check(db: Session = Depends(get_db)):
    try:
        # Test database connection
        result = db.execute(text("SELECT 1")).scalar()
        db_status = "connected" if result == 1 else "error"
        
        return {
            "status": "healthy" if db_status == "connected" else "degraded",
            "services": {
                "api": "running",
                "database": db_status,
                "cloudinary": "configured"
            }
        }
    except Exception as e:
        return {"status": "error", "error": str(e)}
```

The main application file acts as the gateway for all system operations. It configures the server environment, loads critical environmental variables, and dynamically manages Cross-Origin Resource Sharing (CORS) policies to allow secure access from both web and mobile clients. The implementation includes a robust health check mechanism that continuously validates database connectivity and service availability.

---

### 5.3.2 Asynchronous Database Connection

**Purpose:** A robust database connection layer is implemented to manage interactions with Supabase. It employs connection pooling and asynchronous drivers to maximize throughput and prevent connection exhaustion during high-load periods.

**Code Snippet:**

```python
# SQLAlchemy setup with transaction pooler configuration
engine = create_engine(
    DATABASE_URL,
    pool_size=5,
    max_overflow=10,
    pool_pre_ping=True,  # Important for transaction pooler
    pool_recycle=3600,   # Recycle connections every hour
    connect_args={"sslmode": "require"}
)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Async database connection abstraction
database = Database(DATABASE_URL)

async def connect_db():
    """Connect to the database"""
    await database.connect()
    logger.info("✅ Database connected successfully")

async def disconnect_db():
    """Disconnect from the database"""
    await database.disconnect()
    logger.info("❌ Database disconnected")
```

The database configuration module utilizes SQLAlchemy with advanced connection pooling settings. The implementation specific parameters like `pool_pre_ping` and `pool_recycle` are crucial for maintaining stable connections in a cloud environment, automatically recovering from stale connections without downtime.

---

### 5.3.3 Machine Learning Engine (Risk Prediction)

**Purpose:** This module implements the core intelligence of the system. It processes student data to predict academic risk levels. The logic combines rule-based feature engineering with AI-driven validation (via Gemini), providing a hybrid prediction model that is both explainable and accurate.

**Code Snippet:**

```python
async def predict_student_risk(self, student_data: Dict[str, Any]) -> Dict[str, Any]:
    # Check cache first to reduce latency and API costs
    cached = self.cache.get(f"prediction_{student_id}")
    if cached:
        return cached

    # 1. Feature Engineering
    features = self.data_processor.extract_student_features(student_data)
    
    # 2. Local Risk Calculation
    risk_score = self.feature_engineer.calculate_risk_score(features)
    risk_factors = self.feature_engineer.get_risk_factors(features)
    
    # 3. Hybrid Analysis (Local + AI)
    final_prediction = self.feature_engineer.generate_summary(
        student_id=student_id,
        features=features,
        risk_score=risk_score,
        risk_factors=risk_factors,
        recommendations=recommendations,
    )

    # 4. Cache Result
    self.cache.set(f"prediction_{student_id}", final_prediction)
    
    return final_prediction
```

The prediction engine encapsulates the complex logic of student assessment. It follows a multi-stage pipeline: extracting features from raw data, calculating a preliminary risk score using deterministic rules, and then generating a comprehensive summary. The inclusion of a caching layer (`CacheManager`) significantly optimizes performance by retrieving recent predictions instantly.

---

### 5.3.4 AI Action Plan Generator

**Purpose:** This service generates personalized intervention plans for students. It constructs context-aware prompts based on the student's specific risk factors and academic performance, then leverages the Large Language Model (LLM) to prescribe actionable advice.

**Code Snippet:**

```python
async def _generate_ai_plan(
    self, 
    student_data: Dict[str, Any],
    analysis: Dict[str, Any]
) -> Dict[str, Any]:
    """Generate AI-powered action plan using Gemini."""
    
    metrics = analysis["metrics"]
    issues = analysis["issues"]
    
    # Dynamic Prompt Construction
    prompt = f"""Anda adalah penasihat akademik universiti Malaysia.
    
    PELAJAR: {student_name}
    CGPA: {cgpa}
    SKOR AKADEMIK: {metrics['academic_score']:.0f}%
    ISU: {issues_text}
    
    ARAHAN PENTING:
    1. Respons MESTI dalam format JSON yang valid
    2. Beri HANYA 2 tindakan sahaja
    
    Format JSON:
    {{"ringkasan":"...","pelan":[{{"tindakan":"...","sebab":"..."}}]}}"""
    
    # Async LLM Call
    response = await self.model.generate_content_async(prompt)
    
    return self._parse_ai_response(response.text)
```

The action plan generator demonstrates the practical application of Agentic AI. By dynamically injecting student-specific data (CGPA, issues, activity scores) into the system description, it forces the AI to act as a contextual "Academic Advisor." The strict JSON output formatting ensures the generated advice can be parsed and displayed structurally in the user interface.

---

### 5.3.5 API Endpoints (ML Router)

**Purpose:** This router exposes the machine learning capabilities to the frontend. It handles incoming HTTP requests, performs input validation, and manages the batch processing of student data for bulk analytics.

**Code Snippet:**

```python
@router.post("/batch/predict")
async def batch_predict(body: dict = None, db: Session = Depends(get_db)):
    """Batch predict risk for multiple students"""
    
    student_ids = body.get("student_ids", [])
    logger.info(f"Starting batch prediction for {len(student_ids)} students")
    
    # Efficient Data Loading
    students_data = []
    for sid in student_ids:
        profile = db.query(Profile).filter(Profile.student_id == sid).first()
        if profile:
            # Structuring data for predictor
            students_data.append({
                "id": str(profile.id),
                "cgpa": float(profile.cgpa),
                "kokurikulum_score": float(profile.kokurikulum_score),
            })
    
    # Asynchronous Batch Processing
    predictions = await predictor.batch_predict(students_data)
    
    return {
        "status": "success",
        "total": len(student_ids),
        "results": predictions,
    }
```

The API implementation highlights the separation of concerns. The router focuses on request handling and data marshaling, while delegating the heavy lifting to the services. The batch prediction endpoint is particularly important for the "Analytics Dashboard," enabling the system to evaluate entire cohorts of students in a single request transaction.

---

### 5.3.6 Agentic AI v2 (LangGraph Architecture)

**Purpose:** This module represents the next-generation AI assistant logic. Instead of simple request-response loops, it utilizes a state graph architecture (LangGraph) to manage complex, multi-turn conversations. It allows the AI to maintain context (memory), decide when to call external tools, and route the conversation flow dynamically based on user intent.

**Code Snippet:**

```python
def _build_graph(self) -> StateGraph:
    """Build the LangGraph agent workflow."""
    
    # Define the agent node
    def call_model(state: MessagesState):
        messages = state["messages"]
        response = self.llm_with_tools.invoke(messages)
        return {"messages": [response]}
    
    # Define dynamic routing logic
    def should_continue(state: MessagesState):
        last_message = state["messages"][-1]
        
        # If the model requests a tool call, route to 'tools' node
        if hasattr(last_message, 'tool_calls') and last_message.tool_calls:
            return "tools"
        
        # Otherwise, end the workflow
        return END
    
    # Construct the StateGraph
    builder = StateGraph(MessagesState)
    builder.add_node("agent", call_model)
    builder.add_node("tools", ToolNode(self.tools))
    
    # Define edges & loop
    builder.add_edge(START, "agent")
    builder.add_conditional_edges("agent", should_continue, ["tools", END])
    builder.add_edge("tools", "agent")  # Loop back for reasoning
    
    # Compile with persistence
    checkpointer = MemorySaver()
    return builder.compile(checkpointer=checkpointer)
```

The code implements a `StateGraph` that defines the cognitive architecture of the AI agent. It uses a cyclical graph where the agent can "reason" (call_model), "act" (execute tools), and observe the results in a loop until it satisfies the user's request. This architecture enables sophisticated behaviors like clarifying ambiguous queries or chaining multiple database lookups to answer a complex question.

---

### 5.3.7 Malay NLP Engine

**Purpose:** To cater to the local demographic, a specialized Natural Language Processing (NLP) engine is implemented. This module handles the nuances of Bahasa Melayu, including stemming (root word extraction), stopword removal, and entity recognition, ensuring that user queries in Malay are accurately understood by the system.

**Code Snippet:**

```python
class MalayNLPProcessor:
    """NLP processor optimized for Bahasa Melayu."""
    
    def normalize(self, text: str) -> str:
        """
        Normalize Malay text (fix common shortforms).
        """
        replacements = {
            r'\bmcm\b': 'macam',
            r'\bxnak\b': 'tidak mahu',
            r'\bx\b': 'tidak',
            r'\btp\b': 'tetapi',
            r'\bdgn\b': 'dengan',
            r'\byg\b': 'yang',
            r'\bnk\b': 'nak',
        }
        
        result = text
        for pattern, replacement in replacements.items():
            result = re.sub(pattern, replacement, result, flags=re.IGNORECASE)
        
        return result
        
    def extract_intent(self, text: str) -> Dict[str, Any]:
        """
        Extract user intent from Malay text using keyword matching.
        """
        detected_intents = []
        
        for intent, keywords in self.intent_keywords.items():
            for keyword in keywords:
                if keyword in text.lower():
                    detected_intents.append({
                        "intent": intent,
                        "keyword": keyword
                    })
        
        primary_intent = detected_intents[0]["intent"] if detected_intents else "unknown"
        
        return {"primary_intent": primary_intent}
```

The `MalayNLPProcessor` class contains custom logic for normalizing informal Malay text (e.g., converting SMS language like "xnak" to "tidak mahu"). This pre-processing step is critical for improving the accuracy of the intent classification system, allowing students to interact naturally with the AI using colloquial language.

---

### 5.3.8 RAG Knowledge Base Architecture

**Purpose:** The Retrieval-Augmented Generation (RAG) system grounds the AI's responses in factual university data. It combines vector semantic search (to find relevant documents) with the generative capabilities of the LLM, ensuring that answers about university policies or curriculum are accurate and up-to-date.

**Code Snippet:**

```python
def query(self, question: str) -> Dict[str, Any]:
    """Query the RAG system."""
    
    # 1. Retrieve relevant documents from Vector Store
    docs = self._vectorstore.similarity_search(question, k=5)
    
    # 2. Construct RAG Context
    context = "\n\n".join(doc.page_content for doc in docs)
    
    # 3. Generate Answer using Chain
    template = """Anda adalah pembantu AI universiti.
    
    Konteks yang berkaitan:
    {context}
    
    Soalan pengguna: {question}
    
    Arahan: Jawab dalam Bahasa Melayu berdasarkan konteks sahaja."""
    
    prompt = ChatPromptTemplate.from_template(template)
    
    rag_chain = (
        {"context": lambda x: context, "question": RunnablePassthrough()}
        | prompt
        | self._llm
        | StrOutputParser()
    )
    
    return {
        "answer": rag_chain.invoke(question),
        "sources": [d.metadata for d in docs]
    }
```

This RAG implementation demonstrates the integration of a vector database (`ChromaDB`) with the LLM pipeline. When a user asks a question, the system first retrieves the most relevant "chunks" of information from its knowledge base. These chunks provide the "context" for the AI, strictly limiting its response to verified information and reducing the risk of hallucination.

---

*End of Section 5.3 - Backend Implementation*
