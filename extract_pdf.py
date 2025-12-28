import os
from pypdf import PdfReader

def extract_text_from_pdfs(report_dir, output_file):
    if not os.path.exists(report_dir):
        print(f"Directory not found: {report_dir}")
        return

    pdf_files = [f for f in os.listdir(report_dir) if f.lower().endswith('.pdf')]
    pdf_files.sort()
    
    with open(output_file, 'w', encoding='utf-8') as f_out:
        for filename in pdf_files:
            filepath = os.path.join(report_dir, filename)
            f_out.write(f"--- START OF {filename} ---\n")
            print(f"Processing {filename}...")
            try:
                reader = PdfReader(filepath)
                for page in reader.pages:
                    text = page.extract_text()
                    if text:
                        f_out.write(text + "\n")
            except Exception as e:
                f_out.write(f"Error reading {filename}: {e}\n")
            f_out.write(f"--- END OF {filename} ---\n\n")

if __name__ == "__main__":
    report_dir = os.path.join(os.getcwd(), 'report')
    output_file = os.path.join(os.getcwd(), 'report_content.txt')
    extract_text_from_pdfs(report_dir, output_file)
    print(f"Extraction complete. Saved to {output_file}")
