
export interface RiskPrediction {
    student_id: string;
    risk_level: 'HIGH' | 'MEDIUM' | 'LOW';
    risk_score: number;
    confidence: number;
    current_cgpa: number;
    attendance_rate: number;
    risk_factors: string[];
    strengths: string[];
    recommendations: string[];
    gemini_insights?: {
        risk_score: number;
        confidence: number;
        recommendations: string[];
    };
}

export interface MLHealthStatus {
    success: boolean;
    model?: string;
    version?: string;
    lastCheck?: Date;
    error?: string;
}

class MLAnalyticsService {
    private baseUrl: string;

    constructor() {
        this.baseUrl = import.meta.env.PUBLIC_BACKEND_URL || "https://infrared-booth-auckland-prevention.trycloudflare.com";
    }

    async checkHealth(): Promise<MLHealthStatus> {
        try {
            const response = await fetch(`${this.baseUrl}/api/ml/health`);
            if (!response.ok) throw new Error("Health check failed");

            const data = await response.json();
            return {
                success: data.status === "healthy",
                model: data.model || "Unknown",
                lastCheck: new Date()
            };
        } catch (error) {
            console.error("ML Service Health Check Failed:", error);
            return {
                success: false,
                model: "Offline",
                lastCheck: new Date()
            };
        }
    }

    async batchPredict(studentIds: string[]): Promise<{ success: boolean; data?: { results: RiskPrediction[] }; error?: string }> {
        try {
            const response = await fetch(`${this.baseUrl}/api/ml/batch/predict`, {
                method: "POST",
                headers: {
                    "Content-Type": "application/json",
                },
                body: JSON.stringify({ student_ids: studentIds }),
            });

            if (!response.ok) {
                const errorData = await response.json();
                throw new Error(errorData.detail || "Batch prediction failed");
            }

            const data = await response.json();
            return {
                success: true,
                data: {
                    results: data.results.map((r: any) => ({
                        student_id: r.student_id,
                        risk_score: r.risk_score,
                        risk_level: r.risk_level ? r.risk_level.toUpperCase() : 'LOW',
                        confidence: r.confidence,
                        risk_factors: r.risk_factors || [],
                        strengths: r.strengths || [],
                        recommendations: r.recommendations || [],
                        current_cgpa: r.current_cgpa || 0,
                        attendance_rate: r.attendance_rate || 0,
                        gemini_insights: r.gemini_insights
                    }))
                }
            };
        } catch (error: any) {
            console.error("Batch Prediction Failed:", error);
            return {
                success: false,
                error: error.message || "Failed to connect to ML Service"
            };
        }
    }

    formatRiskScore(score: number) {
        if (score >= 0.7) {
            return { level: 'HIGH', color: 'red', icon: '🔴', bgClass: 'bg-red-100 text-red-800' };
        } else if (score >= 0.4) {
            return { level: 'MEDIUM', color: 'yellow', icon: '🟡', bgClass: 'bg-yellow-100 text-yellow-800' };
        } else {
            return { level: 'LOW', color: 'green', icon: '🟢', bgClass: 'bg-green-100 text-green-800' };
        }
    }
}

export const mlAnalyticsService = new MLAnalyticsService();
