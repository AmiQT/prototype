# 🎨 UTHM Talent Profiling App - Design System

## Overview
This design system provides a comprehensive guide for creating consistent, modern, and accessible UI components across the UTHM Talent Profiling mobile application.

## 🎯 Design Principles

### 1. **Professional & Academic**
- Clean, professional appearance suitable for academic environment
- Trustworthy and credible visual language
- Emphasis on content and user achievements

### 2. **Modern & Engaging**
- Contemporary design patterns inspired by leading social platforms
- Smooth animations and micro-interactions
- Visual hierarchy that guides user attention

### 3. **Accessible & Inclusive**
- High contrast ratios for readability
- Touch-friendly interactive elements (minimum 44px)
- Support for different screen sizes and orientations

## 🎨 Color System

### Primary Colors
```dart
// Professional Blue Gradient
static const Color primaryColor = Color(0xFF2563EB);      // Main brand color
static const Color primaryLightColor = Color(0xFF3B82F6); // Lighter variant
static const Color primaryDarkColor = Color(0xFF1D4ED8);  // Darker variant
static const Color primaryAccent = Color(0xFF60A5FA);     // Accent variant
```

### Secondary Colors
```dart
// Warm Red for CTAs and Important Actions
static const Color secondaryColor = Color(0xFFEF4444);      // Main secondary
static const Color secondaryLightColor = Color(0xFFF87171); // Lighter variant
static const Color secondaryDarkColor = Color(0xFFDC2626);  // Darker variant
static const Color secondaryAccent = Color(0xFFFCA5A5);     // Accent variant
```

### Status Colors
```dart
static const Color errorColor = Color(0xFFEF4444);    // Error states
static const Color successColor = Color(0xFF10B981);  // Success states
static const Color warningColor = Color(0xFFF59E0B);  // Warning states
static const Color infoColor = Color(0xFF3B82F6);     // Info states
```

### Background & Surface Colors
```dart
static const Color backgroundColor = Color(0xFFF8FAFC);  // App background
static const Color surfaceColor = Color(0xFFFFFFFF);    // Card/surface background
static const Color surfaceVariant = Color(0xFFF1F5F9);  // Alternative surface
```

## 📏 Spacing System

### Consistent Spacing Scale
```dart
static const double spaceXs = 4.0;   // Extra small spacing
static const double spaceSm = 8.0;   // Small spacing
static const double spaceMd = 16.0;  // Medium spacing (base unit)
static const double spaceLg = 24.0;  // Large spacing
static const double spaceXl = 32.0;  // Extra large spacing
static const double space2xl = 48.0; // 2x extra large
static const double space3xl = 64.0; // 3x extra large
```

### Usage Guidelines
- **spaceXs (4px)**: Icon padding, small gaps
- **spaceSm (8px)**: Button padding, small margins
- **spaceMd (16px)**: Standard padding, card margins
- **spaceLg (24px)**: Section spacing, large padding
- **spaceXl+ (32px+)**: Major layout spacing

## 🔄 Border Radius System

### Consistent Radius Scale
```dart
static const double radiusXs = 4.0;   // Small elements
static const double radiusSm = 8.0;   // Buttons, small cards
static const double radiusMd = 12.0;  // Standard cards
static const double radiusLg = 16.0;  // Large cards, containers
static const double radiusXl = 24.0;  // Hero elements
static const double radiusFull = 999.0; // Circular elements
```

## 🎭 Typography System

### Font Family
- **Primary**: Google Fonts Poppins
- **Fallback**: System default sans-serif

### Type Scale
```dart
// Headlines
headlineLarge: 32px, weight: 700    // Page titles
headlineMedium: 28px, weight: 600   // Section headers
headlineSmall: 24px, weight: 600    // Card titles

// Titles
titleLarge: 22px, weight: 600       // Important titles
titleMedium: 16px, weight: 600      // Standard titles
titleSmall: 14px, weight: 600       // Small titles

// Body Text
bodyLarge: 16px, weight: 400        // Main content
bodyMedium: 14px, weight: 400       // Secondary content
bodySmall: 12px, weight: 400        // Captions, metadata

// Labels
labelLarge: 14px, weight: 500       // Button labels
labelMedium: 12px, weight: 500      // Form labels
labelSmall: 10px, weight: 500       // Small labels
```

## 🎪 Component Guidelines

### Cards
- **Elevation**: 2-8px soft shadows
- **Radius**: 12-16px for standard cards
- **Padding**: 16-24px internal spacing
- **Margin**: 8-16px between cards

### Buttons
- **Primary**: Gradient background, white text
- **Secondary**: Outline style with primary color
- **Minimum Height**: 44px for accessibility
- **Radius**: 8-12px

### Navigation
- **Bottom Navigation**: Floating style with rounded corners
- **Active States**: Color + icon changes
- **Animations**: 200-300ms smooth transitions

### Form Elements
- **Input Fields**: Outlined style with focus states
- **Labels**: Above input, medium weight
- **Error States**: Red color with descriptive text

## 🎬 Animation Guidelines

### Timing
- **Fast**: 150-200ms for micro-interactions
- **Standard**: 250-300ms for most transitions
- **Slow**: 400-500ms for complex animations

### Easing
- **Standard**: `Curves.easeInOut`
- **Entrance**: `Curves.easeOut`
- **Exit**: `Curves.easeIn`

### Common Animations
- **Scale**: 0.95-1.0 for press feedback
- **Fade**: 0.0-1.0 for content transitions
- **Slide**: For page transitions and reveals

## 📱 Responsive Design

### Breakpoints
- **Mobile**: < 768px
- **Tablet**: 768px - 1024px
- **Desktop**: > 1024px

### Layout Guidelines
- **Mobile-first**: Design for mobile, enhance for larger screens
- **Touch Targets**: Minimum 44px for interactive elements
- **Safe Areas**: Respect device safe areas and notches

## ♿ Accessibility

### Color Contrast
- **Normal Text**: 4.5:1 minimum ratio
- **Large Text**: 3:1 minimum ratio
- **Interactive Elements**: Clear focus indicators

### Touch Targets
- **Minimum Size**: 44x44px
- **Spacing**: 8px minimum between targets
- **Feedback**: Visual and haptic feedback for interactions

## 🚀 Implementation Examples

### Using the Design System
```dart
// Spacing
padding: const EdgeInsets.all(AppTheme.spaceMd),

// Colors
color: AppTheme.primaryColor,
backgroundColor: AppTheme.surfaceColor,

// Typography
style: Theme.of(context).textTheme.titleLarge,

// Radius
borderRadius: BorderRadius.circular(AppTheme.radiusMd),

// Elevation
elevation: AppTheme.elevationMd,
```

### Component Structure
```dart
Container(
  margin: const EdgeInsets.all(AppTheme.spaceMd),
  padding: const EdgeInsets.all(AppTheme.spaceLg),
  decoration: BoxDecoration(
    color: AppTheme.surfaceColor,
    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: AppTheme.elevationMd,
        offset: const Offset(0, 2),
      ),
    ],
  ),
  child: YourContent(),
)
```

## 📋 Checklist for New Components

- [ ] Uses design system colors
- [ ] Follows spacing guidelines
- [ ] Implements proper typography
- [ ] Includes accessibility features
- [ ] Has appropriate animations
- [ ] Responsive design considerations
- [ ] Consistent with existing patterns

## 🔄 Updates and Maintenance

This design system should be:
- **Reviewed** quarterly for consistency
- **Updated** when new patterns emerge
- **Documented** with examples and usage
- **Tested** across different devices and accessibility tools

---

*Last updated: August 2025*
*Version: 1.0.0*
