# Importing the essential libraries
import math
import cv2
from time import time
import numpy as np
import mediapipe as mp
import matplotlib.pyplot as plt

# Initializing mediapipe pose class
mp_pose = mp.solutions.pose

# Building the Pose function.
pose = mp_pose.Pose(static_image_mode=True, min_detection_confidence=0.3, model_complexity=2)

# Initializing mediapipe drawing class
mp_drawing = mp.solutions.drawing_utils

# Function to classify a gymnast pose
def classifyPose(prev_state, landmarks, output_image, display=False):
    '''
    This function will classify vault gymnast poses on the basis of the angles of various body joints.
    Args:
        prev_state: keeps the value of the last previous state attained.
        landmarks: Record of detected landmarks of the gymnast whose pose needs to be classified.
        output_image: Gymnast image with the detected pose landmarks drawn.
        display: When true, this function displays the resultant image with the pose label
        written on it and returns nothing.
    Returns:
        prev_state: keeps the value of the latest last previous state attained.
        output_image: Gymnast image with the detected pose landmarks drawn and pose label written.
        label: Classified pose label of the gymnast.

    '''
    # Initializing the unknown state value with '0'
    state = 0

    # Initializing the pose label. It is unknown at this stage.
    label = '   '
    color = (0, 0, 255)
    
    # Calculating the essential required angles.
    #----------------------------------------------------------------------------------------------------------------
    
    # Angle of left elbow means the angle between the left shoulder, elbow and wrist points.
    left_elbow_angle = calculateAngle(landmarks[mp_pose.PoseLandmark.LEFT_SHOULDER.value],
                                      landmarks[mp_pose.PoseLandmark.LEFT_ELBOW.value],
                                      landmarks[mp_pose.PoseLandmark.LEFT_WRIST.value])
    
    # Angle of right elbow means the angle between the right shoulder, elbow and wrist points.
    right_elbow_angle = calculateAngle(landmarks[mp_pose.PoseLandmark.RIGHT_SHOULDER.value],
                                       landmarks[mp_pose.PoseLandmark.RIGHT_ELBOW.value],
                                       landmarks[mp_pose.PoseLandmark.RIGHT_WRIST.value])
    
    # Angle of left shoulder means the angle between the left elbow, shoulder and hip points.
    left_shoulder_angle = calculateAngle(landmarks[mp_pose.PoseLandmark.LEFT_ELBOW.value],
                                         landmarks[mp_pose.PoseLandmark.LEFT_SHOULDER.value],
                                         landmarks[mp_pose.PoseLandmark.LEFT_HIP.value])

    # Angle of right shoulder means the angle between the right hip, shoulder and elbow points.
    right_shoulder_angle = calculateAngle(landmarks[mp_pose.PoseLandmark.RIGHT_HIP.value],
                                          landmarks[mp_pose.PoseLandmark.RIGHT_SHOULDER.value],
                                          landmarks[mp_pose.PoseLandmark.RIGHT_ELBOW.value])

    # Angle of left knee means the angle between the left hip, knee and ankle points.
    left_knee_angle = calculateAngle(landmarks[mp_pose.PoseLandmark.LEFT_HIP.value],
                                     landmarks[mp_pose.PoseLandmark.LEFT_KNEE.value],
                                     landmarks[mp_pose.PoseLandmark.LEFT_ANKLE.value])

    # Angle of right knee means the angle between the right hip, knee and ankle points
    right_knee_angle = calculateAngle(landmarks[mp_pose.PoseLandmark.RIGHT_HIP.value],
                                      landmarks[mp_pose.PoseLandmark.RIGHT_KNEE.value],
                                      landmarks[mp_pose.PoseLandmark.RIGHT_ANKLE.value])
    
    # Angle of left hip means the angle between the left shoulder, hip and knee points.
    left_hip_angle = calculateAngle(landmarks[mp_pose.PoseLandmark.LEFT_SHOULDER.value],
                                    landmarks[mp_pose.PoseLandmark.LEFT_HIP.value],
                                    landmarks[mp_pose.PoseLandmark.LEFT_KNEE.value])
    
    # Angle of right hip means the angle between the right shoulder, hip and knee points
    right_hip_angle = calculateAngle(landmarks[mp_pose.PoseLandmark.RIGHT_SHOULDER.value],
                                    landmarks[mp_pose.PoseLandmark.RIGHT_HIP.value],
                                    landmarks[mp_pose.PoseLandmark.RIGHT_KNEE.value])
    
    #----------------------------------------------------------------------------------------------------------------
    
    
    # Check if the range of elbow and shoulder angles differ from '0' to '360' degree.
    if left_elbow_angle > 0 and left_elbow_angle < 360 and right_elbow_angle > 0 and right_elbow_angle < 360:

        # Check if shoulders are at the required angle.
        if left_shoulder_angle > 0 and left_shoulder_angle < 360 and right_shoulder_angle > 0 and right_shoulder_angle < 360:

    # Checking if it is the Jump pose.
    #----------------------------------------------------------------------------------------------------------------

            # Check if 360-knee_angle is less than 150 degrees.
            if left_knee_angle > 210  and left_knee_angle < 360 or right_knee_angle > 210 and right_knee_angle < 360:

                # Specify the state of the pose that is Jump pose.
                state = 1
                        
    #----------------------------------------------------------------------------------------------------------------
    
    # Check if the both arms are at the required angle.
    if left_elbow_angle > 0 and left_elbow_angle < 360 and right_elbow_angle > 0 and right_elbow_angle < 360:

        # Check if shoulders are straight down.
        if left_shoulder_angle > 0 and left_shoulder_angle < 20 and right_shoulder_angle > 0 and right_shoulder_angle < 20:

    # Check if it is the 2nd flight pose.
    #----------------------------------------------------------------------------------------------------------------

            # Check if both the legs are free.
            if left_knee_angle > 0  and left_knee_angle < 360 or right_knee_angle > 0 and right_knee_angle < 360:

                # Specify the state of the pose that is 2nd flight pose.
                state = 4
    #----------------------------------------------------------------------------------------------------------------
    
    # Check if both arms are at the required angles.
    if left_elbow_angle > 145 and left_elbow_angle < 215 and right_elbow_angle > 145 and right_elbow_angle < 215:

    # Check if it is the 1st flight pose.
    #----------------------------------------------------------------------------------------------------------------
        
        # Check if both the shoulders are straight.
        if left_shoulder_angle > 145 and left_shoulder_angle < 170 and right_shoulder_angle > 65:
            # Check if one leg is straight.
            if left_knee_angle > 165 and left_knee_angle < 195 or right_knee_angle > 165 and right_knee_angle < 195:

                # Specify the state of the pose that is 1st Flight pose.
                state = 2
    #----------------------------------------------------------------------------------------------------------------
    
    # Check if it is the repulsion pose.
    #----------------------------------------------------------------------------------------------------------------
    
    # Check if both the legs are straight.
    if left_knee_angle > 170 and left_knee_angle < 190 and right_knee_angle > 170 and right_knee_angle < 190:
    #----------------------------------------------------------------------------------------------------------------

        # Check if one of the shoulders is greater than 180 degrees.
        if left_shoulder_angle > 180 or right_shoulder_angle > 180:
            # Check if one elbow is at the required angle.
            if left_elbow_angle > 120 and left_elbow_angle < 190 or right_elbow_angle > 120 and right_elbow_angle < 190:

                # Specify the state of the pose that is Repulsion pose.
                state = 3
    #----------------------------------------------------------------------------------------------------------------
    
    
    # Check if both the arms are straight.
    if left_elbow_angle > 165 and left_elbow_angle < 195 and right_elbow_angle > 165 and right_elbow_angle < 195:

        # Check if shoulders are at the required angle.
        if left_shoulder_angle > 85 and left_shoulder_angle < 195 and right_shoulder_angle > 85 and right_shoulder_angle < 195:

    # Check if it is the ending pose.
    #----------------------------------------------------------------------------------------------------------------

            # Check if one leg is straight.
            if left_knee_angle > 135 and left_knee_angle < 180 or right_knee_angle > 135 and right_knee_angle < 180:

                # Specify the state of the pose that is ending pose.
                state = 5
    #-----------------------------------------------------------------------------------------------------------------------
    
    # If the next state is required, increment the previous state to the next state, otherwise ignore the next state
    if state == prev_state + 1:
        prev_state = state
    else:
        state = prev_state
    
    # Initializing labels according to the states
    if state == 1:
            label = 'Jump'
    elif state == 2:
            label = '1st Flight'
            state = state + 2
    elif state == 3:
            label = 'Repulsion'
    elif state == 4:
            label = '2nd Flight'
    elif state == 5:
            label = 'Complete'
            state = 5
    else:
        label = '   '

    # Check if the pose is classified successfully
    if label != '   ':
        
        # Update the color (to green) with which the label will be written on the image.
        color = (0, 255, 0)
    
    # centre of torso of the gymnast body
    left_torso = landmarks[mp_pose.PoseLandmark.LEFT_HIP.value]
    right_torso = landmarks[mp_pose.PoseLandmark.RIGHT_HIP.value]
    cog = centreoftorso(left_torso, right_torso)
    r1, r2, _ = cog

    # Write the label on the output image.
    cv2.putText(output_image, label, tuple(np.multiply([r1+30, r2-80], [1, 1]).astype(int)) ,cv2.FONT_HERSHEY_PLAIN, 2, color, 2)

    # Write the calculated 'Bent knees' and 'Leg separation' label on the output image in white and cyan color.
    if (label =='1st Flight' or label == 'Repulsion' or label == '2nd Flight'):
        n = bent_knees(min(left_knee_angle,right_knee_angle))
        cv2.putText(output_image, "Bent knees:"+" "+ str(n), tuple(np.multiply([r1+30, r2-30], [1, 1]).astype(int)) ,cv2.FONT_HERSHEY_PLAIN, 2, (255, 255, 255), 2)

        shoulder_sep = distance((landmarks[mp_pose.PoseLandmark.RIGHT_SHOULDER.value]),(landmarks[mp_pose.PoseLandmark.LEFT_SHOULDER.value]))
        leg_sep = distance((landmarks[mp_pose.PoseLandmark.RIGHT_ANKLE.value]),(landmarks[mp_pose.PoseLandmark.LEFT_ANKLE.value]))
        leg = leg_d(shoulder_sep, leg_sep)
        cv2.putText(output_image, "Leg Separation:"+" "+ str(leg), tuple(np.multiply([r1+30, r2], [1, 1]).astype(int)) ,cv2.FONT_HERSHEY_PLAIN, 2, (255, 255, 0), 2)

    # Write the calculated 'Shoulder Angle' label on the output image
    if (label == 'Repulsion'):
        pos = shoulder_ang(min(left_shoulder_angle,right_shoulder_angle))
        cv2.putText(output_image, "Shoulder angle:"+" "+ str(pos), tuple(np.multiply([r1+30, r2+30], [1, 1]).astype(int)) ,cv2.FONT_HERSHEY_PLAIN, 2, (255, 255, 255), 2)

    # Write the calculated 'Body Alignment' label on the output image
    if (label == '2nd Flight'):
        if (left_elbow_angle < 165 or left_elbow_angle > 195) or (right_elbow_angle < 165 or right_elbow_angle < 195):
            cv2.putText(output_image, "Body alignment:"+" "+ str(0.1), tuple(np.multiply([r1+30, r2+30], [1, 1]).astype(int)) ,cv2.FONT_HERSHEY_PLAIN, 2, (255, 255, 255), 2)

    # Write the calculated 'Layout failure' label on the output image
    if(label=='Complete' and ((left_knee_angle > 165 and left_knee_angle < 195) or (right_knee_angle > 165 and right_knee_angle < 195)) and ((left_hip_angle > 135
    and left_hip_angle < 195) or (right_hip_angle > 135 and right_hip_angle < 195))):

        cv2.putText(output_image, "Failure to maintain", (640, 90) ,cv2.FONT_HERSHEY_PLAIN, 2, (255, 255, 255), 2)
        cv2.putText(output_image, "layout(pike down):", (640, 130) ,cv2.FONT_HERSHEY_PLAIN, 2, (255, 255, 255), 2)
        cv2.putText(output_image, str(0.1), (640, 170) ,cv2.FONT_HERSHEY_PLAIN, 2, (0, 255, 255), 2)
    
    # Check if the resultant image can be displayed.
    if display:
    
        # Displaying the resultant image.
        plt.figure(figsize=[10,10])
        plt.imshow(output_image[:,:,::-1]);plt.title("Output Image");plt.axis('off');
        
    else:
        
        # Returning the output image and the classified label.
        return prev_state, output_image, label

