#!/usr/bin/env python3
"""
Backend Deployment Helper Script
This script helps you set up your FastAPI backend for cloud deployment
"""

import os
import subprocess
import sys
from pathlib import Path

def check_prerequisites():
    """Check if required tools are installed"""
    print("🔍 Checking prerequisites...")
    
    # Check Python version
    python_version = sys.version_info
    if python_version.major < 3 or (python_version.major == 3 and python_version.minor < 8):
        print("❌ Python 3.8+ is required")
        return False
    
    print(f"✅ Python {python_version.major}.{python_version.minor}.{python_version.micro}")
    
    # Check if requirements.txt exists
    if not Path("requirements.txt").exists():
        print("❌ requirements.txt not found")
        return False
    
    print("✅ requirements.txt found")
    
    # Check if main.py exists
    if not Path("main.py").exists():
        print("❌ main.py not found")
        return False
    
    print("✅ main.py found")
    
    return True

def setup_environment():
    """Set up environment variables"""
    print("\n🔧 Setting up environment...")
    
    env_file = Path(".env.cloud")
    if not env_file.exists():
        print("❌ .env.cloud file not found")
        print("Please create .env.cloud with your configuration")
        return False
    
    print("✅ .env.cloud found")
    
    # Load and validate environment variables
    load_dotenv(env_file)
    
    required_vars = [
        "DATABASE_URL",
        "CLOUDINARY_CLOUD_NAME", 
        "CLOUDINARY_API_KEY",
        "CLOUDINARY_API_SECRET"
    ]
    
    missing_vars = []
    for var in required_vars:
        if not os.getenv(var):
            missing_vars.append(var)
    
    if missing_vars:
        print(f"⚠️ Missing environment variables: {', '.join(missing_vars)}")
        print("Please update .env.cloud with these values")
        return False
    
    print("✅ All required environment variables are set")
    return True

def install_dependencies():
    """Install Python dependencies"""
    print("\n📦 Installing dependencies...")
    
    try:
        subprocess.run([sys.executable, "-m", "pip", "install", "-r", "requirements.txt"], 
                      check=True, capture_output=True)
        print("✅ Dependencies installed successfully")
        return True
    except subprocess.CalledProcessError as e:
        print(f"❌ Failed to install dependencies: {e}")
        return False

def test_backend():
    """Test if the backend can start"""
    print("\n🧪 Testing backend...")
    
    try:
        # Try to import the app
        import main
        print("✅ Backend imports successfully")
        
        # Check if app object exists
        if hasattr(main, 'app'):
            print("✅ FastAPI app object found")
        else:
            print("❌ FastAPI app object not found")
            return False
            
        return True
    except ImportError as e:
        print(f"❌ Failed to import backend: {e}")
        return False
    except Exception as e:
        print(f"❌ Unexpected error: {e}")
        return False

def generate_deployment_commands():
    """Generate deployment commands for different platforms"""
    print("\n🚀 Deployment Commands:")
    
    print("\n📋 For Railway:")
    print("1. Go to https://railway.app")
    print("2. Connect your GitHub repository")
    print("3. Create new project from GitHub")
    print("4. Select the 'backend' folder")
    print("5. Add environment variables from .env.cloud")
    print("6. Deploy!")
    
    print("\n📋 For Render:")
    print("1. Go to https://render.com")
    print("2. Connect your GitHub repository")
    print("3. Create new Web Service")
    print("4. Select the 'backend' folder")
    print("5. Add environment variables from .env.cloud")
    print("6. Deploy!")
    
    print("\n📋 For Docker:")
    print("docker build -t talent-backend .")
    print("docker run -p 8000:8000 --env-file .env.cloud talent-backend")

def main():
    """Main function"""
    print("🚀 Backend Deployment Helper")
    print("=" * 40)
    
    # Check prerequisites
    if not check_prerequisites():
        print("\n❌ Prerequisites check failed")
        return
    
    # Setup environment
    if not setup_environment():
        print("\n❌ Environment setup failed")
        return
    
    # Install dependencies
    if not install_dependencies():
        print("\n❌ Dependency installation failed")
        return
    
    # Test backend
    if not test_backend():
        print("\n❌ Backend test failed")
        return
    
    print("\n✅ All checks passed! Your backend is ready for deployment.")
    
    # Generate deployment commands
    generate_deployment_commands()
    
    print("\n🎉 You're all set! Follow the deployment steps above.")

if __name__ == "__main__":
    try:
        from dotenv import load_dotenv
        main()
    except ImportError:
        print("❌ python-dotenv not found. Install it with: pip install python-dotenv")
        sys.exit(1)
