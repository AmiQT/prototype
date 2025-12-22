
import { GoogleGenerativeAI } from "@google/generative-ai";

export interface ActionPlan {
    studentId: string;
    riskLevel: string;
    recommendations: string[];
    interventionPlan: string;
}

export interface ActionPlanResult {
    success: boolean;
    plan?: ActionPlan;
    error?: string;
}

class GeminiService {
    private genAI: GoogleGenerativeAI;
    private model: any;

    constructor() {
        const apiKey = import.meta.env.PUBLIC_GEMINI_API_KEY;
        if (!apiKey) {
            console.warn("Gemini API Key not found. AI features will be disabled.");
            this.genAI = new GoogleGenerativeAI("dummy_key"); // Prevent crash on init
        } else {
            this.genAI = new GoogleGenerativeAI(apiKey);
        }
        this.model = this.genAI.getGenerativeModel({ model: "gemini-2.5-flash" });
    }

    async generateActionPlan(studentData: any): Promise<ActionPlanResult> {
        const apiKey = import.meta.env.PUBLIC_GEMINI_API_KEY;

        if (!apiKey) {
            console.error("Gemini API Key is missing.");
            return { success: false, error: "Missing API Key. Please check .env file and restart server." };
        }

        try {
            // Extract data from prediction result
            const riskLevel = studentData.risk_level || "UNKNOWN";
            const riskFactors = studentData.risk_factors || [];
            const strengths = studentData.strengths || [];
            const metrics = studentData.performance_metrics || {};
            const confidence = studentData.confidence || 0;

            const prompt = `
                Anda adalah penasihat akademik universiti Malaysia. Analisis data pelajar dan beri pelan tindakan ringkas.
                
                Data Pelajar:
                - ID: ${studentData.student_id}
                - Tahap Risiko: ${riskLevel}
                - Skor Risiko: ${(studentData.risk_score * 100).toFixed(1)}%
                - Keyakinan: ${(confidence * 100).toFixed(0)}%
                - Kekuatan: ${strengths.length > 0 ? strengths.join(", ") : "Tiada data"}
                - Faktor Risiko: ${riskFactors.length > 0 ? riskFactors.join(", ") : "Tiada isu"}
                - Metrik: CGPA=${metrics.cgpa_normalized?.toFixed(2) || "N/A"}, Koku=${metrics.koku_normalized?.toFixed(2) || "N/A"}

                ARAHAN:
                1. Respons dalam Bahasa Melayu
                2. Fokus HANYA pada prestasi akademik (CGPA) dan kokurikulum
                3. Beri 2-3 cadangan praktikal sahaja
                4. Jangan sebut "0 CGPA" atau "0% attendance" - guna data sebenar di atas

                Beri respons JSON:
                {
                    "recommendations": ["cadangan1", "cadangan2"],
                    "interventionPlan": "Ringkasan pelan tindakan dalam 1-2 ayat."
                }
                Return ONLY valid JSON.
            `;

            const result = await this.model.generateContent(prompt);
            const response = await result.response;
            const text = response.text();

            // Clean up markdown code blocks if present
            const jsonStr = text.replace(/```json/g, "").replace(/```/g, "").trim();
            const parsed = JSON.parse(jsonStr);

            return {
                success: true,
                plan: {
                    studentId: studentData.student_id,
                    riskLevel: studentData.risk_level,
                    recommendations: parsed.recommendations || [],
                    interventionPlan: parsed.interventionPlan || "No plan generated."
                }
            };

        } catch (error: any) {
            console.error("Error generating AI action plan:", error);
            return { success: false, error: error.message || "Failed to generate plan." };
        }
    }
}

export const geminiService = new GeminiService();