# Function for finding the centre of torso in body
def centreoftorso(landmark1, landmark2):
    x1, y1, _ = landmark1
    x2, y2, _ = landmark2

    x3 = (x1+x2)/2
    y3 = (y1+y2)/2
    landmark9 = x3, y3, _

    return landmark9

# Function to calculate the distance between 2 body landmark points
def distance(landmark1, landmark2):
    x1, y1, _ = landmark1
    x2, y2, _ = landmark2

    d = (abs((x1**2)-(x2**2)) + abs((y1**2)-(y2**2)))**(0.5)
    return d

# Function to calculate the deduction due to leg separation
def leg_d(a,b):
    if b > a:
        d = 0.3
    elif (b > 0 or b == 0) and b < a/2:
        d = 0
    else:
        d = 0.1
    return d

# Function to calculate the deduction due to bent knees
def bent_knees(angle_in_degree):
    a = 185 - angle_in_degree
    if abs(a) > 0 and abs(a) < 45:
        d = 0.1
    elif abs(a) > 45 and abs(a) < 90:
        d = 0.3
    elif abs(a) > 90:
        d = 0.5
    else:
        d = 0
    return d

# Function to calculate the deduction due to shoulder angles
def shoulder_ang(angle_in_degree):
    a = 185 - angle_in_degree
    if abs(a) > 5 and abs(a) < 20:
        d = 0.1
    elif abs(a) > 20 and abs(a) < 35:
        d = 0.3
    elif abs(a) > 35:
        d = 0.5
    else:
        d = 0
    return d

