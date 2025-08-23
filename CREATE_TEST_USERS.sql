-- 👥 Create Test Users for Student Talent Profiling System
-- Run these commands in your Supabase SQL Editor
-- Go to: https://supabase.com/dashboard/project/xibffemtpboiecpeynon/sql

-- 🔑 Create Admin User
INSERT INTO users (
    id, 
    email, 
    name, 
    role, 
    department, 
    staff_id, 
    is_active, 
    profile_completed, 
    created_at, 
    updated_at
) VALUES (
    '880698eb-2793-435f-ae67-734cc7d3d756',
    'admin@uthm.edu.my',
    'Dr. Ahmad Rahman',
    'admin',
    'FSKTM',
    'STAFF001',
    true,
    true,
    NOW(),
    NOW()
);

-- 🎓 Create Student User
INSERT INTO users (
    id,
    email,
    name, 
    role,
    department,
    student_id,
    is_active,
    profile_completed,
    created_at,
    updated_at
) VALUES (
    'b68d744f-1f1b-4c1d-b747-5c2d8596e31b',
    'student@uthm.edu.my',
    'Nurul Aisyah binti Abdullah',
    'student',
    'FSKTM',
    'AI220001',
    true,
    true,
    NOW(),
    NOW()
);

-- 📝 Create Admin Profile
INSERT INTO profiles (
    id,
    user_id,
    full_name,
    bio,
    phone_number,
    address,
    headline,
    profile_image_url,
    academic_info,
    skills,
    interests,
    experiences,
    projects,
    is_profile_complete,
    created_at,
    updated_at
) VALUES (
    'c3d4e5f6-a7b8-9012-cdef-345678901234',
    '880698eb-2793-435f-ae67-734cc7d3d756',
    'Dr. Ahmad Rahman',
    'Head of Department at FSKTM UTHM. Passionate about advancing computer science education and student development. Expertise in AI, machine learning, and educational technology.',
    '+60123456789',
    'Batu Pahat, Johor, Malaysia',
    'Head of Department | AI Researcher | Educational Technology Expert',
    'https://via.placeholder.com/400x400/2c3e50/ffffff?text=DR',
    '{"position": "Head of Department", "faculty": "FSKTM", "department": "Computer Science", "specialization": "Artificial Intelligence", "years_of_service": "12"}',
    '{"Leadership", "Artificial Intelligence", "Machine Learning", "Research", "Educational Technology", "Project Management"}',
    '{"AI Research", "Educational Innovation", "Student Mentoring", "Academic Administration"}',
    '[{"title": "Head of Department", "organization": "UTHM FSKTM", "duration": "2020-Present", "description": "Leading academic programs and research initiatives in computer science"}]',
    '[{"name": "AI Education Platform", "description": "Developed innovative AI-powered learning platform for students", "technologies": ["Python", "TensorFlow", "Web Technologies"], "status": "Completed"}]',
    true,
    NOW(),
    NOW()
);

-- 📝 Create Student Profile  
INSERT INTO profiles (
    id,
    user_id,
    full_name,
    bio,
    phone_number,
    address,
    headline,
    profile_image_url,
    academic_info,
    skills,
    interests,
    experiences,
    projects,
    is_profile_complete,
    created_at,
    updated_at
) VALUES (
    'd4e5f6a7-b8c9-0123-def4-456789012345',
    'b68d744f-1f1b-4c1d-b747-5c2d8596e31b',
    'Nurul Aisyah binti Abdullah',
    'Passionate Computer Science student specializing in Artificial Intelligence. Love solving complex problems and building innovative solutions. Actively participating in coding competitions and tech communities.',
    '+60198765432',
    'Kuala Lumpur, Malaysia',
    'AI Enthusiast | Full-Stack Developer | Problem Solver',
    'https://via.placeholder.com/400x400/3498db/ffffff?text=NA',
    '{"faculty": "FSKTM", "department": "Computer Science", "program": "Bachelor of Computer Science (Artificial Intelligence)", "year_of_study": "3", "semester": "2", "cgpa": "3.67", "expected_graduation": "2026"}',
    '{"Python", "JavaScript", "React", "Node.js", "Machine Learning", "TensorFlow", "SQL", "Git", "Docker", "AWS"}',
    '{"Artificial Intelligence", "Web Development", "Data Science", "Mobile Development", "Cloud Computing", "Open Source"}',
    '[{"title": "Software Development Intern", "company": "TechStart Malaysia", "duration": "Jun 2024 - Aug 2024", "description": "Developed web applications using React and Node.js. Worked on AI-powered features for customer analytics."}]',
    '[{"name": "AI Study Buddy", "description": "AI-powered study assistant for students using NLP and machine learning", "technologies": ["Python", "TensorFlow", "Flask", "React"], "url": "https://github.com/nurulaisyah/ai-study-buddy", "status": "In Progress"}, {"name": "Campus Event Manager", "description": "Full-stack web application for managing university events", "technologies": ["React", "Node.js", "PostgreSQL", "Docker"], "url": "https://github.com/nurulaisyah/campus-events", "status": "Completed"}]',
    true,
    NOW(),
    NOW()
);

