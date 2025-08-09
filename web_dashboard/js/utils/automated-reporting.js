import { dataFetcher } from './analytics-data-fetcher.js';
import { comparativeAnalysis } from './comparative-analysis.js';
import { securityManager } from './security-manager.js';

/**
 * Automated reporting system for scheduled analytics reports
 */
export class AutomatedReporting {
    constructor() {
        this.reportSchedules = new Map();
        this.reportTemplates = new Map();
        this.reportHistory = [];
        this.isRunning = false;
        
        this.initializeDefaultTemplates();
        this.loadSchedules();
        this.startScheduler();
    }
    
    /**
     * Initialize default report templates
     */
    initializeDefaultTemplates() {
        // Weekly Summary Report
        this.reportTemplates.set('weekly-summary', {
            name: 'Weekly Summary Report',
            description: 'Comprehensive weekly analytics summary',
            frequency: 'weekly',
            sections: [
                'user-growth',
                'achievement-trends',
                'event-participation',
                'department-analysis'
            ],
            format: 'json',
            includeCharts: false,
            recipients: []
        });
        
        // Monthly Executive Report
        this.reportTemplates.set('monthly-executive', {
            name: 'Monthly Executive Report',
            description: 'High-level monthly metrics for executives',
            frequency: 'monthly',
            sections: [
                'executive-summary',
                'key-metrics',
                'growth-analysis',
                'recommendations'
            ],
            format: 'pdf',
            includeCharts: true,
            recipients: []
        });
        
        // Daily Operations Report
        this.reportTemplates.set('daily-operations', {
            name: 'Daily Operations Report',
            description: 'Daily operational metrics and alerts',
            frequency: 'daily',
            sections: [
                'daily-stats',
                'system-health',
                'pending-actions'
            ],
            format: 'json',
            includeCharts: false,
            recipients: []
        });
    }
    
    /**
     * Schedule a new report
     */
    scheduleReport(templateId, schedule, options = {}) {
        if (!this.reportTemplates.has(templateId)) {
            throw new Error(`Report template '${templateId}' not found`);
        }
        
        const scheduleId = this.generateScheduleId();
        const reportSchedule = {
            id: scheduleId,
            templateId,
            schedule, // cron-like schedule or simple frequency
            options: {
                enabled: true,
                lastRun: null,
                nextRun: this.calculateNextRun(schedule),
                ...options
            },
            createdAt: new Date().toISOString(),
            createdBy: securityManager.currentUser?.uid
        };
        
        this.reportSchedules.set(scheduleId, reportSchedule);
        this.saveSchedules();
        
        return scheduleId;
    }
    
    /**
     * Generate a report manually
     */
    async generateReport(templateId, options = {}) {
        if (!securityManager.canExportData()) {
            throw new Error('Insufficient permissions to generate reports');
        }
        
        const template = this.reportTemplates.get(templateId);
        if (!template) {
            throw new Error(`Report template '${templateId}' not found`);
        }
        
        console.log(`Generating report: ${template.name}`);
        
        const reportData = await this.collectReportData(template, options);
        const report = await this.buildReport(template, reportData, options);
        
        // Save to history
        this.reportHistory.push({
            id: this.generateReportId(),
            templateId,
            template: template.name,
            generatedAt: new Date().toISOString(),
            generatedBy: securityManager.currentUser?.uid,
            size: JSON.stringify(report).length,
            format: template.format
        });
        
        // Keep only last 100 reports in history
        if (this.reportHistory.length > 100) {
            this.reportHistory.shift();
        }
        
        this.saveReportHistory();
        
        return report;
    }
    
    /**
     * Collect data for report
     */
    async collectReportData(template, options = {}) {
        const data = {};
        const timeRange = options.timeRange || this.getDefaultTimeRange(template.frequency);
        
        // Collect base data
        const [users, achievements, events, profiles, badgeClaims] = await Promise.all([
            dataFetcher.fetchData('users'),
            dataFetcher.fetchData('achievements'),
            dataFetcher.fetchData('events'),
            dataFetcher.fetchData('profiles'),
            dataFetcher.fetchData('badgeClaims')
        ]);
        
        data.users = users.data;
        data.achievements = achievements.data;
        data.events = events.data;
        data.profiles = profiles.data;
        data.badgeClaims = badgeClaims.data;
        
        // Filter by time range if specified
        if (timeRange) {
            data.users = this.filterByTimeRange(data.users, timeRange);
            data.achievements = this.filterByTimeRange(data.achievements, timeRange);
            data.events = this.filterByTimeRange(data.events, timeRange);
            data.badgeClaims = this.filterByTimeRange(data.badgeClaims, timeRange);
        }
        
        // Add comparative data if needed
        if (template.sections.includes('growth-analysis') || template.sections.includes('comparative-analysis')) {
            data.comparative = await this.collectComparativeData(data, timeRange);
        }
        
        return data;
    }
    