# Function calculates angle between three different landmarks
def calculateAngle(landmark1, landmark2, landmark3):
    '''
    Args:
        landmark1: The first landmark with x1,y1 and z1 coordinates.
        landmark2: The second landmark with x2,y2 and z2 coordinates.
        landmark3: The third landmark with x3,y3 and z3 coordinates.
    Returns:
        angle: Contains the calculated angle between the three landmarks.

    '''

    # Obtaining the required landmarks coordinates.
    x1, y1, _ = landmark1
    x2, y2, _ = landmark2
    x3, y3, _ = landmark3

    # Calculating the angle between the three points
    angle = math.degrees(math.atan2(y3 - y2, x3 - x2) - math.atan2(y1 - y2, x1 - x2))
    
    # Check if the angle is less than zero.
    if angle < 0:

        # Add 360 to the found angle.
        angle += 360
    
    # Return the calculated angle.
    return angle

# Function to perform pose detection on an image
def detectPose(image, pose, display=True):
    '''
    Args:
        image: The input image with a gymnast whose pose landmarks are to be detected.
        pose: The pose build function needed to carry out the pose detection.
        display: If it is true, the function displays the original input image, the resultant image,
                 and the pose landmarks in 3D plot and returns nothing.
    Returns:
        output_image: The input image with the detected pose landmarks drawn.
        landmarks: Record of detected landmarks converted into their original scale.
    '''
    
    # Create a copy of the input image.
    output_image = image.copy()
    
    # Convert the image from BGR into RGB format.
    imageRGB = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
    
    # Do the Pose Detection.
    results = pose.process(imageRGB)
    
    # Obtain the height and width of the input image
    height, width, _ = image.shape
    
    # Initialize a list to store the detected landmarks
    landmarks = []
    
    # Check if any landmarks are detected
    if results.pose_landmarks:
    
        # Draw Pose landmarks on the output image
        mp_drawing.draw_landmarks(image=output_image, landmark_list=results.pose_landmarks,
                                  connections=mp_pose.POSE_CONNECTIONS)
        
        # Repeating over the detected landmarks.
        for landmark in results.pose_landmarks.landmark:
            
            # Append the landmark into the list.
            landmarks.append((int(landmark.x * width), int(landmark.y * height),
                                  (landmark.z * width)))
    
    # Check if the original input image and the resultant image are specified to be displayed.
    if display:
    
        # Display the original input image and the resultant image.
        plt.figure(figsize=[22,22])
        plt.subplot(121);plt.imshow(image[:,:,::-1]);plt.title("Original Image");plt.axis('off');
        plt.subplot(122);plt.imshow(output_image[:,:,::-1]);plt.title("Output Image");plt.axis('off');
        
        # And Plot the Pose landmarks in 3D.
        mp_drawing.plot_landmarks(results.pose_world_landmarks, mp_pose.POSE_CONNECTIONS)
        
    # ELSE
    else:
        
        # Return the output image and the found landmarks.
        return output_image, landmarks


