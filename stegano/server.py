from flask import Flask, request, send_file, jsonify
import os
from werkzeug.utils import secure_filename
from flask_cors import CORS

import base64
from cryptography.hazmat.primitives.asymmetric import rsa, padding as rsa_padding
from cryptography.hazmat.primitives import serialization, hashes
import cv2
import uuid
import shutil

app = Flask(__name__)
CORS(app, resources={r"/*": {"origins": "*"}}, supports_credentials=True)

@app.after_request
def after_request(response):
    response.headers.add('Access-Control-Allow-Origin', '*')
    response.headers.add('Access-Control-Allow-Headers', 'Content-Type,Authorization')
    response.headers.add('Access-Control-Allow-Methods', 'GET,PUT,POST,DELETE,OPTIONS')
    return response

# Configure upload settings
UPLOAD_FOLDER = './uploads'
TEMP_FOLDER = './tmp'
os.makedirs(UPLOAD_FOLDER, exist_ok=True)
os.makedirs(TEMP_FOLDER, exist_ok=True)

@app.route('/')
def hello():
    return "Video Steganography API"

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)

def extract_frames(video_path, temp_dir):
    """Extract frames from video"""
    if not os.path.exists(temp_dir):
        os.makedirs(temp_dir)
    
    print(f"[INFO] Extracting frames from video {video_path}")
    vidcap = cv2.VideoCapture(video_path)
    count = 0
    frames = []
    
    while True:
        success, image = vidcap.read()
        if not success:
            break
        frame_path = os.path.join(temp_dir, f"{count}.png")
        cv2.imwrite(frame_path, image)
        frames.append(frame_path)
        count += 1
    
    print(f"[INFO] Extracted {count} frames from video")
    return frames, count

# Add endpoint
@app.route('/extract', methods=['POST'])
def extract_endpoint():
    """Test endpoint to extract frames from video"""
    if 'video' not in request.files:
        return jsonify({"error": "Missing video file"}), 400
    
    video_file = request.files['video']
    
    if video_file.filename == '':
        return jsonify({"error": "No video selected"}), 400
    
    # Create temporary directory for processing
    session_id = str(uuid.uuid4())
    temp_dir = os.path.join(TEMP_FOLDER, session_id)
    os.makedirs(temp_dir, exist_ok=True)
    
    try:
        # Save uploaded video
        video_path = os.path.join(temp_dir, secure_filename(video_file.filename))
        video_file.save(video_path)
        
        # Extract frames from video
        frames, count = extract_frames(video_path, temp_dir)
        
        return jsonify({"frames_extracted": count})
    
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    
    finally:
        # Clean up temporary files
        try:
            if os.path.exists(temp_dir):
                shutil.rmtree(temp_dir)
        except Exception as cleanup_error:
            print(f"Error cleaning up: {cleanup_error}")


KEYS_FOLDER = './keys'
os.makedirs(KEYS_FOLDER, exist_ok=True)

def generate_keys(key_size=2048):
    """Generate RSA key pair if they don't exist"""
    private_keys_path = os.path.join(KEYS_FOLDER, f'private_key_{key_size}.pem')
    public_keys_path = os.path.join(KEYS_FOLDER, f'public_key_{key_size}.pem')
    
    if os.path.isfile(private_keys_path) and os.path.isfile(public_keys_path):
        print("Public and private keys already exist")
        return
    
    # Generate a private key
    private_key = rsa.generate_private_key(
        public_exponent=65537,
        key_size=key_size,
    )
    
    # Get the public key
    public_key = private_key.public_key()
    
    # Serialize and save the private key
    private_pem = private_key.private_bytes(
        encoding=serialization.Encoding.PEM,
        format=serialization.PrivateFormat.PKCS8,
        encryption_algorithm=serialization.NoEncryption()
    )
    
    with open(private_keys_path, "wb") as file_obj:
        file_obj.write(private_pem)
    
    # Serialize and save the public key
    public_pem = public_key.public_bytes(
        encoding=serialization.Encoding.PEM,
        format=serialization.PublicFormat.SubjectPublicKeyInfo
    )
    
    with open(public_keys_path, "wb") as file_obj:
        file_obj.write(public_pem)
    
    print(f"Public and Private keys created with size {key_size}")

