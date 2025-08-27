import { ANALYTICS_CONFIG } from '../config/analytics-config.js';

// Data validation utilities for analytics
export class AnalyticsValidator {
    
    /**
     * Validate data structure for analytics processing
     * @param {Array} data - Data array to validate
     * @param {string} type - Data type (users, events, achievements)
     * @returns {Object} Validation result
     */
    static validateData(data, type) {
        const result = {
            isValid: true,
            errors: [],
            warnings: [],
            cleanedData: []
        };
        
        if (!Array.isArray(data)) {
            result.isValid = false;
            result.errors.push('Data must be an array');
            return result;
        }
        
        if (data.length === 0) {
            result.warnings.push('Data array is empty');
            return result;
        }
        
        if (data.length > ANALYTICS_CONFIG.VALIDATION_RULES.maxDataPoints) {
            result.warnings.push(`Data exceeds maximum points (${ANALYTICS_CONFIG.VALIDATION_RULES.maxDataPoints})`);
            data = data.slice(0, ANALYTICS_CONFIG.VALIDATION_RULES.maxDataPoints);
        }
        
        // Validate each record
        data.forEach((record, index) => {
            const recordValidation = this.validateRecord(record, type, index);
            if (!recordValidation.isValid) {
                result.errors.push(...recordValidation.errors);
            } else {
                result.cleanedData.push(recordValidation.cleanedRecord);
            }
            result.warnings.push(...recordValidation.warnings);
        });
        
        result.isValid = result.errors.length === 0;
        return result;
    }
    
    /**
     * Validate individual record
     * @param {Object} record - Single data record
     * @param {string} type - Data type
     * @param {number} index - Record index
     * @returns {Object} Validation result
     */
    static validateRecord(record, type, index) {
        const result = {
            isValid: true,
            errors: [],
            warnings: [],
            cleanedRecord: { ...record }
        };
        
        // Check required fields
        ANALYTICS_CONFIG.VALIDATION_RULES.requiredFields.forEach(field => {
            if (!record.hasOwnProperty(field) || record[field] === null || record[field] === undefined) {
                result.errors.push(`Record ${index}: Missing required field '${field}'`);
            }
        });
        
        // Validate dates
        if (record.createdAt) {
            const dateValidation = this.validateDate(record.createdAt);
            if (!dateValidation.isValid) {
                result.errors.push(`Record ${index}: Invalid date format for 'createdAt'`);
            } else {
                result.cleanedRecord.createdAt = dateValidation.standardizedDate;
            }
        }
        
        // Type-specific validations
        switch (type) {
            case 'users':
                this.validateUserRecord(record, result, index);
                break;

            case 'events':
                this.validateEventRecord(record, result, index);
                break;
        }
        
        result.isValid = result.errors.length === 0;
        return result;
    }
    
    /**
     * Validate date formats
     * @param {string|number|Date} date - Date to validate
     * @returns {Object} Validation result with standardized date
     */
    static validateDate(date) {
        const result = {
            isValid: false,
            standardizedDate: null
        };
        
        try {
            let parsedDate;
            
            if (date instanceof Date) {
                parsedDate = date;
            } else if (typeof date === 'string') {
                parsedDate = new Date(date);
            } else if (typeof date === 'number') {
                parsedDate = new Date(date);
            } else {
                return result;
            }
            
            if (!isNaN(parsedDate.getTime())) {
                result.isValid = true;
                result.standardizedDate = parsedDate.toISOString();
            }
        } catch (error) {
            // Date parsing failed
        }
        
        return result;
    }
    
    /**
     * Validate user record
     */
    static validateUserRecord(record, result, index) {
        if (record.role && !['student', 'lecturer', 'admin'].includes(record.role)) {
            result.warnings.push(`Record ${index}: Unknown user role '${record.role}'`);
        }
        
        if (record.email && !this.isValidEmail(record.email)) {
            result.warnings.push(`Record ${index}: Invalid email format`);
        }
    }
    

    
    /**
     * Validate event record
     */
    static validateEventRecord(record, result, index) {
        if (record.startDate && record.endDate) {
            const start = new Date(record.startDate);
            const end = new Date(record.endDate);
            if (start > end) {
                result.warnings.push(`Record ${index}: Start date is after end date`);
            }
        }
    }
    
    /**
     * Simple email validation
     */
    static isValidEmail(email) {
        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        return emailRegex.test(email);
    }
    
    /**
     * Sanitize data for chart rendering
     * @param {Array} data - Data to sanitize
     * @returns {Array} Sanitized data
     */
    static sanitizeForChart(data) {
        return data.map(item => {
            const sanitized = {};
            Object.keys(item).forEach(key => {
                const value = item[key];
                if (typeof value === 'string') {
                    // Remove potentially harmful characters
                    sanitized[key] = value.replace(/[<>\"']/g, '');
                } else {
                    sanitized[key] = value;
                }
            });
            return sanitized;
        });
    }
}