# Build Pose function for video.
pose_video = mp_pose.Pose(static_image_mode=False, min_detection_confidence=0.5, model_complexity=1)

prev_state = 0

# Initialize the VideoCapture object to read from the webcam.
video = cv2.VideoCapture("Input Videos/input.mp4")
output_file = 'Output Videos/output_video.mp4'


fps = video.get(cv2.CAP_PROP_FPS)
width = int(video.get(cv2.CAP_PROP_FRAME_WIDTH))
height = int(video.get(cv2.CAP_PROP_FRAME_HEIGHT))

# Define the codec and create VideoWriter object
fourcc = cv2.VideoWriter_fourcc(*'mp4v')
out = cv2.VideoWriter(output_file, fourcc, fps, (width, height))

# Repeat until the video is accessed successfully.
while video.isOpened():
    
    # Read a frame.
    ok, frame = video.read()
    
    # Check if frame is not read properly.
    if not ok:
        # Break the loop.
        break
        
    # Convert the image to RGB and process it with MediaPipe Pose
    image = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
    results = pose.process(image)

    # Flip the frame horizontally for better visualization and analysis.
    frame = cv2.flip(frame, 1)

    # Get the width and height of the frame
    frame_height, frame_width, _ = frame.shape
    
    # Resize the frame while keeping the aspect ratio.
    frame = cv2.resize(frame, (int(frame_width * (640 / frame_height)), 640))
    
    # Perform Pose landmark detection.
    frame, landmarks = detectPose(frame, pose_video, display=False)

    # Check if the landmarks are detected.
    if landmarks:
        # Perform the Pose Classification.
        prev_state, frame, pose_class = classifyPose(prev_state, landmarks, frame, display=False)
        
        # Draw the results on the frame
        cv2.putText(frame, pose_class, (50, 50), cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 255, 0), 2, cv2.LINE_AA)

    # Write the frame to the output video
    out.write(frame)

# Release the VideoWriter and VideoCapture objects.
out.release()
video.release()

# Close any remaining windows.
cv2.destroyAllWindows()