def encrypt_rsa(message):
    """Encrypt message using RSA"""
    key_size = 2048
    # Ensure keys exist
    generate_keys(key_size)
    
    # Read public key
    public_key_path = os.path.join(KEYS_FOLDER, f'public_key_{key_size}.pem')
    with open(public_key_path, 'rb') as key_file:
        public_key = serialization.load_pem_public_key(key_file.read())
    
    # Encrypt the message
    message_bytes = message.encode('utf-8') if isinstance(message, str) else message
    ciphertext = public_key.encrypt(
        message_bytes,
        rsa_padding.OAEP(
            mgf=rsa_padding.MGF1(algorithm=hashes.SHA256()),
            algorithm=hashes.SHA256(),
            label=None
        )
    )
    
    # Encode in base64
    return base64.b64encode(ciphertext)

def decrypt_rsa(encoded_message):
    """Decrypt message using RSA"""
    key_size = 2048
    # Ensure keys exist
    generate_keys(key_size)
    
    # Set private key path
    private_key_path = os.path.join(KEYS_FOLDER, f'private_key_{key_size}.pem')
    
    # Read private key
    with open(private_key_path, 'rb') as key_file:
        private_key = serialization.load_pem_private_key(
            key_file.read(),
            password=None
        )
    
    # Decode base64 if needed
    if isinstance(encoded_message, str):
        encoded_message = encoded_message.encode('utf-8')
    
    cipher_text = base64.b64decode(encoded_message)
    
    # Decrypt the message
    plain_text = private_key.decrypt(
        cipher_text,
        rsa_padding.OAEP(
            mgf=rsa_padding.MGF1(algorithm=hashes.SHA256()),
            algorithm=hashes.SHA256(),
            label=None
        )
    )
    
    return plain_text

# Add code to generate keys during startup
if __name__ == '__main__':
    # Make sure keys are generated on startup
    generate_keys()
    
    # Try different ports if the default is in use
    port = 5000
    max_port_attempts = 10
    
    for attempt in range(max_port_attempts):
        try:
            print(f"Attempting to start server on port {port}")
            app.run(debug=True, host='0.0.0.0', port=port)
            break
        except OSError as e:
            if "Address already in use" in str(e) and attempt < max_port_attempts - 1:
                port += 1
                print(f"Port {port-1} is in use, trying port {port}")
            else:
                print(f"Could not start server: {e}")
                raise
def decode_video(video_path, temp_dir):
    """Decode hidden text from video"""
    # Create a temporary directory
    if not os.path.exists(temp_dir):
        os.makedirs(temp_dir)
    
    # Extract frames using OpenCV directly
    cap = cv2.VideoCapture(video_path)
    number_of_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
    
    print(f"[INFO] Video has {number_of_frames} frames")
    
    # Try the first 15 frames for simplicity in this basic version
    frames_to_check = list(range(15))
    
    # Process frames
    decoded = {}
    
    for frame_number in frames_to_check:
        if frame_number >= number_of_frames:
            continue
            
        # Jump to the specific frame
        cap.set(cv2.CAP_PROP_POS_FRAMES, frame_number)
        ret, frame = cap.read()
        if not ret:
            continue
        
        encoded_frame_file_name = os.path.join(temp_dir, f"{frame_number}-enc.png")
        cv2.imwrite(encoded_frame_file_name, frame)
        
        # Try to decode the frame
        try:
            clear_message = lsb.reveal(encoded_frame_file_name)
            if clear_message:
                decoded[frame_number] = clear_message
                print(f"Frame {frame_number} DECODED: {clear_message}")
        except Exception as e:
            print(f"Error decoding frame {frame_number}: {e}")
    
    # Arrange and decrypt the message
    res = ""
    for fn in sorted(decoded.keys()):
        res += decoded[fn]
    
    if not res:
        return None
    
    try:
        # Try to decrypt the message
        decrypted_message = decrypt_rsa(res)
        return decrypted_message.decode('utf-8')
    except Exception as e:
        print(f"Error decrypting message: {e}")
        return res  # Return the encoded message if decryption fails