    /**
     * Build the actual report
     */
    async buildReport(template, data, options = {}) {
        const report = {
            metadata: {
                title: template.name,
                description: template.description,
                generatedAt: new Date().toISOString(),
                generatedBy: securityManager.currentUser?.uid,
                template: template.name,
                format: template.format,
                version: '2.0.0'
            },
            summary: {},
            sections: {},
            appendix: {}
        };
        
        // Build each section
        for (const sectionId of template.sections) {
            report.sections[sectionId] = await this.buildReportSection(sectionId, data, options);
        }
        
        // Generate summary
        report.summary = this.generateReportSummary(report.sections, data);
        
        // Add appendix
        report.appendix = {
            dataStats: this.generateDataStats(data),
            methodology: this.getMethodologyNotes(),
            glossary: this.getGlossary()
        };
        
        return report;
    }
    
    /**
     * Build individual report section
     */
    async buildReportSection(sectionId, data, options = {}) {
        switch (sectionId) {
            case 'user-growth':
                return this.buildUserGrowthSection(data);
            
            case 'achievement-trends':
                return this.buildAchievementTrendsSection(data);
            
            case 'event-participation':
                return this.buildEventParticipationSection(data);
            
            case 'department-analysis':
                return this.buildDepartmentAnalysisSection(data);
            
            case 'executive-summary':
                return this.buildExecutiveSummarySection(data);
            
            case 'key-metrics':
                return this.buildKeyMetricsSection(data);
            
            case 'growth-analysis':
                return this.buildGrowthAnalysisSection(data);
            
            case 'daily-stats':
                return this.buildDailyStatsSection(data);
            
            case 'system-health':
                return this.buildSystemHealthSection(data);
            
            case 'pending-actions':
                return this.buildPendingActionsSection(data);
            
            default:
                return { error: `Unknown section: ${sectionId}` };
        }
    }
    
    /**
     * Build user growth section
     */
    buildUserGrowthSection(data) {
        const section = {
            title: 'User Growth Analysis',
            metrics: {
                totalUsers: data.users.length,
                newUsers: data.users.filter(u => this.isRecent(u.createdAt, 7)).length,
                activeUsers: data.users.filter(u => u.lastLogin && this.isRecent(u.lastLogin, 30)).length
            },
            breakdown: {
                byRole: this.groupBy(data.users, 'role'),
                byDepartment: this.groupBy(data.profiles, 'department'),
                byMonth: this.groupByMonth(data.users)
            },
            insights: []
        };
        
        // Generate insights
        if (section.metrics.newUsers > section.metrics.totalUsers * 0.1) {
            section.insights.push('High new user acquisition rate (>10% of total users)');
        }
        
        if (section.metrics.activeUsers < section.metrics.totalUsers * 0.5) {
            section.insights.push('Low user engagement - less than 50% active in last 30 days');
        }
        
        return section;
    }
    
    /**
     * Build achievement trends section
     */
    buildAchievementTrendsSection(data) {
        return {
            title: 'Achievement Trends',
            metrics: {
                totalAchievements: data.achievements.length,
                verifiedAchievements: data.achievements.filter(a => a.isVerified).length,
                pendingAchievements: data.achievements.filter(a => !a.isVerified).length
            },
            breakdown: {
                byType: this.groupBy(data.achievements, 'type'),
                byMonth: this.groupByMonth(data.achievements),
                topPerformers: this.getTopPerformers(data.achievements)
            },
            trends: {
                verificationRate: (data.achievements.filter(a => a.isVerified).length / data.achievements.length * 100).toFixed(1) + '%'
            }
        };
    }
    
    /**
     * Build executive summary section
     */
    buildExecutiveSummarySection(data) {
        return {
            title: 'Executive Summary',
            keyHighlights: [
                `Total registered users: ${data.users.length}`,
                `Active achievements: ${data.achievements.length}`,
                `Events conducted: ${data.events.length}`,
                `Departments participating: ${new Set(data.profiles.map(p => p.department)).size}`
            ],
            performanceIndicators: {
                userEngagement: this.calculateEngagementRate(data),
                achievementCompletion: this.calculateCompletionRate(data),
                systemUtilization: this.calculateUtilizationRate(data)
            },
            recommendations: this.generateRecommendations(data)
        };
    }
    