-- 📅 Create Sample Event (Created by Admin)
INSERT INTO events (
    id,
    title,
    description,
    event_date,
    location,
    organizer_id,
    is_active,
    created_at,
    updated_at
) VALUES (
    'e5f6a7b8-c9d0-1234-ef56-567890123456',
    'AI & Machine Learning Workshop 2025',
    'Comprehensive hands-on workshop covering the fundamentals of Artificial Intelligence and Machine Learning. Participants will learn about neural networks, deep learning, and practical AI applications. Include real-world projects and industry insights.',
    '2025-02-15 09:00:00+08',
    'FSKTM Computer Lab 1, Main Campus',
    '880698eb-2793-435f-ae67-734cc7d3d756',
    true,
    NOW(),
    NOW()
);

-- 📱 Create Sample Showcase Post (by Student)
INSERT INTO showcase_posts (
    id,
    user_id,
    title,
    content,
    media_urls,
    category,
    tags,
    is_approved,
    created_at,
    updated_at
) VALUES (
    'f6a7b8c9-d0e1-2345-f678-678901234567',
    'b68d744f-1f1b-4c1d-b747-5c2d8596e31b',
    'My First AI Project: Study Buddy Assistant',
    'Excited to share my latest project - an AI-powered Study Buddy Assistant! 🤖📚

This application helps students by:
✅ Answering questions about study materials
✅ Creating personalized study schedules  
✅ Providing explanations for complex topics
✅ Tracking learning progress

Built with:
🐍 Python for the AI backend
🧠 TensorFlow for machine learning models
⚛️ React for the frontend interface
🗃️ PostgreSQL for data storage

The most challenging part was training the NLP model to understand various question formats. But seeing it help my classmates made all the effort worthwhile!

Currently working on adding voice interaction and mobile app support. 

#AI #MachineLearning #StudentProject #NLP #TensorFlow #Python #React #UTHM #FSKTM',
    '{"https://via.placeholder.com/800x600/3498db/ffffff?text=AI+Study+Buddy+Demo", "https://via.placeholder.com/800x600/2ecc71/ffffff?text=App+Interface"}',
    'project',
    '{"AI", "MachineLearning", "StudentProject", "NLP", "TensorFlow", "Python", "React", "UTHM", "FSKTM"}',
    true,
    NOW(),
    NOW()
);

-- 💬 Create Sample Showcase Interactions
INSERT INTO showcase_interactions (
    id,
    post_id,
    user_id,
    interaction_type,
    content,
    created_at
) VALUES (
    'a1b2c3d4-e5f6-7890-abcd-111111111111',
    'f6a7b8c9-d0e1-2345-f678-678901234567',
    '880698eb-2793-435f-ae67-734cc7d3d756',
    'comment',
    'Excellent work, Nurul! This AI Study Buddy project showcases great technical skills and practical application. The use of TensorFlow for NLP is impressive. I would love to see this presented at our upcoming AI showcase event. Keep up the innovative work! 👏',
    NOW()
),
(
    'b2c3d4e5-f6a7-8901-bcde-222222222222',
    'f6a7b8c9-d0e1-2345-f678-678901234567',
    'b68d744f-1f1b-4c1d-b747-5c2d8596e31b',
    'comment',
    'Thank you so much, Dr. Ahmad! Your encouragement means a lot. I would be honored to present this at the AI showcase. Working on this project has really deepened my understanding of NLP and machine learning concepts. 😊',
    NOW()
);

-- ✅ Test Users Created Successfully!
-- 
-- 🔑 Login Credentials:
-- Admin: admin@uthm.edu.my
-- Student: student@uthm.edu.my
--
-- 📊 Data Created:
-- • 2 Users (1 Admin, 1 Student)
-- • 2 Complete Profiles
-- • 1 Sample Event (AI Workshop)
-- • 1 Sample Showcase Post (AI Study Buddy)
-- • 2 Sample Interactions (Comments)
--
-- 🚀 Your database is now ready for testing!