# Add decrypt endpoint
@app.route('/decrypt', methods=['POST'])
def decrypt_endpoint():
    """Endpoint to decrypt hidden text from video"""
    if 'video' not in request.files:
        return jsonify({"error": "Missing video file"}), 400
    
    video_file = request.files['video']
    
    if video_file.filename == '':
        return jsonify({"error": "No video selected"}), 400
    
    # Create temporary directory for processing
    session_id = str(uuid.uuid4())
    temp_dir = os.path.join(TEMP_FOLDER, session_id)
    os.makedirs(temp_dir, exist_ok=True)
    
    try:
        # Save uploaded video
        video_path = os.path.join(temp_dir, secure_filename(video_file.filename))
        video_file.save(video_path)
        
        # Decode and decrypt hidden text
        decrypted_text = decode_video(video_path, temp_dir)
        
        if decrypted_text:
            return jsonify({"text": decrypted_text})
        else:
            return jsonify({"error": "No hidden text found in video"}), 404
    
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    
    finally:
        # Clean up temporary files
        if os.path.exists(temp_dir):
            shutil.rmtree(temp_dir)

# Update encode_frames function to add metadata
def encode_frames(frames, encrypted_text, temp_dir):
    """Encode encrypted text into frames"""
    # Convert to string if it's bytes
    if isinstance(encrypted_text, bytes):
        encrypted_text = encrypted_text.decode('utf-8')
        
    # Split the text into parts
    split_text_list = split_string(encrypted_text)
    num_parts = len(split_text_list)
    
    # Use the first N frames (N = number of text parts)
    frame_numbers = list(range(min(num_parts, len(frames))))
    
    print(f"Encoding text into {len(frame_numbers)} frames")
    
    # Hide text parts in frames
    for i, frame_num in enumerate(frame_numbers):
        if i >= len(split_text_list):
            break
            
        frame_path = frames[frame_num]
        # Hide text in frame using LSB steganography
        secret_enc = lsb.hide(frame_path, split_text_list[i])
        secret_enc.save(frame_path)
        print(f"[INFO] Frame {frame_num} holds {split_text_list[i]}")
    
    # Save the frame numbers in a special metadata frame
    # This will help with faster decryption
    metadata_frame_path = os.path.join(temp_dir, "metadata.png")
    # Create a simple black image for metadata
    metadata_img = cv2.imread(frames[0])
    cv2.imwrite(metadata_frame_path, metadata_img)
    
    # Save frame numbers as metadata
    metadata_content = ",".join(map(str, frame_numbers))
    metadata_secret = lsb.hide(metadata_frame_path, metadata_content)
    metadata_secret.save(metadata_frame_path)
    print(f"[INFO] Metadata frame holds frame numbers: {metadata_content}")
    
    # Insert the metadata frame as the last frame to process
    frames.append(metadata_frame_path)
        
    return frame_numbers

# Update decode_video to look for metadata frame
def decode_video(video_path, temp_dir):
    """Decode hidden text from video"""
    # Create a temporary directory
    if not os.path.exists(temp_dir):
        os.makedirs(temp_dir)
    
    # Extract frames using OpenCV directly
    cap = cv2.VideoCapture(video_path)
    number_of_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
    
    print(f"[INFO] Video has {number_of_frames} frames")
    
    # First check if there's a metadata frame by looking at the last frames
    metadata_frame_numbers = []
    
    # Check the last 5 frames for metadata
    print("[INFO] Looking for metadata frame...")
    for frame_index in range(max(0, number_of_frames - 5), number_of_frames):
        # Jump to frame
        cap.set(cv2.CAP_PROP_POS_FRAMES, frame_index)
        ret, frame = cap.read()
        if not ret:
            continue
            
        # Save frame and try to decode it
        metadata_frame_path = os.path.join(temp_dir, f"metadata_check_{frame_index}.png")
        cv2.imwrite(metadata_frame_path, frame)
        
        try:
            metadata_content = lsb.reveal(metadata_frame_path)
            if metadata_content and ',' in metadata_content:
                # This looks like our metadata frame
                print(f"[INFO] Found potential metadata at frame {frame_index}: {metadata_content}")
                try:
                    # Try to parse the frame numbers
                    frame_nums = [int(num) for num in metadata_content.split(',')]
                    metadata_frame_numbers = frame_nums
                    print(f"[INFO] Using frame numbers from metadata: {frame_nums}")
                    break
                except:
                    print(f"[INFO] Failed to parse metadata numbers: {metadata_content}")
        except Exception as e:
            pass
    
    # Reset the video capture
    cap.release()
    cap = cv2.VideoCapture(video_path)
    
    # Frames to check - either from metadata or first 15 frames if no metadata
    frames_to_check = metadata_frame_numbers if metadata_frame_numbers else list(range(15))
    print(f"[INFO] Will check these frames: {frames_to_check}")
    
    # Rest of decode_video function remains the same...