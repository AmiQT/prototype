# 🎯 Auto-Generate UAT & UX/UI Testing Form

**Generated:** December 20, 2025  
**Purpose:** Automate creation of Google Form for Student Talent Profiling App testing

---

## 📋 CARA GUNA (5 MINIT)

### **Step 1: Buka Google Apps Script**
1. Pergi ke [script.google.com](https://script.google.com)
2. Klik **New project**
3. Nama: `UAT Form Generator`

### **Step 2: Paste Script**
1. Delete code default (`function myFunction()...`)
2. Copy **SEMUA code** dari Section Script di bawah
3. Paste dalam editor
4. Klik **Save** (💾 icon) atau `Ctrl+S`

### **Step 3: Run Script**
1. Pilih function **`createUATForm`** dari dropdown atas
2. Klik **Run** (▶️ button)
3. **First time:** Klik **Review Permissions** → Pilih Google account → **Allow**
4. Tunggu 5-10 saat

### **Step 4: Get Form Link**
1. Tengok **Execution log** (panel bawah)
2. Copy **Form URL** yang muncul
3. Share link tu untuk testing!

---

## 💻 GOOGLE APPS SCRIPT CODE

```javascript
/**
 * Auto-Generate UAT & UX/UI Testing Form (ULTRA COMPACT)
 * For: Student Talent Profiling App (Flutter + FastAPI + Supabase)
 * Created: December 20, 2025
 * Questions: 10 (essential core only)
 */

function createUATForm() {
  // Create new form
  var form = FormApp.create('Student Talent Profiling App - Quick Testing');
  
  // Form settings
  form.setDescription(
    'Student Talent Profiling Application - User Acceptance Testing\n\n' +
    'Thank you for taking the time to test our application. Your feedback is valuable for improving the system. ' +
    'This form should take approximately 5 minutes to complete.\n\n' +
    'All questions are optional - please answer only those related to features you tested.'
  );
  
  form.setConfirmationMessage(
    'Thank you for your feedback! Your response has been recorded successfully. ' +
    'If you encountered any critical bugs, please contact the development team immediately.'
  );
  
  form.setAllowResponseEdits(true);
  form.setCollectEmail(true);
  form.setLimitOneResponsePerUser(false);
  
  // ============================================
  // SECTION 1: BASIC INFO
  // ============================================
  form.addSectionHeaderItem()
    .setTitle('Respondent Information')
    .setHelpText('Basic information for categorizing feedback');
  
  form.addMultipleChoiceItem()
    .setTitle('User Role & Platform Tested')
    .setChoiceValues([
      'Student - Mobile Application',
      'Student - Web Dashboard',
      'Lecturer - Mobile Application',
      'Lecturer - Web Dashboard',
      'Administrator - Mobile Application',
      'Administrator - Web Dashboard',
      'External Tester - Mobile Application',
      'External Tester - Web Dashboard'
    ])
    .setRequired(false);
  
  // ============================================
  // SECTION 2: CORE FEATURES (UAT + UX)
  // ============================================
  form.addPageBreakItem()
    .setTitle('Functionality Testing')
    .setHelpText('Please test the following features and rate their functionality. Select "Did not test" if you skipped that feature.');
  
  form.addMultipleChoiceItem()
    .setTitle('1. Login & Authentication')
    .setChoiceValues([
      'Working properly - No issues encountered',
      'Working with minor issues - Functional but has small bugs',
      'Major issues - Significant problems or errors',
      'Not functional - Feature is broken or crashes',
      'Did not test'
    ])
    .setRequired(false);
  
  form.addMultipleChoiceItem()
    .setTitle('2. Profile Management (View & Edit)')
    .setChoiceValues([
      'Working properly - No issues encountered',
      'Working with minor issues - Functional but has small bugs',
      'Major issues - Significant problems or errors',
      'Not functional - Feature is broken or crashes',
      'Did not test'
    ])
    .setRequired(false);
  
  form.addMultipleChoiceItem()
    .setTitle('3. Showcase Feed & Media Upload')
    .setChoiceValues([
      'Working properly - No issues encountered',
      'Working with minor issues - Functional but has small bugs',
      'Major issues - Significant problems or errors',
      'Not functional - Feature is broken or crashes',
      'Did not test'
    ])
    .setRequired(false);
  
  form.addMultipleChoiceItem()
    .setTitle('4. AI Assistant Chat (Bahasa Melayu Support)')
    .setChoiceValues([
      'Working properly - No issues encountered',
      'Working with minor issues - Functional but has small bugs',
      'Major issues - Significant problems or errors',
      'Not functional - Feature is broken or crashes',
      'Did not test'
    ])
    .setRequired(false);
  
  form.addMultipleChoiceItem()
    .setTitle('5. Analytics Dashboard & Search Function')
    .setChoiceValues([
      'Working properly - No issues encountered',
      'Working with minor issues - Functional but has small bugs',
      'Major issues - Significant problems or errors',
      'Not functional - Feature is broken or crashes',
      'Did not test'
    ])
    .setRequired(false);
  
  // ============================================
  // SECTION 3: EXPERIENCE RATING
  // ============================================
  form.addPageBreakItem()
    .setTitle('User Experience Evaluation')
    .setHelpText('Rate your overall experience with the application');
  
  form.addScaleItem()
    .setTitle('6. User Interface Design & Navigation - How would you rate the ease of use?')
    .setBounds(1, 5)
    .setLabels('Very Confusing', 'Very Intuitive')
    .setRequired(false);
  
  form.addScaleItem()
    .setTitle('7. Application Speed & Performance')
    .setBounds(1, 5)
    .setLabels('Very Slow', 'Very Fast')
    .setRequired(false);
  
  form.addMultipleChoiceItem()
    .setTitle('8. Application Stability - Did you experience any crashes or freezes?')
    .setChoiceValues([
      'Very stable - No crashes or issues',
      'Mostly stable - 1-2 minor issues',
      'Somewhat unstable - 3-4 crashes or freezes',
      'Very unstable - Frequent crashes (5+ times)',
      'Unable to assess'
    ])
    .setRequired(false);
  
  // ============================================
  // SECTION 4: FINAL FEEDBACK
  // ============================================
  form.addPageBreakItem()
    .setTitle('Overall Assessment & Feedback')
    .setHelpText('Your final thoughts and recommendations');
  
  form.addScaleItem()
    .setTitle('9. Overall Satisfaction - How satisfied are you with the application?')
    .setBounds(1, 5)
    .setLabels('Very Dissatisfied', 'Very Satisfied')
    .setRequired(false);
  
  form.addParagraphTextItem()
    .setTitle('10. Bug Reports & Suggestions for Improvement')
    .setHelpText('Please describe any bugs encountered or suggestions for enhancement. Include details such as what happened, when it occurred, and what you expected to happen.')
    .setRequired(false);
  
  // ============================================
  // FINAL: Get URLs
  // ============================================
  var formUrl = form.getEditUrl();
  var publishedUrl = form.getPublishedUrl();
  
  // Log results
  Logger.log('✅ FORM CREATED SUCCESSFULLY!');
  Logger.log('');
  Logger.log('Form Title: ' + form.getTitle());
  Logger.log('Total Questions: 10 (Ultra Compact)');
  Logger.log('All questions: OPTIONAL');
  Logger.log('Estimated time: 3 minutes');
  Logger.log('');
  Logger.log('📝 EDIT FORM (admin only):');
  Logger.log(formUrl);
  Logger.log('');
  Logger.log('🔗 PUBLIC LINK (share to testers):');
  Logger.log(publishedUrl);
  Logger.log('');
  Logger.log('📊 Responses auto-saved to Google Sheets');
  
  // Return URLs for reference
  return {
    editUrl: formUrl,
    publicUrl: publishedUrl
  };
}

/**
 * Helper function: Create response spreadsheet
 * Run this AFTER running createUATForm() if you want custom sheet
 */
function linkResponseSheet() {
  // Get all forms
  var forms = FormApp.getActiveForm();
  if (!forms) {
    Logger.log('❌ No active form found. Run createUATForm() first.');
    return;
  }
  
  // Create new spreadsheet for responses
  var ss = SpreadsheetApp.create('UAT Responses - ' + forms.getTitle());
  forms.setDestination(FormApp.DestinationType.SPREADSHEET, ss.getId());
  
  Logger.log('✅ Response sheet created:');
  Logger.log(ss.getUrl());
}
```

---

## ✅ HASIL YANG AKAN DAPAT

Form dengan **18 soalan** organized dalam **4 sections** (STREAMLINED):
0 soalan SAHAJA** - ultra compact:

### **SectiManagement (View & Edit)
3. Showcase Feed & Media Upload
4. AI Assistant Chat (Bahasa Melayu)
5. Analytics Dashboard & Search

**Options:** Working properly | Working with minor issues | Major issues | Not functional | Did not test
3. Showcase & Upload Media
4. AI Chat (BahasUser Experience Evaluation (3 Q)**
6. UI Design & Navigation (scale 1-5: Very Confusing → Very Intuitive)
7. Speed & Performance (scale 1-5: Very Slow → Very Fast)
8. Application Stability (5 options: Very stable → Very u Issue | ❌ Broken | ⏭️ Skip

### **Section 3: Quick Ratings (3 Q)**
6. Design & Navigation (scale 1-5)
7. Speed & Performance (sAssessment (2 Q)**
9. Overall Satisfaction (scale 1-5: Very Dissatisfied → Very Satisfied)
10. Bug Reports & Suggestions for Improvement (detailed 
### **Section 4: Overall (2 Q)**
9. Overall Rating (scale 1-5)
10. Main Issues/Suggestions (text)

---

### 🎯 **SUPER COMPACT:**
- ✅ **10 soalan** je (vs 18 sebelum ni)
- ✅ **3 minit** je nak complete
- ✅ **Semua optional**
- ✅ Combine related features
- ✅ Simplify choices (4 options max)
- ✅ Focus on actionable feedback
---

## 🎯 NEXT STEPS SELEPAS FORM CREATED

### 1. **Test Form**
- Click public URL
- Test submit sample response
- Ensure semua logic & branching berfungsi

### 2. **View Responses**
- Dalam form editor, klik **"Responses"** tab
- Auto-create Google Sheet with all responses
- Download as CSV bila perlu

### 3. **Share Link**
- Copy **Public URL** dari execution log
- Share kepada testers via WhatsApp/Email/Teams
- Set deadline untuk complete testing

### 4. **Analyze Results**
- Export Google Sheet
- Create pivot tables untuk summary
- Identify critical bugs vs improvements

---

## 💡 TIPS

### **Customize Form:**
1. Dalam Google Apps Script editor, modify `createUATForm()` function
2. Add/remove questions by copying existing patterns
3. Re-run script untuk create new form

### **Multiple Forms:**
- Run script multiple times = multiple forms
- Rename forms dalam Google Drive after creation
- Useful untuk different testing phases (Alpha, Beta, UAV)

### **Advanced Features:**
```javascript
// Add conditional branching (Section jump based on answer)
var item = form.addMultipleChoiceItem();
item.setTitle('Question...')
    .setChoiceValues(['Option A', 'Option B']);

var pageBreak = form.addPageBreakItem();
item.createChoice('Option A', pageBreak);
```

---

## 🚨 TROUBLESHOOTING

### **Error: "Authorization Required"**
- Click **Review Permissions**
- Select your Google account
- Click **Advanced** → **Go to project (unsafe)** → **Allow**

### **Error: "Script not found"**
- Ensure function name adalah `createUATForm` (exact spelling)
- Check dropdown atas ada pilih function yang betul

### **Form tidak muncul dalam Drive**
- Refresh Google Drive
- Search by name: "Student Talent Profiling App"
- Check dalam "Recent" folder

### **Nak edit form manually after creation**
- Use **Edit URL** dari log
- Open form → Click pencil icon
- Make changes manually