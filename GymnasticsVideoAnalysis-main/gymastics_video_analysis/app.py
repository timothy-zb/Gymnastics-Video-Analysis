import os
import urllib.parse
import firebase_admin
from firebase_admin import credentials, storage, firestore
import sys
import time
import subprocess
from google.api_core.exceptions import NotFound
import datetime
from flask import Flask, request, jsonify
from flask_sslify import SSLify

# Set the path for the gymnastics_analysis folder on the desktop
gymnastics_analysis_folder = os.path.join(os.path.expanduser("~"), "Desktop", "gymnastics_analysis")

# Set the path for the input videos folder within gymnastics_analysis
input_folder = os.path.join(gymnastics_analysis_folder, "Input Videos")

# Set the path for the output videos folder within gymnastics_analysis
output_folder = os.path.join(gymnastics_analysis_folder, "Output Videos")

# Set the path to the service account key JSON file within gymnastics_analysis
service_account_key_path = os.path.join(gymnastics_analysis_folder, "gymnastics-analysis-543bc-firebase-adminsdk-bogtx-aa762a6ac2.json")

# Set the path for the private.key file within gymnastics_analysis
ssl_key = os.path.join(gymnastics_analysis_folder, "private.key")

# Set the path for the certificate.crt file within gymnastics_analysis
ssl_cert = os.path.join(gymnastics_analysis_folder, "certificate.crt")

# Initialize Firebase
cred = credentials.Certificate(service_account_key_path)
firebase_admin.initialize_app(cred, {
    'storageBucket': 'gymnastics-analysis-543bc.appspot.com'
})

app = Flask(__name__)
sslify = SSLify(app)

# Load SSL certificate files
ssl_context = (ssl_cert, ssl_key)

@app.route('/process_video', methods=['POST'])
def process_video():
    athlete_id = request.form['athlete_id']

    if not athlete_id:
        error_message = "Athlete ID not provided."
        print(error_message)
        return jsonify({'error': error_message}), 400

    try:
        # Initialize Firestore
        db = firestore.client()

        # Retrieve the athlete document with the given ID
        athlete_ref = db.collection('athletes').document(athlete_id)
        athlete_doc = athlete_ref.get()
        if not athlete_doc.exists:
            error_message = "Athlete not found."
            print(error_message)
            return jsonify({'error': error_message}), 404

        # Retrieve the videos subcollection for the athlete
        videos_ref = athlete_ref.collection('videos')

        # Retrieve all video documents in the subcollection
        video_docs = videos_ref.get()

        video_number = 0

        for video_doc in video_docs:
            video_number += 1
            if process_single_video(video_doc, video_number, athlete_id):
                print("Video processed successfully.")
            else:
                print("Error processing video:", video_doc.id)

        return jsonify({'message': 'Videos processed successfully.'})

    except NotFound as e:
        error_message = "Error downloading the video: The requested object was not found."
        print(error_message)
        return jsonify({'error': error_message}), 404
    except Exception as e:
        error_message = "An error occurred: " + str(e)
        print(error_message)
        return jsonify({'error': error_message}), 500

def process_single_video(video_data, video_number, athlete_id):
    # Print the videoUrl
    print("Video URL:", video_data.get('videoUrl'))

    # Retrieve the video URL from the video document
    video_url = video_data.get('videoUrl')
    video_name = f'input.mp4'
    video_path = os.path.join(input_folder, video_name)

    parsed_url = urllib.parse.urlparse(video_url)
    blob_path = urllib.parse.unquote(parsed_url.path)
    blob_name = blob_path.split('/')[-1]  # Extract the blob name

    # Specify the videos folder path in Firebase Storage
    folder_path = 'videos'

    # Construct the full blob name with the folder path
    blob_full_path = os.path.join(folder_path, blob_name)

    # Initialize Firebase Storage
    bucket = storage.bucket()

    video_blob = bucket.blob(blob_full_path)

    # Download the video file
    print("Downloading video...")
    start_time = time.time()
    video_blob.download_to_filename(video_path)
    end_time = time.time()
    download_time = end_time - start_time

    if os.path.getsize(video_path) > 0:
        print(f"Video downloaded successfully in {download_time:.2f} seconds.")
        print(f"Video saved as '{video_name}' successfully.")
    else:
        print("Error downloading the video: The downloaded file is empty.")
        return False

    # Set the paths for the Vault_Gymnast.py script, input videos folder, and output videos folder
    script_folder = os.path.dirname(os.path.abspath(__file__))
    script_path = os.path.join(script_folder, "Vault_Gymnast.py")
    output_folder = os.path.join(gymnastics_analysis_folder, "Output Videos")

    # Specify the path to the input and output video file
    input_file = video_path
    output_file = os.path.join(output_folder, f"output_video.mp4")

    # Create the output folder if it doesn't exist
    os.makedirs(output_folder, exist_ok=True)

    # Change the current working directory to the script folder
    os.chdir(script_folder)

    # Run the Vault_Gymnast.py script with the input and output paths as command line arguments
    subprocess.run([sys.executable, script_path, input_file, output_folder])

    print("Processing completed!")

    # Specify the path to the processed video file
    processed_video_path = output_file

    # Specify the output folder path in Firebase Storage
    output_folder_path = 'output'

    # Construct the full blob name with the output folder path and video ID
    output_blob_name = f"output_{athlete_id}_video{video_number}.mp4"
    output_blob_path = os.path.join(output_folder_path, output_blob_name)

    # Rename the processed video file with the desired name
    renamed_processed_video_path = os.path.join(output_folder, output_blob_name)
    os.rename(processed_video_path, renamed_processed_video_path)

    # Upload the renamed processed video to Firebase Storage
    output_blob = bucket.blob(output_blob_path)
    output_blob.upload_from_filename(renamed_processed_video_path)

    print("Processed video uploaded to Firebase Storage.")

    # Get the URL of the uploaded processed video
    output_video_url = output_blob.public_url

    # Update the video document in the Firestore database with the output video URL
    video_data.reference.update({
        'outputVideoUrl': output_video_url
    })

    print("Processed video URL updated in the database.")

    # Delete input and processed videos
    os.remove(video_path)
    os.remove(renamed_processed_video_path)

    print("Input and processed videos deleted.")
    return True

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=443, ssl_context=ssl_context)