    /**
     * Helper methods
     */
    groupBy(array, field) {
        return array.reduce((groups, item) => {
            const key = item[field] || 'Unknown';
            groups[key] = (groups[key] || 0) + 1;
            return groups;
        }, {});
    }
    
    groupByMonth(array) {
        return array.reduce((groups, item) => {
            if (!item.createdAt) return groups;
            
            const date = new Date(item.createdAt);
            const monthKey = `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}`;
            groups[monthKey] = (groups[monthKey] || 0) + 1;
            return groups;
        }, {});
    }
    
    isRecent(dateString, days) {
        if (!dateString) return false;
        const date = new Date(dateString);
        const now = new Date();
        const diffTime = Math.abs(now - date);
        const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
        return diffDays <= days;
    }
    
    calculateEngagementRate(data) {
        const activeUsers = data.users.filter(u => u.lastLogin && this.isRecent(u.lastLogin, 30)).length;
        return ((activeUsers / data.users.length) * 100).toFixed(1) + '%';
    }
    
    calculateCompletionRate(data) {
        const completed = data.achievements.filter(a => a.isVerified).length;
        return ((completed / data.achievements.length) * 100).toFixed(1) + '%';
    }
    
    calculateUtilizationRate(data) {
        // Simple utilization based on events and participation
        const totalEvents = data.events.length;
        const totalClaims = data.badgeClaims.length;
        return totalEvents > 0 ? ((totalClaims / totalEvents) * 100).toFixed(1) + '%' : '0%';
    }
    
    generateRecommendations(data) {
        const recommendations = [];
        
        const engagementRate = parseFloat(this.calculateEngagementRate(data));
        if (engagementRate < 50) {
            recommendations.push('Implement user engagement initiatives to increase active participation');
        }
        
        const completionRate = parseFloat(this.calculateCompletionRate(data));
        if (completionRate < 70) {
            recommendations.push('Streamline achievement verification process to improve completion rates');
        }
        
        return recommendations;
    }
    
    /**
     * Utility methods
     */
    generateScheduleId() {
        return 'schedule_' + Date.now() + '_' + Math.random().toString(36).substr(2, 9);
    }
    
    generateReportId() {
        return 'report_' + Date.now() + '_' + Math.random().toString(36).substr(2, 9);
    }
    
    calculateNextRun(schedule) {
        // Simple implementation - in production, use a proper cron parser
        const now = new Date();
        switch (schedule) {
            case 'daily':
                return new Date(now.getTime() + 24 * 60 * 60 * 1000);
            case 'weekly':
                return new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000);
            case 'monthly':
                const nextMonth = new Date(now);
                nextMonth.setMonth(nextMonth.getMonth() + 1);
                return nextMonth;
            default:
                return new Date(now.getTime() + 24 * 60 * 60 * 1000);
        }
    }
    
    saveSchedules() {
        const schedules = Array.from(this.reportSchedules.entries());
        localStorage.setItem('reportSchedules', JSON.stringify(schedules));
    }
    
    loadSchedules() {
        const saved = localStorage.getItem('reportSchedules');
        if (saved) {
            const schedules = JSON.parse(saved);
            this.reportSchedules = new Map(schedules);
        }
    }
    
    saveReportHistory() {
        localStorage.setItem('reportHistory', JSON.stringify(this.reportHistory));
    }
    
    startScheduler() {
        // Check for scheduled reports every hour
        setInterval(() => {
            this.checkScheduledReports();
        }, 60 * 60 * 1000);
    }
    
    async checkScheduledReports() {
        if (!this.isRunning) return;
        
        const now = new Date();
        
        for (const [scheduleId, schedule] of this.reportSchedules.entries()) {
            if (schedule.options.enabled && schedule.options.nextRun <= now) {
                try {
                    await this.generateReport(schedule.templateId);
                    
                    // Update next run time
                    schedule.options.lastRun = now.toISOString();
                    schedule.options.nextRun = this.calculateNextRun(schedule.schedule);
                    
                    this.saveSchedules();
                } catch (error) {
                    console.error(`Error generating scheduled report ${scheduleId}:`, error);
                }
            }
        }
    }
    
    /**
     * Get report templates
     */
    getTemplates() {
        return Array.from(this.reportTemplates.entries()).map(([id, template]) => ({
            id,
            ...template
        }));
    }
    
    /**
     * Get scheduled reports
     */
    getSchedules() {
        return Array.from(this.reportSchedules.entries()).map(([id, schedule]) => ({
            id,
            ...schedule
        }));
    }
    
    /**
     * Get report history
     */
    getHistory() {
        return [...this.reportHistory].reverse(); // Most recent first
    }
}

// Create singleton instance
export const automatedReporting = new AutomatedReporting();
